import NIO
import XCTest
@testable import jlsftp

final class DataReplyPacketSerializationHandlerTests: XCTestCase {

	private func getHandler() -> jlsftp.SftpProtocol.Version_3.DataReplyPacketSerializationHandler {
		return jlsftp.SftpProtocol.Version_3.DataReplyPacketSerializationHandler()
	}

	// MARK: Test deserialize(buffer:)

	func testDeserializeValid() {
		let handler = getHandler()
		var buffer = ByteBuffer(bytes: [
			// Id (UInt32 Network Order: 3)
			0x00, 0x00, 0x00, 0x03,
			// Data Length (UInt32 Network Order: 2)
			0x00, 0x00, 0x00, 0x02,
		])

		let result = handler.deserialize(from: &buffer)

		XCTAssertNoThrow(try result.get())
		let packet = try? result.get()
		guard case let .dataReply(dataReplyPacket) = packet else {
			XCTFail()
			return
		}

		XCTAssertEqual(0, buffer.readableBytes)
		XCTAssertEqual(3, dataReplyPacket.id)
		XCTAssertEqual(2, dataReplyPacket.dataLength)
	}

	func testDeserializeNotEnoughData() {
		let handler = getHandler()
		let buffers = [
			ByteBuffer(bytes: []),
			ByteBuffer(bytes: [0x03]),
			ByteBuffer(bytes: [0x03, 0x00]),
			ByteBuffer(bytes: [0x03, 0x00, 0x00]),
			ByteBuffer(bytes: [0x03, 0x00, 0x00, 0x00]),
			ByteBuffer(bytes: [0x03, 0x00, 0x00, 0x00, 0x00]),
			ByteBuffer(bytes: [0x03, 0x00, 0x00, 0x00, 0x00, 0x00]),
			ByteBuffer(bytes: [0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]),
		]

		for var buffer in buffers {
			let result = handler.deserialize(from: &buffer)

			XCTAssertEqual(.needMoreData, result.error)
		}
	}

	// MARK: Test serialize(packet:to:)

	func testSerializeValid() {
		let handler = getHandler()
		let packet = DataReplyPacket(id: 3, dataLength: 4)
		var buffer = ByteBuffer()

		XCTAssertNil(handler.serialize(packet: .dataReply(packet), to: &buffer))
		XCTAssertEqual(buffer, ByteBuffer(bytes: [
			// Id (UInt32 Network Order: 3)
			0x00, 0x00, 0x00, 0x03,
			// Data Length (UInt32 Network Order: 4)
			0x00, 0x00, 0x00, 0x04,
		]))
	}

	func testSerializeWrongPacket() {
		let handler = getHandler()
		let packet = InitializePacketV3(version: .v3, extensionData: [])
		var buffer = ByteBuffer()

		XCTAssertEqual(handler.serialize(packet: .initializeV3(packet), to: &buffer), .wrongPacketInternalError)
		XCTAssertEqual(ByteBuffer(), buffer)
	}

	static var allTests = [
		// Test deserialize(from:)
		("testDeserializeValid", testDeserializeValid),
		("testDeserializeNotEnoughData", testDeserializeNotEnoughData),
		// Test serialize(packet:to:)
		("testSerializeValid", testSerializeValid),
		("testSerializeWrongPacket", testSerializeWrongPacket),
	]
}
