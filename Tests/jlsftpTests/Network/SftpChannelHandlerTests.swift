import XCTest
import Combine
import NIO
@testable import jlsftp

/// Tests that the handler passes on message parts to the server as messages
/// correctly.
final class SftpChannelHandlerTests: XCTestCase {

	func testValid() {
		let channel = EmbeddedChannel()
		var currentHandleMessagePromise: EventLoopPromise<Void>!
		var lastHandledMessage: SftpMessage?
		let customServer = CustomSftpServer(
			handleMessageHandler: { message in
				lastHandledMessage = message
				return currentHandleMessagePromise.futureResult
		})
		let sftpChannelHandler = SftpChannelHandler(server: customServer)

		XCTAssertNoThrow(try channel.pipeline.addHandler(sftpChannelHandler).wait())
		// Test a single header-only packet
		var messagePart: MessagePart = .header(.initializeV3(InitializePacketV3(version: .v3, extensionData: [])), 0)
		currentHandleMessagePromise = channel.eventLoop.makePromise()
		XCTAssertNoThrow(try channel.writeInbound(messagePart))
		currentHandleMessagePromise.completeWith(.success(()))
		XCTAssertEqual(lastHandledMessage?.packet, .some(.initializeV3(InitializePacketV3(version: .v3, extensionData: []))))

		// Test a packet with with a body
		messagePart = .header(.dataReply(.init(id: 1)), 10)
		currentHandleMessagePromise = channel.eventLoop.makePromise()
		XCTAssertNoThrow(try channel.writeInbound(messagePart))
		XCTAssertEqual(lastHandledMessage?.packet, .some(.dataReply(DataReplyPacket(id: 1))))
		var didComplete = false
		var lastValue: ByteBuffer?

		// In conjunction with the above, test that writing the body works
		// as intended. Here, construct the sink.
		XCTAssertNoThrow(try withExtendedLifetime(lastHandledMessage!.data.sink(receiveCompletion: { _ in
			didComplete = true
		}, receiveValue: { buffer in
			lastValue = buffer
		})) {
			// Write the first 6 of 10 bytes.
			messagePart = .body(ByteBuffer(bytes: [0x01, 0x01, 0x01, 0x01, 0x01, 0x01]))
			XCTAssertNoThrow(try channel.writeInbound(messagePart))
			XCTAssertEqual(lastHandledMessage?.packet, .some(.dataReply(DataReplyPacket(id: 1))))
			XCTAssertEqual(didComplete, false)
			XCTAssertEqual(lastValue, ByteBuffer(bytes: [0x01, 0x01, 0x01, 0x01, 0x01, 0x01]))

			// Write the last 4 of the 10 bytes.
			messagePart = .body(ByteBuffer(bytes: [0x01, 0x01, 0x01, 0x01]))
			XCTAssertNoThrow(try channel.writeInbound(messagePart))
			XCTAssertEqual(lastHandledMessage?.packet, .some(.dataReply(DataReplyPacket(id: 1))))
			XCTAssertEqual(didComplete, false)
			XCTAssertEqual(lastValue, ByteBuffer(bytes: [0x01, 0x01, 0x01, 0x01]))

			// Mark the end of the message.
			messagePart = .end
			XCTAssertNoThrow(try channel.writeInbound(messagePart))
			XCTAssertEqual(lastHandledMessage?.packet, .some(.dataReply(DataReplyPacket(id: 1))))
			XCTAssertEqual(didComplete, true)
			XCTAssertEqual(lastValue, ByteBuffer(bytes: [0x01, 0x01, 0x01, 0x01]))
		})

		currentHandleMessagePromise.completeWith(.success(()))

		XCTAssertNoThrow(try channel.throwIfErrorCaught())
		XCTAssertNoThrow(XCTAssert(try channel.finish().isClean))
	}

	func testValidNop() {
		let channel = EmbeddedChannel()
		var currentHandleMessagePromise: EventLoopPromise<Void>!
		var lastHandledMessage: SftpMessage?
		let customServer = CustomSftpServer(
			handleMessageHandler: { message in
				lastHandledMessage = message
				return currentHandleMessagePromise.futureResult
		})
		let sftpChannelHandler = SftpChannelHandler(server: customServer)

		XCTAssertNoThrow(try channel.pipeline.addHandler(sftpChannelHandler).wait())

		// Ensure NOPs work.
		let messagePart: MessagePart = .header(.nopDebug(NOPDebugPacket(message: "test")), 0)
		currentHandleMessagePromise = channel.eventLoop.makePromise()
		XCTAssertNoThrow(try channel.writeInbound(messagePart))
		currentHandleMessagePromise.completeWith(.success(()))
		XCTAssertEqual(lastHandledMessage?.packet, .some(.nopDebug(NOPDebugPacket(message: "test"))))

		XCTAssertNoThrow(try channel.throwIfErrorCaught())
		XCTAssertNoThrow(XCTAssert(try channel.finish().isClean))
	}

	func testInvalidUnexpectedHeaderWhileProcessing() {
		let channel = EmbeddedChannel()
		var currentHandleMessagePromise: EventLoopPromise<Void>!
		var lastHandledMessage: SftpMessage?
		let customServer = CustomSftpServer(
			handleMessageHandler: { message in
				lastHandledMessage = message
				return currentHandleMessagePromise.futureResult
		})
		let sftpChannelHandler = SftpChannelHandler(server: customServer)

		XCTAssertNoThrow(try channel.pipeline.addHandler(sftpChannelHandler).wait())

		// First, put in a DataReply with 10 bytes of expected body.
		var messagePart: MessagePart = .header(.dataReply(DataReplyPacket(id: 1)), 10)
		currentHandleMessagePromise = channel.eventLoop.makePromise()
		XCTAssertNoThrow(try channel.writeInbound(messagePart))
		XCTAssertEqual(lastHandledMessage?.packet, .some(.dataReply(DataReplyPacket(id: 1))))
		XCTAssertNoThrow(try channel.throwIfErrorCaught())

		// Next, instead of supplying a body, give it an unexpected other header.
		lastHandledMessage = nil
		messagePart = .header(.status(StatusPacket(id: 2, path: "a")), 0)
		XCTAssertThrowsError(try channel.writeInbound(messagePart)) { error in
			XCTAssert(error is SftpChannelHandler.HandlerError)
			switch error as! SftpChannelHandler.HandlerError {
			case .unexpected(messagePart, .processingMessage(_)):
				break
			default:
				XCTFail()
			}
		}
		XCTAssertEqual(lastHandledMessage?.packet, .none)

		currentHandleMessagePromise.completeWith(.success(()))
		XCTAssertNoThrow(XCTAssert(try channel.finish().isClean))
	}

	func testInvalidUnexpectedHeaderWhileFinishing() {
		let channel = EmbeddedChannel()
		var currentHandleMessagePromise: EventLoopPromise<Void>!
		var lastHandledMessage: SftpMessage?
		let customServer = CustomSftpServer(
			handleMessageHandler: { message in
				lastHandledMessage = message
				return currentHandleMessagePromise.futureResult
		})
		let sftpChannelHandler = SftpChannelHandler(server: customServer)

		XCTAssertNoThrow(try channel.pipeline.addHandler(sftpChannelHandler).wait())

		// First, put in a regular header, but do not complete the promise.
		var messagePart: MessagePart = .header(.close(.init(id: 1, handle: "a")), 0)
		currentHandleMessagePromise = channel.eventLoop.makePromise()
		XCTAssertNoThrow(try channel.writeInbound(messagePart))
		XCTAssertEqual(lastHandledMessage?.packet, .some(.close(.init(id: 1, handle: "a"))))
		XCTAssertNoThrow(try channel.throwIfErrorCaught())

		// Next, put in another header, expecting the error.
		messagePart = .header(.close(.init(id: 2, handle: "b")), 0)
		XCTAssertThrowsError(try channel.writeInbound(messagePart)) { error in
			XCTAssert(error is SftpChannelHandler.HandlerError)
			switch error as! SftpChannelHandler.HandlerError {
			case .unexpected(messagePart, .awaitingFinishedReply(_)):
				break
			default:
				XCTFail()
			}
		}
		XCTAssertEqual(lastHandledMessage?.packet, .some(.close(.init(id: 1, handle: "a"))))

		currentHandleMessagePromise.completeWith(.success(()))
		XCTAssertNoThrow(XCTAssert(try channel.finish().isClean))
	}

	func testInvalidUnexpectedBodyWhileAwaiting() {
		let channel = EmbeddedChannel()
		let currentHandleMessagePromise: EventLoopPromise<Void>! = nil
		var lastHandledMessage: SftpMessage?
		let customServer = CustomSftpServer(
			handleMessageHandler: { message in
				lastHandledMessage = message
				return currentHandleMessagePromise.futureResult
		})
		let sftpChannelHandler = SftpChannelHandler(server: customServer)

		XCTAssertNoThrow(try channel.pipeline.addHandler(sftpChannelHandler).wait())

		// Send a Body MessagePart when the channel is expecting a header
		let messagePart: MessagePart = .body(ByteBuffer(bytes: [0x01]))

		XCTAssertThrowsError(try channel.writeInbound(messagePart)) { error in
			XCTAssert(error is SftpChannelHandler.HandlerError)
			switch error as! SftpChannelHandler.HandlerError {
			case .unexpected(messagePart, .awaitingHeader):
				break
			default:
				XCTFail()
			}
		}
		XCTAssertEqual(lastHandledMessage?.packet, .none)

		XCTAssertNoThrow(XCTAssert(try channel.finish().isClean))
	}

	func testInvalidUnexpectedBodyWhileFinishing() {
		let channel = EmbeddedChannel()
		var currentHandleMessagePromise: EventLoopPromise<Void>!
		var lastHandledMessage: SftpMessage?
		let customServer = CustomSftpServer(
			handleMessageHandler: { message in
				lastHandledMessage = message
				return currentHandleMessagePromise.futureResult
		})
		let sftpChannelHandler = SftpChannelHandler(server: customServer)

		XCTAssertNoThrow(try channel.pipeline.addHandler(sftpChannelHandler).wait())

		// First, send a header (not expecting body) without completing the promise.
		var messagePart: MessagePart = .header(.close(.init(id: 1, handle: "a")), 0)
		currentHandleMessagePromise = channel.eventLoop.makePromise()
		XCTAssertNoThrow(try channel.writeInbound(messagePart))
		XCTAssertEqual(lastHandledMessage?.packet, .some(.close(.init(id: 1, handle: "a"))))

		// Second, send random body data while it's unexpected (still awaiting header to finish)
		messagePart = .body(ByteBuffer(bytes: [0x01]))
		XCTAssertThrowsError(try channel.writeInbound(messagePart)) { error in
			XCTAssert(error is SftpChannelHandler.HandlerError)
			switch error as! SftpChannelHandler.HandlerError {
			case .unexpected(messagePart, .awaitingFinishedReply(_)):
				break
			default:
				XCTFail()
			}
		}
		XCTAssertEqual(lastHandledMessage?.packet, .some(.close(.init(id: 1, handle: "a"))))

		currentHandleMessagePromise.completeWith(.success(()))
		XCTAssertNoThrow(XCTAssert(try channel.finish().isClean))
	}

	func testInvalidTooManyBodyBytes() {
		let channel = EmbeddedChannel()
		var currentHandleMessagePromise: EventLoopPromise<Void>!
		var lastHandledMessage: SftpMessage?
		let customServer = CustomSftpServer(
			handleMessageHandler: { message in
				lastHandledMessage = message
				return currentHandleMessagePromise.futureResult
		})
		let sftpChannelHandler = SftpChannelHandler(server: customServer)

		XCTAssertNoThrow(try channel.pipeline.addHandler(sftpChannelHandler).wait())

		// Send a DataReply with an expected body size of 4 bytes.
		var messagePart: MessagePart = .header(.dataReply(DataReplyPacket(id: 1)), 4)
		currentHandleMessagePromise = channel.eventLoop.makePromise()
		XCTAssertNoThrow(try channel.writeInbound(messagePart))
		XCTAssertEqual(lastHandledMessage?.packet, .some(.dataReply(DataReplyPacket(id: 1))))
		XCTAssertNoThrow(try channel.throwIfErrorCaught())

		XCTAssertNoThrow(
			try withExtendedLifetime(lastHandledMessage!.data.sink(receiveValue: { _ in })) {
				// Send a body of 2 bytes. Other tests ensure the bytes come through correctly.
				messagePart = .body(ByteBuffer(bytes: [0x01, 0x02]))
				XCTAssertNoThrow(try channel.writeInbound(messagePart))
				XCTAssertEqual(lastHandledMessage?.packet, .some(.dataReply(DataReplyPacket(id: 1))))
				XCTAssertNoThrow(try channel.throwIfErrorCaught())

				// Send a body of 4 bytes (totalling 6, above the expected 4) and expect
				// an error.
				messagePart = .body(ByteBuffer(bytes: [0x03, 0x04, 0x05, 0x06]))
				XCTAssertThrowsError(try channel.writeInbound(messagePart)) { error in
					XCTAssert(error is SftpMessage.SendDataError)
					if error is SftpMessage.SendDataError {
						switch error as! SftpMessage.SendDataError {
						case .tooMuchData:
							break
							//					default:
							//						XCTFail()
						}
					}
				}
				XCTAssertEqual(lastHandledMessage?.packet, .some(.dataReply(DataReplyPacket(id: 1))))
			}
		)

		currentHandleMessagePromise.completeWith(.success(()))
		XCTAssertNoThrow(XCTAssert(try channel.finish().isClean))
	}

	func testInvalidUnexpectedEndWhileAwaiting() {
		let channel = EmbeddedChannel()
		let currentHandleMessagePromise: EventLoopPromise<Void>! = nil
		var lastHandledMessage: SftpMessage?
		let customServer = CustomSftpServer(
			handleMessageHandler: { message in
				lastHandledMessage = message
				return currentHandleMessagePromise.futureResult
		})
		let sftpChannelHandler = SftpChannelHandler(server: customServer)

		XCTAssertNoThrow(try channel.pipeline.addHandler(sftpChannelHandler).wait())

		// Send a Body MessagePart when the channel is expecting a header
		let messagePart: MessagePart = .end
		XCTAssertThrowsError(try channel.writeInbound(messagePart)) { error in
			XCTAssert(error is SftpChannelHandler.HandlerError)
			switch error as! SftpChannelHandler.HandlerError {
			case .unexpected(messagePart, .awaitingHeader):
				break
			default:
				XCTFail()
			}
		}
		XCTAssertEqual(lastHandledMessage?.packet, .none)

		XCTAssertNoThrow(XCTAssert(try channel.finish().isClean))
	}

	func testInvalidUnexpectedEndWhileFinishing() {
		let channel = EmbeddedChannel()
		var currentHandleMessagePromise: EventLoopPromise<Void>!
		var lastHandledMessage: SftpMessage?
		let customServer = CustomSftpServer(
			handleMessageHandler: { message in
				lastHandledMessage = message
				return currentHandleMessagePromise.futureResult
		})
		let sftpChannelHandler = SftpChannelHandler(server: customServer)

		XCTAssertNoThrow(try channel.pipeline.addHandler(sftpChannelHandler).wait())

		// First, send a header (not expecting body) without completing the promise.
		var messagePart: MessagePart = .header(.close(.init(id: 1, handle: "a")), 0)
		currentHandleMessagePromise = channel.eventLoop.makePromise()
		XCTAssertNoThrow(try channel.writeInbound(messagePart))
		XCTAssertEqual(lastHandledMessage?.packet, .some(.close(.init(id: 1, handle: "a"))))

		// Second, send a random end marker while it's unexpected (still awaiting header to finish)
		messagePart = .end
		XCTAssertThrowsError(try channel.writeInbound(messagePart)) { error in
			XCTAssert(error is SftpChannelHandler.HandlerError)
			switch error as! SftpChannelHandler.HandlerError {
			case .unexpected(messagePart, .awaitingFinishedReply(_)):
				break
			default:
				XCTFail()
			}
		}
		XCTAssertEqual(lastHandledMessage?.packet, .some(.close(.init(id: 1, handle: "a"))))

		currentHandleMessagePromise.completeWith(.success(()))
		XCTAssertNoThrow(XCTAssert(try channel.finish().isClean))
	}

	func testValidReplyHeader() {
		let channel = EmbeddedChannel()
		let customServer = CustomSftpServer()
		let sftpChannelHandler = SftpChannelHandler(server: customServer)
		XCTAssertNoThrow(try channel.pipeline.addHandler(sftpChannelHandler).wait())
		XCTAssertNoThrow(try channel.pipeline.register().wait())

		XCTAssert(customServer.registeredReplyHandler != nil)
		let message = SftpMessage(packet: .initializeV3(.init(version: .v3, extensionData: [])), dataLength: 0, shouldReadHandler: { _ in })
		let replyHandlerFuture = customServer.registeredReplyHandler!(message)
		channel.flush()
		let initHeader: MessagePart? = try! channel.readOutbound()
		XCTAssertNoThrow(try replyHandlerFuture.wait())
		XCTAssertEqual(initHeader, .header(.initializeV3(.init(version: .v3, extensionData: [])), 0))

		XCTAssertNoThrow(XCTAssert(try channel.finish().isClean))
	}

	func testValidReplyBody() {
		let channel = EmbeddedChannel()
		let customServer = CustomSftpServer()
		let sftpChannelHandler = SftpChannelHandler(server: customServer)
		XCTAssertNoThrow(try channel.pipeline.addHandler(sftpChannelHandler).wait())
		XCTAssertNoThrow(try channel.pipeline.register().wait())

		XCTAssert(customServer.registeredReplyHandler != nil)
		let message = SftpMessage(packet: .dataReply(.init(id: 1)), dataLength: 5, shouldReadHandler: { _ in })
		let replyHandlerFuture = customServer.registeredReplyHandler!(message)
		channel.flush()

		let initHeader: MessagePart? = try! channel.readOutbound()
		XCTAssertEqual(initHeader, .header(.dataReply(.init(id: 1)), 5))

		XCTAssertEqual(message.sendData(ByteBuffer(bytes: [0x00, 0x01])), .success(false))
		channel.flush()
		var bodyPart: MessagePart? = try! channel.readOutbound()
		XCTAssertEqual(bodyPart, .body(ByteBuffer(bytes: [0x00, 0x01])))

		XCTAssertEqual(message.sendData(ByteBuffer(bytes: [0x02, 0x03, 0x04])), .success(true))
		channel.flush()
		bodyPart = try! channel.readOutbound()
		XCTAssertEqual(bodyPart, .body(ByteBuffer(bytes: [0x02, 0x03, 0x04])))

		// Mark the message as complete after flushing and reading the end of
		// the body above. The variant test below puts this before the flush.
		message.completeData()
		channel.flush()
		let endPart: MessagePart? = try! channel.readOutbound()
		XCTAssertEqual(endPart, .end)

		try! replyHandlerFuture.wait()

		XCTAssert(try! channel.finish().isClean)
	}

	func testValidReplyBodyVariant() {
		let channel = EmbeddedChannel()
		let customServer = CustomSftpServer()
		let sftpChannelHandler = SftpChannelHandler(server: customServer)
		XCTAssertNoThrow(try channel.pipeline.addHandler(sftpChannelHandler).wait())
		XCTAssertNoThrow(try channel.pipeline.register().wait())

		XCTAssert(customServer.registeredReplyHandler != nil)
		let message = SftpMessage(packet: .dataReply(.init(id: 1)), dataLength: 5, shouldReadHandler: { _ in })
		let replyHandlerFuture = customServer.registeredReplyHandler!(message)
		channel.flush()

		let initHeader: MessagePart? = try! channel.readOutbound()
		XCTAssertEqual(initHeader, .header(.dataReply(.init(id: 1)), 5))

		XCTAssertEqual(message.sendData(ByteBuffer(bytes: [0x00, 0x01])), .success(false))
		channel.flush()
		var bodyPart: MessagePart? = try! channel.readOutbound()
		XCTAssertEqual(bodyPart, .body(ByteBuffer(bytes: [0x00, 0x01])))

		// Write the last of the body, and immediately complete the message
		// before flushing the channel. The variant test above completes later.
		XCTAssertEqual(message.sendData(ByteBuffer(bytes: [0x02, 0x03, 0x04])), .success(true))
		message.completeData()
		channel.flush()

		bodyPart = try! channel.readOutbound()
		XCTAssertEqual(bodyPart, .body(ByteBuffer(bytes: [0x02, 0x03, 0x04])))

		let endPart: MessagePart? = try! channel.readOutbound()
		XCTAssertEqual(endPart, .end)

		XCTAssertNoThrow(try replyHandlerFuture.wait())

		XCTAssert(try! channel.finish().isClean)
	}

	func testReadState() {
		let channel = EmbeddedChannel()
		var currentHandleMessagePromise: EventLoopPromise<Void>!
		var lastHandledMessage: SftpMessage?
		let customServer = CustomSftpServer(
			handleMessageHandler: { message in
				lastHandledMessage = message
				return currentHandleMessagePromise.futureResult
		})
		let sftpChannelHandler = SftpChannelHandler(server: customServer)

		let messagePart: MessagePart = .header(.close(.init(id: 1, handle: "a")), 0)
		channel.read()
	}

	static var allTests = [
		("testValid", testValid),
		("testValidNop", testValidNop),
		("testInvalidUnexpectedHeaderWhileProcessing", testInvalidUnexpectedHeaderWhileProcessing),
		("testInvalidUnexpectedHeaderWhileFinishing", testInvalidUnexpectedHeaderWhileFinishing),
		("testInvalidUnexpectedBodyWhileAwaiting", testInvalidUnexpectedBodyWhileAwaiting),
		("testInvalidUnexpectedBodyWhileFinishing", testInvalidUnexpectedBodyWhileFinishing),
		("testInvalidTooManyBodyBytes", testInvalidTooManyBodyBytes),
		("testInvalidUnexpectedEndWhileAwaiting", testInvalidUnexpectedEndWhileAwaiting),
		("testInvalidUnexpectedEndWhileFinishing", testInvalidUnexpectedEndWhileFinishing),
		("testValidReplyHeader", testValidReplyHeader),
		("testValidReplyBody", testValidReplyBody),
		("testValidReplyBodyVariant", testValidReplyBodyVariant),
		("testReadState", testReadState),
	]
}
