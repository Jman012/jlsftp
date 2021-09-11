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

	public func testWriteUnexpectedWrite() {
		let channel = EmbeddedChannel()
		let server = CustomSftpServer(handleMessageHandler: { message in
			return channel.eventLoop.makePromise().futureResult
		})
		let handler = SftpServerChannelHandler(server: server, logger: noopLogger)
		XCTAssertNoThrow(try channel.pipeline.addHandler(handler).wait())

		// Don't get state into processing a message

		// Write a simple header-only packet
		let replyPacket: Packet = .handleReply(.init(id: 1, handle: "a"))
		let replyMessage = SftpMessage(packet: replyPacket, dataLength: 0, shouldReadHandler: { _ in })
		// Expect the error
		XCTAssertThrowsError(try channel.writeOutbound(replyMessage))
		XCTAssertThrowsError(try channel.throwIfErrorCaught())
	}

	public func testWriteHeader() {
		let channel = EmbeddedChannel()
		let server = CustomSftpServer(handleMessageHandler: { message in
			return channel.eventLoop.makePromise().futureResult
		})
		let handler = SftpServerChannelHandler(server: server, logger: noopLogger)
		XCTAssertNoThrow(try channel.pipeline.addHandler(handler).wait())

		// Get state into processing a message
		XCTAssertNoThrow(try channel.writeInbound(MessagePart.header(.status(.init(id: 1, path: "")), 0)))

		// Write a simple header-only packet
		let replyPacket: Packet = .handleReply(.init(id: 1, handle: "a"))
		let replyMessage = SftpMessage(packet: replyPacket, dataLength: 0, shouldReadHandler: { _ in })
		XCTAssertNoThrow(try channel.writeOutbound(replyMessage))

		// Make sure it went through properly
		let replyPart: MessagePart? = try? channel.readOutbound(as: MessagePart.self)
		XCTAssertNotNil(replyPart)
		XCTAssertEqual(replyPart, .header(.handleReply(.init(id: 1, handle: "a")), 0))
	}

	public func testWriteBody() {
		let channel = EmbeddedChannel()
		let server = CustomSftpServer(handleMessageHandler: { message in
			return channel.eventLoop.makePromise().futureResult
		})
		let handler = SftpServerChannelHandler(server: server, logger: noopLogger)
		XCTAssertNoThrow(try channel.pipeline.addHandler(handler).wait())

		// Get state into processing a message
		XCTAssertNoThrow(try channel.writeInbound(MessagePart.header(.status(.init(id: 1, path: "")), 0)))

		// Write a simple header-only packet
		let replyPacket: Packet = .dataReply(.init(id: 1, dataLength: 5))
		let replyMessage = SftpMessage(packet: replyPacket, dataLength: 5, shouldReadHandler: { _ in })
		let writeFuture = channel.write(replyMessage)
		XCTAssertNoThrow(try channel.throwIfErrorCaught())

		// Make sure the header went through properly
		channel.flush()
		var replyPart: MessagePart? = try? channel.readOutbound(as: MessagePart.self)
		XCTAssertNotNil(replyPart)
		XCTAssertEqual(replyPart, .header(.dataReply(.init(id: 1, dataLength: 5)), 5))

		// Write some data and ensure it went through properly
		_ = replyMessage.sendData(ByteBuffer(bytes: [0x01, 0x02]))
		replyPart = try? channel.readOutbound(as: MessagePart.self)
		XCTAssertNotNil(replyPart)
		XCTAssertEqual(replyPart, .body(ByteBuffer(bytes: [0x01, 0x02])))

		_ = replyMessage.sendData(ByteBuffer(bytes: [0x03, 0x04, 0x05]))
		replyPart = try? channel.readOutbound(as: MessagePart.self)
		XCTAssertNotNil(replyPart)
		XCTAssertEqual(replyPart, .body(ByteBuffer(bytes: [0x03, 0x04, 0x05])))

		// Make sure the future completes fully
		replyMessage.completeData()
		XCTAssertNoThrow(try writeFuture.wait())
	}

	// MARK: `createMessage`

	public func testCreateMessageBackpressure() {
		let channel = EmbeddedChannel()
		var lastMessage: SftpMessage?
		let server = CustomSftpServer(handleMessageHandler: { message in
			lastMessage = message
			return channel.eventLoop.makePromise().futureResult
		})
		let handler = SftpServerChannelHandler(server: server, logger: noopLogger)
		handler.outstandingFutureLimit = 1 // Single future to trigger backpressure. Easier for tests.
		XCTAssertNoThrow(try channel.pipeline.addHandler(handler).wait())

		// Get state into processing a message
		XCTAssertNoThrow(try channel.writeInbound(MessagePart.header(.write(.init(id: 1, handle: "a", offset: 0)), 5)))
		guard let message = lastMessage else {
			XCTFail()
			return
		}

		// Ensure starting state
		switch handler.state {
		case .processingMessage(current: _, queue: _, needsContextRead: false, canWriteBody: false):
			break
		default:
			XCTFail()
		}

		// Start collecting
		var promises: [EventLoopPromise<Void>] = []
		message.stream.collect(onComplete: { }, handler: { buffer in
			let newPromise: EventLoopPromise<Void> = channel.eventLoop.makePromise()
			promises.append(newPromise)
			return newPromise.futureResult
		})

		// Ensure starting state after starting collecting
		switch handler.state {
		case .processingMessage(current: _, queue: _, needsContextRead: false, canWriteBody: true):
			break
		default:
			XCTFail()
		}

		// Write first buffer. Should trigger backpressure.
		XCTAssertNoThrow(try channel.writeInbound(MessagePart.body(ByteBuffer(bytes: [0x01]))))
		XCTAssertEqual(promises.count, 1)
		switch handler.state {
		case .processingMessage(current: _, queue: _, needsContextRead: false, canWriteBody: false):
			break
		default:
			XCTFail()
		}

		// Add rest of data to queue. Unchanged state.
		XCTAssertNoThrow(try channel.writeInbound(MessagePart.body(ByteBuffer(bytes: [0x02, 0x03, 0x04, 0x05]))))
		XCTAssertEqual(promises.count, 1)
		switch handler.state {
		case .processingMessage(current: _, queue: _, needsContextRead: false, canWriteBody: false):
			break
		default:
			XCTFail()
		}

		// Complete
		XCTAssertNoThrow(try channel.writeInbound(MessagePart.end))
		XCTAssertEqual(message.stream.isCompleted, true)

		// Request read. Changed state
		channel.read()
		switch handler.state {
		case let .processingMessage(current: _, queue: queue, needsContextRead: true, canWriteBody: false):
			XCTAssertEqual(queue.count, 0)
			break
		default:
			XCTFail()
		}

		// Finish first promise. Should negate backpressure, take in next queued
		// write and go back to backpressure, all without triggering. No change to state yet.
		XCTAssertEqual(promises.count, 1)
		promises.removeFirst().succeed(())
		switch handler.state {
		case let .processingMessage(current: _, queue: queue, needsContextRead: true, canWriteBody: false):
			XCTAssertEqual(queue.count, 0)
			break
		default:
			XCTFail()
		}
		// Still one because the stream queue immediately dumped.
		XCTAssertEqual(promises.count, 1)

		// Finish last promise to finally trigger release of backpressure and
		// perform request read.
		promises.removeFirst().succeed(())
		switch handler.state {
		case let .processingMessage(current: _, queue: queue, needsContextRead: false, canWriteBody: true):
			XCTAssertEqual(queue.count, 0)
			break
		default:
			XCTFail()
		}

	}

	// MARK: `messageCompleted`

	func testMessageCompleted() {
		let channel = EmbeddedChannel()
		var lastMessage: SftpMessage?
		var messagePromise: EventLoopPromise<Void>?
		let server = CustomSftpServer(handleMessageHandler: { message in
			lastMessage = message
			let promise = channel.eventLoop.makePromise(of: Void.self)
			messagePromise = promise
			return promise.futureResult
		})
		let handler = SftpServerChannelHandler(server: server, logger: noopLogger)
		XCTAssertNoThrow(try channel.pipeline.addHandler(handler).wait())

		// Begin processing first message
		XCTAssertNoThrow(try channel.writeInbound(MessagePart.header(.status(.init(id: 1, path: "a")), 0)))
		XCTAssertEqual(lastMessage?.packet, .some(.status(.init(id: 1, path: "a"))))

		// Queue next message
		XCTAssertNoThrow(try channel.writeInbound(MessagePart.header(.close(.init(id: 2, handle: "b")), 0)))
		XCTAssertEqual(lastMessage?.packet, .some(.status(.init(id: 1, path: "a"))))
		switch handler.state {
		case let .processingMessage(current: _, queue: queue, needsContextRead: _, canWriteBody: _):
			XCTAssertEqual(queue.count, 1)
		default:
			XCTFail()
		}

		// Complete first message
		messagePromise?.succeed(())

		// Should be processing next message
		XCTAssertEqual(lastMessage?.packet, .some(.close(.init(id: 2, handle: "b"))))

		// Complete last
		messagePromise?.succeed(())
	}

	static var allTests = [
		("testHandlerErrorDescription", testHandlerErrorDescription),
		("testChannelReadAwaitingHeaderHeader", testChannelReadAwaitingHeaderHeader),
		("testChannelReadAwaitingHeaderBody", testChannelReadAwaitingHeaderBody),
		("testChannelReadAwaitingHeaderEnd", testChannelReadAwaitingHeaderEnd),
		("testChannelReadProcessingMessageHeader", testChannelReadProcessingMessageHeader),
		("testChannelReadProcessingMessageBodyValid", testChannelReadProcessingMessageBodyValid),
		("testChannelReadProcessingMessageBodyError", testChannelReadProcessingMessageBodyError),
		("testChannelReadProcessingMessageEnd", testChannelReadProcessingMessageEnd),
		("testReadAwaiting", testReadAwaiting),
		("testReadProcessingCanWriteAndQueueIsEmpty", testReadProcessingCanWriteAndQueueIsEmpty),
		("testReadProcessingCantWrite", testReadProcessingCantWrite),
		("testReadProcessingFullQueue", testReadProcessingFullQueue),
		("testWriteUnexpectedWrite", testWriteUnexpectedWrite),
		("testWriteHeader", testWriteHeader),
		("testWriteBody", testWriteBody),
		("testCreateMessageBackpressure", testCreateMessageBackpressure),
		("testMessageCompleted", testMessageCompleted),
	]
}
