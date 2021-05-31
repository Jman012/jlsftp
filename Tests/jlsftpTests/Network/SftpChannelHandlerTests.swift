import XCTest
import Combine
import NIO
@testable import jlsftp

final class SftpChannelHandlerTests: XCTestCase {

	func testValid() {
		var lastHandledMessage: SftpMessage?
		let customServer = CustomSftpServer(
			handleMessageHandler: { message in lastHandledMessage = message })
		let sftpChannelHandler = SftpChannelHandler(server: customServer)

		let channel = EmbeddedChannel()
		try? channel.pipeline.addHandler(sftpChannelHandler).wait()

		var messagePart: MessagePart = .header(.initializeV3(InitializePacketV3(version: .v3, extensionData: [])), 0)
		channel.pipeline.fireChannelRead(NIOAny(messagePart))
		XCTAssertEqual(lastHandledMessage?.packet, .some(.initializeV3(InitializePacketV3(version: .v3, extensionData: []))))

		messagePart = .header(.dataReply(.init(id: 1)), 10)
		channel.pipeline.fireChannelRead(NIOAny(messagePart))
		XCTAssertEqual(lastHandledMessage?.packet, .some(.dataReply(DataReplyPacket(id: 1))))
		var didComplete = false
		var lastValue: ByteBuffer?

		withExtendedLifetime(lastHandledMessage!.data.sink(receiveCompletion: { _ in
			didComplete = true
		}, receiveValue: { buffer in
			lastValue = buffer
		})) {
			messagePart = .body(ByteBuffer(bytes: [0x01, 0x01, 0x01, 0x01, 0x01, 0x01]))
			channel.pipeline.fireChannelRead(NIOAny(messagePart))
			XCTAssertEqual(lastHandledMessage?.packet, .some(.dataReply(DataReplyPacket(id: 1))))
			XCTAssertEqual(didComplete, false)
			XCTAssertEqual(lastValue, ByteBuffer(bytes: [0x01, 0x01, 0x01, 0x01, 0x01, 0x01]))

			messagePart = .body(ByteBuffer(bytes: [0x01, 0x01, 0x01, 0x01]))
			channel.pipeline.fireChannelRead(NIOAny(messagePart))
			XCTAssertEqual(lastHandledMessage?.packet, .some(.dataReply(DataReplyPacket(id: 1))))
			XCTAssertEqual(didComplete, false)
			XCTAssertEqual(lastValue, ByteBuffer(bytes: [0x01, 0x01, 0x01, 0x01]))

			messagePart = .end
			channel.pipeline.fireChannelRead(NIOAny(messagePart))
			XCTAssertEqual(lastHandledMessage?.packet, .some(.dataReply(DataReplyPacket(id: 1))))
			XCTAssertEqual(didComplete, true)
			XCTAssertEqual(lastValue, ByteBuffer(bytes: [0x01, 0x01, 0x01, 0x01]))
		}
	}

	static var allTests = [
		("testValid", testValid),
	]
}
