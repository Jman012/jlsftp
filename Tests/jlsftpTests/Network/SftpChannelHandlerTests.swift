import XCTest
import Combine
import NIO
@testable import jlsftp

/// Tests that the handler passes on message parts to the server as messages
/// correctly.
final class SftpChannelHandlerTests: XCTestCase {

	func testValid() {
		let channel = EmbeddedChannel()
		let sftpChannelHandler = SftpChannelHandler()

		XCTAssertNoThrow(try channel.pipeline.addHandler(sftpChannelHandler).wait())
		// Test a single header-only packet
		var messagePart: MessagePart = .header(.initializeV3(InitializePacketV3(version: .v3, extensionData: [])), 0)
		XCTAssertNoThrow(try channel.writeInbound(messagePart))
		var message: SftpMessage? = try? channel.readInbound(as: SftpMessage.self)
		XCTAssertEqual(message?.packet, .some(.initializeV3(InitializePacketV3(version: .v3, extensionData: []))))

		// Test a packet with with a body
		messagePart = .header(.dataReply(.init(id: 1)), 10)
		XCTAssertNoThrow(try channel.writeInbound(messagePart))
		message = try? channel.readInbound(as: SftpMessage.self)
		XCTAssertEqual(message?.packet, .some(.dataReply(DataReplyPacket(id: 1))))
		var didComplete = false
		var lastValue: ByteBuffer?

		// In conjunction with the above, test that writing the body works
		// as intended. Here, construct the sink.
		XCTAssertNoThrow(try withExtendedLifetime(message!.data.sink(receiveCompletion: { _ in
			didComplete = true
		}, receiveValue: { buffer in
			lastValue = buffer
		})) {
			// Write the first 6 of 10 bytes.
			messagePart = .body(ByteBuffer(bytes: [0x01, 0x01, 0x01, 0x01, 0x01, 0x01]))
			XCTAssertNoThrow(try channel.writeInbound(messagePart))
			XCTAssertEqual(didComplete, false)
			XCTAssertEqual(lastValue, ByteBuffer(bytes: [0x01, 0x01, 0x01, 0x01, 0x01, 0x01]))

			// Write the last 4 of the 10 bytes.
			messagePart = .body(ByteBuffer(bytes: [0x01, 0x01, 0x01, 0x01]))
			XCTAssertNoThrow(try channel.writeInbound(messagePart))
			XCTAssertEqual(didComplete, false)
			XCTAssertEqual(lastValue, ByteBuffer(bytes: [0x01, 0x01, 0x01, 0x01]))

			// Mark the end of the message.
			messagePart = .end
			XCTAssertNoThrow(try channel.writeInbound(messagePart))
			XCTAssertEqual(didComplete, true)
			XCTAssertEqual(lastValue, ByteBuffer(bytes: [0x01, 0x01, 0x01, 0x01]))
		})

		XCTAssertNoThrow(try channel.throwIfErrorCaught())
		XCTAssertNoThrow(XCTAssert(try channel.finish().isClean))
	}

	func testValidNop() {
		let channel = EmbeddedChannel()
		let sftpChannelHandler = SftpChannelHandler()

		XCTAssertNoThrow(try channel.pipeline.addHandler(sftpChannelHandler).wait())

		// Ensure NOPs work.
		let messagePart: MessagePart = .header(.nopDebug(NOPDebugPacket(message: "test")), 0)
		XCTAssertNoThrow(try channel.writeInbound(messagePart))
		let message = try? channel.readInbound(as: SftpMessage.self)
		XCTAssertEqual(message?.packet, .some(.nopDebug(NOPDebugPacket(message: "test"))))

		XCTAssertNoThrow(try channel.throwIfErrorCaught())
		XCTAssertNoThrow(XCTAssert(try channel.finish().isClean))
	}

	func testInvalidUnexpectedHeaderWhileProcessing() {
		let channel = EmbeddedChannel()
		let sftpChannelHandler = SftpChannelHandler()

		XCTAssertNoThrow(try channel.pipeline.addHandler(sftpChannelHandler).wait())

		// First, put in a DataReply with 10 bytes of expected body.
		var messagePart: MessagePart = .header(.dataReply(DataReplyPacket(id: 1)), 10)
		XCTAssertNoThrow(try channel.writeInbound(messagePart))
		var message = try? channel.readInbound(as: SftpMessage.self)
		XCTAssertEqual(message?.packet, .some(.dataReply(DataReplyPacket(id: 1))))
		XCTAssertNoThrow(try channel.throwIfErrorCaught())

		// Next, instead of supplying a body, give it an unexpected other header.
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
		message = try? channel.readInbound(as: SftpMessage.self)
		XCTAssertNil(message)

		XCTAssertNoThrow(XCTAssert(try channel.finish().isClean))
	}

	func testInvalidUnexpectedBodyWhileAwaiting() {
		let channel = EmbeddedChannel()
		let sftpChannelHandler = SftpChannelHandler()

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
		let message = try? channel.readInbound(as: SftpMessage.self)
		XCTAssertNil(message)

		XCTAssertNoThrow(XCTAssert(try channel.finish().isClean))
	}

	func testInvalidTooManyBodyBytes() {
		let channel = EmbeddedChannel()
		let sftpChannelHandler = SftpChannelHandler()

		XCTAssertNoThrow(try channel.pipeline.addHandler(sftpChannelHandler).wait())

		// Send a DataReply with an expected body size of 4 bytes.
		var messagePart: MessagePart = .header(.dataReply(DataReplyPacket(id: 1)), 4)
		XCTAssertNoThrow(try channel.writeInbound(messagePart))
		var message = try? channel.readInbound(as: SftpMessage.self)
		XCTAssertEqual(message?.packet, .some(.dataReply(DataReplyPacket(id: 1))))
		XCTAssertNoThrow(try channel.throwIfErrorCaught())

		XCTAssertNoThrow(
			try withExtendedLifetime(message!.data.sink(receiveCompletion: { _ in }, receiveValue: { _ in })) {
				// Send a body of 2 bytes. Other tests ensure the bytes come through correctly.
				messagePart = .body(ByteBuffer(bytes: [0x01, 0x02]))
				XCTAssertNoThrow(try channel.writeInbound(messagePart))
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
						}
					}
				}
				message = try? channel.readInbound(as: SftpMessage.self)
				XCTAssertNil(message)
			}
		)

		XCTAssertNoThrow(XCTAssert(try channel.finish().isClean))
	}

	func testInvalidUnexpectedEndWhileAwaiting() {
		let channel = EmbeddedChannel()
		let sftpChannelHandler = SftpChannelHandler()

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
		let message = try? channel.readInbound(as: SftpMessage.self)
		XCTAssertNil(message)

		XCTAssertNoThrow(XCTAssert(try channel.finish().isClean))
	}

	func testValidReplyHeader() {
		let channel = EmbeddedChannel()
		let sftpChannelHandler = SftpChannelHandler()
		XCTAssertNoThrow(try channel.pipeline.addHandler(sftpChannelHandler).wait())
		XCTAssertNoThrow(try channel.pipeline.register().wait())

		let message = SftpMessage(packet: .initializeV3(.init(version: .v3, extensionData: [])), dataLength: 0, shouldReadHandler: { _ in })
		XCTAssertNoThrow(try channel.writeOutbound(message))
		channel.flush()
		let initHeader: MessagePart? = try! channel.readOutbound()
		XCTAssertEqual(initHeader, .header(.initializeV3(.init(version: .v3, extensionData: [])), 0))

		XCTAssertNoThrow(XCTAssert(try channel.finish().isClean))
	}

	func testValidReplyBody() {
		let channel = EmbeddedChannel()
		let sftpChannelHandler = SftpChannelHandler()
		XCTAssertNoThrow(try channel.pipeline.addHandler(sftpChannelHandler).wait())
		XCTAssertNoThrow(try channel.pipeline.register().wait())

		let message = SftpMessage(packet: .dataReply(.init(id: 1)), dataLength: 5, shouldReadHandler: { _ in })
		let writeFuture = channel.writeAndFlush(message)

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
		XCTAssertNoThrow(try writeFuture.wait())
		let endPart: MessagePart? = try! channel.readOutbound()
		XCTAssertEqual(endPart, .end)

		XCTAssert(try! channel.finish().isClean)
	}

	func testValidReplyBodyVariant() {
		let channel = EmbeddedChannel()
		let sftpChannelHandler = SftpChannelHandler()
		XCTAssertNoThrow(try channel.pipeline.addHandler(sftpChannelHandler).wait())
		XCTAssertNoThrow(try channel.pipeline.register().wait())

		let message = SftpMessage(packet: .dataReply(.init(id: 1)), dataLength: 5, shouldReadHandler: { _ in })
		let writeFuture = channel.writeAndFlush(message)

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
		XCTAssertNoThrow(try writeFuture.wait())

		bodyPart = try! channel.readOutbound()
		XCTAssertEqual(bodyPart, .body(ByteBuffer(bytes: [0x02, 0x03, 0x04])))

		let endPart: MessagePart? = try! channel.readOutbound()
		XCTAssertEqual(endPart, .end)

		XCTAssert(try! channel.finish().isClean)
	}

	func testErrorMessageCustom() {
		let data: [SftpChannelHandler.HandlerError] = [
			//.unexpected(.header(.close(.init(id: 1, handle: "a")), 0), .awaitingHeader),
			.unexpected(.header(.close(.init(id: 1, handle: "a")), 0), .processingMessage(SftpMessage(packet: .close(.init(id: 1, handle: "a")), dataLength: 0, shouldReadHandler: { _ in }))),

			.unexpected(.body(ByteBuffer(bytes: [0x01])), .awaitingHeader),
			//.unexpected(.body(ByteBuffer(bytes: [0x01])), .processingMessage(SftpMessage(packet: .close(.init(id: 1, handle: "a")), dataLength: 0, shouldReadHandler: { _ in }))),

			.unexpected(.end, .awaitingHeader),
			//.unexpected(.end, .processingMessage(SftpMessage(packet: .close(.init(id: 1, handle: "a")), dataLength: 0, shouldReadHandler: { _ in }))),
		]

		for datum in data {
			XCTAssertNotEqual(datum.description, "An unexpected error occurred, but the state does not make sense.")
			XCTAssert(!datum.description.isEmpty)
		}
	}

	func testErrorMessageDefault() {
		let dataDefault: [SftpChannelHandler.HandlerError] = [
			.unexpected(.header(.close(.init(id: 1, handle: "a")), 0), .awaitingHeader),
			//.unexpected(.header(.close(.init(id: 1, handle: "a")), 0), .processingMessage(SftpMessage(packet: .close(.init(id: 1, handle: "a")), dataLength: 0, shouldReadHandler: { _ in }))),

			//.unexpected(.body(ByteBuffer(bytes: [0x01])), .awaitingHeader),
			.unexpected(.body(ByteBuffer(bytes: [0x01])), .processingMessage(SftpMessage(packet: .close(.init(id: 1, handle: "a")), dataLength: 0, shouldReadHandler: { _ in }))),

			//.unexpected(.end, .awaitingHeader),
			.unexpected(.end, .processingMessage(SftpMessage(packet: .close(.init(id: 1, handle: "a")), dataLength: 0, shouldReadHandler: { _ in }))),
		]

		for datum in dataDefault {
			XCTAssertEqual(datum.description, "An unexpected error occurred, but the state does not make sense.")
			XCTAssert(!datum.description.isEmpty)
		}
	}

	func testRead() {
		let sftpChannelHandler = SftpChannelHandler()
		let readEventHitHandler = ReadEventHitHandler()
		let channel = EmbeddedChannel()
		XCTAssertNoThrow(try channel.pipeline.addHandlers([readEventHitHandler, sftpChannelHandler]).wait())
		XCTAssertEqual(readEventHitHandler.readHitCounter, 0)

		// State = awaitingHeader. Read should occur.
		channel.read()
		XCTAssertEqual(readEventHitHandler.readHitCounter, 1)

		// State = processingHeader and shouldRead = false
		let messagePart: MessagePart = .header(.dataReply(.init(id: 1)), 3)
		XCTAssertNoThrow(try channel.writeInbound(messagePart))
		channel.read()
		XCTAssertEqual(readEventHitHandler.readHitCounter, 1)

		// State = processingHeader and shouldRead = true
		let message = try? channel.readInbound(as: SftpMessage.self)
		XCTAssertNotNil(message)
		withExtendedLifetime(message!.data.sink(receiveCompletion: { _ in }, receiveValue: { _ in })) {
			channel.read()
			XCTAssertEqual(readEventHitHandler.readHitCounter, 2)
		}
	}

	static var allTests = [
		("testValid", testValid),
		("testValidNop", testValidNop),
		("testInvalidUnexpectedHeaderWhileProcessing", testInvalidUnexpectedHeaderWhileProcessing),
		("testInvalidUnexpectedBodyWhileAwaiting", testInvalidUnexpectedBodyWhileAwaiting),
		("testInvalidTooManyBodyBytes", testInvalidTooManyBodyBytes),
		("testInvalidUnexpectedEndWhileAwaiting", testInvalidUnexpectedEndWhileAwaiting),
		("testValidReplyHeader", testValidReplyHeader),
		("testValidReplyBody", testValidReplyBody),
		("testValidReplyBodyVariant", testValidReplyBodyVariant),
		("testErrorMessageCustom", testErrorMessageCustom),
		("testErrorMessageDefault", testErrorMessageDefault),
		("testRead", testRead),
	]
}
