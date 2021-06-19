import XCTest
import Combine
import NIO
@testable import jlsftp

/// Tests that the handler passes on message parts to the server as messages
/// correctly.
final class SftpChannelHandlerTests: XCTestCase {

	func testValid() {
		var lastHandledMessage: SftpMessage?
		let customServer = CustomSftpServer(
			handleMessageHandler: { message in lastHandledMessage = message })
		let sftpChannelHandler = SftpChannelHandler(server: customServer)

		let channel = EmbeddedChannel()
		try! channel.pipeline.addHandler(sftpChannelHandler).wait()

		// Test a single header-only packet
		var messagePart: MessagePart = .header(.initializeV3(InitializePacketV3(version: .v3, extensionData: [])), 0)
		try! channel.writeInbound(messagePart)
		XCTAssertEqual(lastHandledMessage?.packet, .some(.initializeV3(InitializePacketV3(version: .v3, extensionData: []))))

		// Test a packet with with a body
		messagePart = .header(.dataReply(.init(id: 1)), 10)
		try! channel.writeInbound(messagePart)
		XCTAssertEqual(lastHandledMessage?.packet, .some(.dataReply(DataReplyPacket(id: 1))))
		var didComplete = false
		var lastValue: ByteBuffer?

		// In conjunction with the above, test that writing the body works
		// as intended. Here, construct the sink.
		withExtendedLifetime(lastHandledMessage!.data.sink(receiveCompletion: { _ in
			didComplete = true
		}, receiveValue: { buffer in
			lastValue = buffer
		})) {
			// Write the first 6 of 10 bytes.
			messagePart = .body(ByteBuffer(bytes: [0x01, 0x01, 0x01, 0x01, 0x01, 0x01]))
			try! channel.writeInbound(messagePart)
			XCTAssertEqual(lastHandledMessage?.packet, .some(.dataReply(DataReplyPacket(id: 1))))
			XCTAssertEqual(didComplete, false)
			XCTAssertEqual(lastValue, ByteBuffer(bytes: [0x01, 0x01, 0x01, 0x01, 0x01, 0x01]))

			// Write the last 4 of the 10 bytes.
			messagePart = .body(ByteBuffer(bytes: [0x01, 0x01, 0x01, 0x01]))
			try! channel.writeInbound(messagePart)
			XCTAssertEqual(lastHandledMessage?.packet, .some(.dataReply(DataReplyPacket(id: 1))))
			XCTAssertEqual(didComplete, false)
			XCTAssertEqual(lastValue, ByteBuffer(bytes: [0x01, 0x01, 0x01, 0x01]))

			// Mark the end of the message.
			messagePart = .end
			try! channel.writeInbound(messagePart)
			XCTAssertEqual(lastHandledMessage?.packet, .some(.dataReply(DataReplyPacket(id: 1))))
			XCTAssertEqual(didComplete, true)
			XCTAssertEqual(lastValue, ByteBuffer(bytes: [0x01, 0x01, 0x01, 0x01]))
		}

		XCTAssertNoThrow(try channel.throwIfErrorCaught())
		XCTAssert(try! channel.finish().isClean)
	}

	func testValidNop() {
		var lastHandledMessage: SftpMessage?
		let customServer = CustomSftpServer(
			handleMessageHandler: { message in lastHandledMessage = message })
		let sftpChannelHandler = SftpChannelHandler(server: customServer)

		let channel = EmbeddedChannel()
		try! channel.pipeline.addHandler(sftpChannelHandler).wait()

		// Ensure NOPs work.
		let messagePart: MessagePart = .header(.nopDebug(NOPDebugPacket(message: "test")), 0)
		try! channel.writeInbound(messagePart)
		XCTAssertEqual(lastHandledMessage?.packet, .some(.nopDebug(NOPDebugPacket(message: "test"))))

		XCTAssertNoThrow(try channel.throwIfErrorCaught())
		XCTAssert(try! channel.finish().isClean)
	}

	func testInvalidUnexpectedHeader() {
		var lastHandledMessage: SftpMessage?
		let customServer = CustomSftpServer(
			handleMessageHandler: { message in lastHandledMessage = message })
		let sftpChannelHandler = SftpChannelHandler(server: customServer)

		let channel = EmbeddedChannel()
		try! channel.pipeline.addHandler(sftpChannelHandler).wait()

		// First, put in a DataReply with 10 bytes of expected body.
		var messagePart: MessagePart = .header(.dataReply(DataReplyPacket(id: 1)), 10)
		try! channel.writeInbound(messagePart)
		XCTAssertEqual(lastHandledMessage?.packet, .some(.dataReply(DataReplyPacket(id: 1))))
		XCTAssertNoThrow(try channel.throwIfErrorCaught())

		// Next, instead of supplying a body, give it an unexpected other header.
		lastHandledMessage = nil
		messagePart = .header(.status(StatusPacket(id: 2, path: "a")), 0)
		XCTAssertThrowsError(try channel.writeInbound(messagePart)) { error in
			XCTAssert(error is SftpChannelHandler.HandlerError)
			switch error as! SftpChannelHandler.HandlerError {
			case .unexpectedInput(_):
				break
//			default:
//				XCTFail()
			}
		}
		XCTAssertEqual(lastHandledMessage?.packet, .none)

		XCTAssert(try! channel.finish().isClean)
	}

	func testInvalidUnexpectedBody() {
		var lastHandledMessage: SftpMessage?
		let customServer = CustomSftpServer(
			handleMessageHandler: { message in lastHandledMessage = message })
		let sftpChannelHandler = SftpChannelHandler(server: customServer)

		let channel = EmbeddedChannel()
		try! channel.pipeline.addHandler(sftpChannelHandler).wait()

		// Send a Body MessagePart when the channel is expecting a header
		let messagePart: MessagePart = .body(ByteBuffer(bytes: [0x01]))

		XCTAssertThrowsError(try channel.writeInbound(messagePart)) { error in
			XCTAssert(error is SftpChannelHandler.HandlerError)
			switch error as! SftpChannelHandler.HandlerError {
			case .unexpectedInput(_):
				break
//			default:
//				XCTFail()
			}
		}
		XCTAssertEqual(lastHandledMessage?.packet, .none)

		XCTAssert(try! channel.finish().isClean)
	}

	func testInvalidTooManyBodyBytes() {
		var lastHandledMessage: SftpMessage?
		let customServer = CustomSftpServer(
			handleMessageHandler: { message in lastHandledMessage = message })
		let sftpChannelHandler = SftpChannelHandler(server: customServer)

		let channel = EmbeddedChannel()
		try! channel.pipeline.addHandler(sftpChannelHandler).wait()

		// Send a DataReply with an expected body size of 4 bytes.
		var messagePart: MessagePart = .header(.dataReply(DataReplyPacket(id: 1)), 4)
		try! channel.writeInbound(messagePart)
		XCTAssertEqual(lastHandledMessage?.packet, .some(.dataReply(DataReplyPacket(id: 1))))
		XCTAssertNoThrow(try channel.throwIfErrorCaught())

		do {
			try withExtendedLifetime(lastHandledMessage!.data.sink(receiveValue: { _ in })) {
				// Send a body of 2 bytes. Other tests ensure the bytes come through correctly.
				messagePart = .body(ByteBuffer(bytes: [0x01, 0x02]))
				try! channel.writeInbound(messagePart)
				XCTAssertEqual(lastHandledMessage?.packet, .some(.dataReply(DataReplyPacket(id: 1))))
				XCTAssertNoThrow(try channel.throwIfErrorCaught())

				// Send a body of 4 bytes (totalling 6, above the expected 4) and expect
				// an error.
				messagePart = .body(ByteBuffer(bytes: [0x03, 0x04, 0x05, 0x06]))
				XCTAssertThrowsError(try channel.writeInbound(messagePart)) { error in
					XCTAssert(error is SftpMessage.SendDataError)
					switch error as! SftpMessage.SendDataError {
					case .tooMuchData(_):
						break
//					default:
//						XCTFail()
					}
				}
				XCTAssertEqual(lastHandledMessage?.packet, .some(.dataReply(DataReplyPacket(id: 1))))
			}
		} catch {
			XCTFail()
		}

		XCTAssert(try! channel.finish().isClean)
	}

	func testInvalidUnexpectedEnd() {
		var lastHandledMessage: SftpMessage?
		let customServer = CustomSftpServer(
			handleMessageHandler: { message in lastHandledMessage = message })
		let sftpChannelHandler = SftpChannelHandler(server: customServer)

		let channel = EmbeddedChannel()
		try! channel.pipeline.addHandler(sftpChannelHandler).wait()

		// Send a Body MessagePart when the channel is expecting a header
		let messagePart: MessagePart = .end
		XCTAssertThrowsError(try channel.writeInbound(messagePart)) { error in
			XCTAssert(error is SftpChannelHandler.HandlerError)
			switch error as! SftpChannelHandler.HandlerError {
			case .unexpectedInput(_):
				break
//			default:
//				XCTFail()
			}
		}
		XCTAssertEqual(lastHandledMessage?.packet, .none)

		XCTAssert(try! channel.finish().isClean)
	}

	func testValidReplyHeader() {
		let channel = EmbeddedChannel()
		let customServer = CustomSftpServer()
		let sftpChannelHandler = SftpChannelHandler(server: customServer)
		try! channel.pipeline.addHandler(sftpChannelHandler).wait()
		try! channel.pipeline.register().wait()

		XCTAssert(customServer.registeredReplyHandler != nil)
		let message = SftpMessage(packet: .initializeV3(.init(version: .v3, extensionData: [])), dataLength: 0, shouldReadHandler: { _ in })
		let replyHandlerFuture = customServer.registeredReplyHandler!(message)
		channel.flush()
		let initHeader: MessagePart? = try! channel.readOutbound()
		try! replyHandlerFuture.wait()
		XCTAssertEqual(initHeader, .header(.initializeV3(.init(version: .v3, extensionData: [])), 0))

		XCTAssert(try! channel.finish().isClean)
	}

	func testValidReplyBody() {
		let channel = EmbeddedChannel()
		let customServer = CustomSftpServer()
		let sftpChannelHandler = SftpChannelHandler(server: customServer)
		try! channel.pipeline.addHandler(sftpChannelHandler).wait()
		try! channel.pipeline.register().wait()

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
		try! channel.pipeline.addHandler(sftpChannelHandler).wait()
		try! channel.pipeline.register().wait()

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

		try! replyHandlerFuture.wait()

		XCTAssert(try! channel.finish().isClean)
	}

	static var allTests = [
		("testValid", testValid),
		("testValidNop", testValidNop),
		("testInvalidUnexpectedHeader", testInvalidUnexpectedHeader),
		("testInvalidUnexpectedBody", testInvalidUnexpectedBody),
		("testInvalidTooManyBodyBytes", testInvalidTooManyBodyBytes),
		("testInvalidUnexpectedEnd", testInvalidUnexpectedEnd),
		("testValidReplyHeader", testValidReplyHeader),
		("testValidReplyBody", testValidReplyBody),
		("testValidReplyBodyVariant", testValidReplyBodyVariant),
	]
}
