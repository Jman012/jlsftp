import XCTest
import Combine
import NIO
import NIOTestUtils
import Logging
@testable import jlsftp

final class SftpServerChannelHandlerTests: XCTestCase {

	let noopLogger = Logger(label: "test", factory: { _ in SwiftLogNoOpLogHandler() })

	// MARK: `HandlerError`

	func testHandlerErrorDescription() {
		let message = SftpMessage(packet: .close(.init(id: 1, handle: "")), dataLength: 0, shouldReadHandler: { _ in })
		let data: [(SftpServerChannelHandler.HandlerError, String)] = [
			(.unexpectedState(.header(.initializeV3(.init(version: .v3, extensionData: [])), 0), .awaitingHeader),
			 "An unexpected error occurred, but the state does not make sense."),
			(.unexpectedState(.header(.initializeV3(.init(version: .v3, extensionData: [])), 0), .processingMessage(current: message, queue: [], needsContextRead: false, canWriteBody: false)),
			 "An unexpected error occurred, but the state does not make sense."),
			(.unexpectedState(.body(ByteBuffer()), .awaitingHeader),
			 "An unexpected sftp data chunk was encountered when an sftp packet header was expected."),
			(.unexpectedState(.body(ByteBuffer()), .processingMessage(current: message, queue: [], needsContextRead: false, canWriteBody: false)),
			 "An unexpected error occurred, but the state does not make sense."),
			(.unexpectedState(.end, .awaitingHeader),
			 "An unexpected sftp data end marker was encountered when an sftp packet header was expected."),
			(.unexpectedState(.end, .processingMessage(current: message, queue: [], needsContextRead: false, canWriteBody: false)),
			 "An unexpected error occurred, but the state does not make sense."),
			(.unexpectedWrite, "The server responded to an unknown request")
		]

		for datum in data {
			XCTAssertEqual(datum.0.description, datum.1)
		}
	}

	// MARK: `channelRead(context:data:)`

	func testChannelReadAwaitingHeaderHeader() {
		let channel = EmbeddedChannel()
		var lastMessage: SftpMessage?
		let server = CustomSftpServer(handleMessageHandler: { message in
			lastMessage = message
			return channel.eventLoop.makePromise().futureResult
		})
		let handler = SftpServerChannelHandler(server: server, logger: noopLogger)
		let eventCounterHandlerBegin = EventCounterHandler()
		XCTAssertNoThrow(try channel.pipeline.addHandlers([eventCounterHandlerBegin, handler]).wait())

		XCTAssertNoThrow(try channel.writeInbound(MessagePart.header(.status(.init(id: 1, path: "")), 0)))
		XCTAssertNotNil(lastMessage)
	}

	func testChannelReadAwaitingHeaderBody() {
		let channel = EmbeddedChannel()
		var lastMessage: SftpMessage?
		let server = CustomSftpServer(handleMessageHandler: { message in
			lastMessage = message
			return channel.eventLoop.makePromise().futureResult
		})
		let handler = SftpServerChannelHandler(server: server, logger: noopLogger)
		let eventCounterHandlerBegin = EventCounterHandler()
		XCTAssertNoThrow(try channel.pipeline.addHandlers([eventCounterHandlerBegin, handler]).wait())

		XCTAssertThrowsError(try channel.writeInbound(MessagePart.body(ByteBuffer())))
		XCTAssertNil(lastMessage)
	}

	func testChannelReadAwaitingHeaderEnd() {
		let channel = EmbeddedChannel()
		var lastMessage: SftpMessage?
		let server = CustomSftpServer(handleMessageHandler: { message in
			lastMessage = message
			return channel.eventLoop.makePromise().futureResult
		})
		let handler = SftpServerChannelHandler(server: server, logger: noopLogger)
		let eventCounterHandlerBegin = EventCounterHandler()
		XCTAssertNoThrow(try channel.pipeline.addHandlers([eventCounterHandlerBegin, handler]).wait())

		XCTAssertThrowsError(try channel.writeInbound(MessagePart.end))
		XCTAssertNil(lastMessage)
	}

	func testChannelReadProcessingMessageHeader() {
		let channel = EmbeddedChannel()
		var lastMessage: SftpMessage?
		let server = CustomSftpServer(handleMessageHandler: { message in
			lastMessage = message
			return channel.eventLoop.makePromise().futureResult
		})
		let handler = SftpServerChannelHandler(server: server, logger: noopLogger)
		let eventCounterHandlerBegin = EventCounterHandler()
		XCTAssertNoThrow(try channel.pipeline.addHandlers([eventCounterHandlerBegin, handler]).wait())

		// Get state into processing message
		XCTAssertNoThrow(try channel.writeInbound(MessagePart.header(.status(.init(id: 1, path: "")), 0)))
		XCTAssertNotNil(lastMessage)
		XCTAssertEqual(lastMessage?.packet, .status(.init(id: 1, path: "")))
		XCTAssertNoThrow(try channel.writeInbound(MessagePart.end))

		XCTAssertNoThrow(try channel.writeInbound(MessagePart.header(.status(.init(id: 2, path: "a")), 0)))
		XCTAssertEqual(lastMessage?.packet, .status(.init(id: 1, path: ""))) // Same
		switch handler.state {
		case let .processingMessage(current: _, queue: queue, needsContextRead: _, canWriteBody: _):
			XCTAssertEqual(queue.count, 1)
			XCTAssertEqual(queue.first?.packet, .status(.init(id: 2, path: "a")))
		default:
			XCTFail()
		}
	}

	func testChannelReadProcessingMessageBodyValid() {
		let channel = EmbeddedChannel()
		var lastMessage: SftpMessage?
		let server = CustomSftpServer(handleMessageHandler: { message in
			lastMessage = message
			return channel.eventLoop.makePromise().futureResult
		})
		let handler = SftpServerChannelHandler(server: server, logger: noopLogger)
		let eventCounterHandlerBegin = EventCounterHandler()
		XCTAssertNoThrow(try channel.pipeline.addHandlers([eventCounterHandlerBegin, handler]).wait())

		// Get state into processing message
		XCTAssertNoThrow(try channel.writeInbound(MessagePart.header(.status(.init(id: 1, path: "")), 0)))
		XCTAssertNotNil(lastMessage)
		XCTAssertEqual(lastMessage?.packet, .status(.init(id: 1, path: "")))
		XCTAssertNoThrow(try channel.writeInbound(MessagePart.end))

		XCTAssertNoThrow(try channel.writeInbound(MessagePart.header(.write(.init(id: 2, handle: "", offset: 0)), 1)))
		XCTAssertEqual(lastMessage?.packet, .status(.init(id: 1, path: ""))) // Same

		XCTAssertNoThrow(try channel.writeInbound(MessagePart.body(ByteBuffer(bytes: [0x01]))))
		switch handler.state {
		case let .processingMessage(current: _, queue: queue, needsContextRead: _, canWriteBody: _):
			XCTAssertEqual(queue.first?.stream.queuedData, [ByteBuffer(bytes: [0x01])])
		default:
			XCTFail()
		}
	}

	func testChannelReadProcessingMessageBodyError() {
		let channel = EmbeddedChannel()
		var lastMessage: SftpMessage?
		let server = CustomSftpServer(handleMessageHandler: { message in
			lastMessage = message
			return channel.eventLoop.makePromise().futureResult
		})
		let handler = SftpServerChannelHandler(server: server, logger: noopLogger)
		let eventCounterHandlerBegin = EventCounterHandler()
		XCTAssertNoThrow(try channel.pipeline.addHandlers([eventCounterHandlerBegin, handler]).wait())

		// Get state into processing message
		XCTAssertNoThrow(try channel.writeInbound(MessagePart.header(.write(.init(id: 1, handle: "", offset: 0)), 0)))
		XCTAssertNotNil(lastMessage)
		XCTAssertEqual(lastMessage?.packet, .write(.init(id: 1, handle: "", offset: 0)))
		XCTAssertNoThrow(try channel.writeInbound(MessagePart.end))

		XCTAssertThrowsError(try channel.writeInbound(MessagePart.body(ByteBuffer(bytes: [0x01]))))
		switch handler.state {
		case let .processingMessage(current: message, queue: _, needsContextRead: _, canWriteBody: _):
			XCTAssertEqual(message.stream.queuedData, [])
		default:
			XCTFail()
		}
	}

	func testChannelReadProcessingMessageEnd() {
		let channel = EmbeddedChannel()
		var lastMessage: SftpMessage?
		let server = CustomSftpServer(handleMessageHandler: { message in
			lastMessage = message
			return channel.eventLoop.makePromise().futureResult
		})
		let handler = SftpServerChannelHandler(server: server, logger: noopLogger)
		let eventCounterHandlerBegin = EventCounterHandler()
		XCTAssertNoThrow(try channel.pipeline.addHandlers([eventCounterHandlerBegin, handler]).wait())

		// Get state into processing message
		XCTAssertNoThrow(try channel.writeInbound(MessagePart.header(.status(.init(id: 1, path: "")), 0)))
		XCTAssertNotNil(lastMessage)
		XCTAssertEqual(lastMessage?.packet, .status(.init(id: 1, path: "")))
		XCTAssertNoThrow(try channel.writeInbound(MessagePart.end))

		XCTAssertNoThrow(try channel.writeInbound(MessagePart.end))
		switch handler.state {
		case let .processingMessage(current: message, queue: _, needsContextRead: _, canWriteBody: _):
			XCTAssertEqual(message.stream.isCompleted, true)
		default:
			XCTFail()
		}
	}

	// MARK: `read(context:)`

	func testReadAwaiting() {
		let channel = EmbeddedChannel()
		let server = CustomSftpServer(handleMessageHandler: { message in
			return channel.eventLoop.makePromise().futureResult
		})
		let handler = SftpServerChannelHandler(server: server, logger: noopLogger)
		let eventCounterHandlerBegin = EventCounterHandler()
		XCTAssertNoThrow(try channel.pipeline.addHandlers([eventCounterHandlerBegin, handler]).wait())

		XCTAssertEqual(eventCounterHandlerBegin.readCalls, 0)

		// Already in awaitingHeader state

		channel.read()
		XCTAssertEqual(eventCounterHandlerBegin.readCalls, 1)
	}

	func testReadProcessingCanWriteAndQueueIsEmpty() {
		let channel = EmbeddedChannel()
		var lastMessage: SftpMessage?
		let server = CustomSftpServer(handleMessageHandler: { message in
			lastMessage = message
			return channel.eventLoop.makePromise().futureResult
		})
		let handler = SftpServerChannelHandler(server: server, logger: noopLogger)
		let eventCounterHandlerBegin = EventCounterHandler()
		XCTAssertNoThrow(try channel.pipeline.addHandlers([eventCounterHandlerBegin, handler]).wait())

		XCTAssertEqual(eventCounterHandlerBegin.readCalls, 0)

		// Begin processing a message
		XCTAssertNoThrow(try channel.writeInbound(MessagePart.header(.write(.init(id: 1, handle: "", offset: 0)), 1)))
		guard let message = lastMessage else {
			XCTFail()
			return
		}
		// Begin collecting to enable canWriteBody. Queue should be empty.
		message.stream.collect(onComplete: { }, handler: { _ in channel.eventLoop.makePromise().futureResult })

		channel.read()
		XCTAssertEqual(eventCounterHandlerBegin.readCalls, 1)
	}

	func testReadProcessingCantWrite() {
		let channel = EmbeddedChannel()
		var lastMessage: SftpMessage?
		let server = CustomSftpServer(handleMessageHandler: { message in
			lastMessage = message
			return channel.eventLoop.makePromise().futureResult
		})
		let handler = SftpServerChannelHandler(server: server, logger: noopLogger)
		let eventCounterHandlerBegin = EventCounterHandler()
		XCTAssertNoThrow(try channel.pipeline.addHandlers([eventCounterHandlerBegin, handler]).wait())

		XCTAssertEqual(eventCounterHandlerBegin.readCalls, 0)

		// Begin processing a message
		XCTAssertNoThrow(try channel.writeInbound(MessagePart.header(.write(.init(id: 1, handle: "", offset: 0)), 1)))
		XCTAssertNotNil(lastMessage)
		// Don't collect so canWriteBody is false
		switch handler.state {
		case .processingMessage(current: _, queue: _, needsContextRead: false, canWriteBody: false):
			break
		default:
			XCTFail()
		}

		channel.read()
		XCTAssertEqual(eventCounterHandlerBegin.readCalls, 0)
		switch handler.state {
		case .processingMessage(current: _, queue: _, needsContextRead: true, canWriteBody: false):
			break
		default:
			XCTFail()
		}
	}

	func testReadProcessingFullQueue() {
		let channel = EmbeddedChannel()
		var lastMessage: SftpMessage?
		let server = CustomSftpServer(handleMessageHandler: { message in
			lastMessage = message
			return channel.eventLoop.makePromise().futureResult
		})
		let handler = SftpServerChannelHandler(server: server, logger: noopLogger)
		let eventCounterHandlerBegin = EventCounterHandler()
		XCTAssertNoThrow(try channel.pipeline.addHandlers([eventCounterHandlerBegin, handler]).wait())

		XCTAssertEqual(eventCounterHandlerBegin.readCalls, 0)

		// Begin processing a message
		XCTAssertNoThrow(try channel.writeInbound(MessagePart.header(.write(.init(id: 1, handle: "", offset: 0)), 1)))
		guard let message = lastMessage else {
			XCTFail()
			return
		}
		// Begin collecting to enable canWriteBody. Queue should be empty.
		message.stream.collect(onComplete: { }, handler: { _ in channel.eventLoop.makePromise().futureResult })

		// Add to queue
		XCTAssertNoThrow(try channel.writeInbound(MessagePart.header(.write(.init(id: 1, handle: "", offset: 0)), 1)))
		switch handler.state {
		case .processingMessage(current: _, queue: _, needsContextRead: false, canWriteBody: true):
			break
		default:
			XCTFail()
		}

		channel.read()
		XCTAssertEqual(eventCounterHandlerBegin.readCalls, 0)
		switch handler.state {
		case .processingMessage(current: _, queue: _, needsContextRead: true, canWriteBody: true):
			break
		default:
			XCTFail()
		}
	}

	// MARK: `write(context:data:promise:)`

	// MARK: `createMessage`

	// MARK: `messageCompleted`

	static var allTests = [
		("testHandlerErrorDescription", testHandlerErrorDescription),
	]
}
