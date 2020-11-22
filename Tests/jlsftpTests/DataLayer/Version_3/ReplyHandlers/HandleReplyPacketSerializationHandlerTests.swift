import NIO
import XCTest
@testable import jlsftp

final class HandleReplyPacketSerializationHandlerTests: XCTestCase {

	private func getHandler() -> jlsftp.DataLayer.Version_3.HandleReplyPacketSerializationHandler {
		return jlsftp.DataLayer.Version_3.HandleReplyPacketSerializationHandler()
	}

	// MARK: Test deserialize(buffer:)

	func testDeserializeValid() {
		let handler = getHandler()
		var buffer = ByteBuffer(bytes: [
			// Id (UInt32 Network Order: 3)
			0x00, 0x00, 0x00, 0x03,
			// Handle string length (UInt32 Network Order: 1)
			0x00, 0x00, 0x00, 0x01,
			// Handle string data ("a")
			0x61,
		])

		let result = handler.deserialize(from: &buffer)

		XCTAssertNoThrow(try result.get())
		let packet = try! result.get()
		guard case let .handleReply(handleReplyPacket) = packet else {
			XCTFail()
			return
		}

		XCTAssertEqual(0, buffer.readableBytes)
		XCTAssertEqual(3, handleReplyPacket.id)
		XCTAssertEqual("a", handleReplyPacket.handle)
	}

	func testDeserializeNotEnoughData() {
		let handler = getHandler()
		let buffers = [
			// Partial Id
			ByteBuffer(bytes: []),
			ByteBuffer(bytes: [0x03]),
			ByteBuffer(bytes: [0x00, 0x03]),
			ByteBuffer(bytes: [0x00, 0x00, 0x03]),
			// Id, no handle
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03]),
			// Id, partial handle string length
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03, 0x00]),
			// Id, handle string length = 1, no data
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00, 0x01]),
		]

		for var buffer in buffers {
			let result = handler.deserialize(from: &buffer)
			XCTAssertEqual(.needMoreData, result.error)
		}
	}

	func testDeserializeInvalidString() {
		let handler = getHandler()
		var buffer = ByteBuffer(bytes: [
			// Id (UInt32 Network Order: 3)
			0x00, 0x00, 0x00, 0x03,
			// Handle string length (UInt32 Network Order: 1)
			0x00, 0x00, 0x00, 0x01,
			// Handle string data (invalid UTF8)
			0xFF,
		])

		let result = handler.deserialize(from: &buffer)

		guard case .failure(.invalidData(reason: _)) = result else {
			XCTFail("Expected failure. Instead, got '\(result)'")
			return
		}
	}

	// MARK: Test serialize(packet:to:)

	func testSerializeValid() {
		let handler = getHandler()
		let packet = HandleReplyPacket(id: 3, handle: "a")
		var buffer = ByteBuffer()

		XCTAssertTrue(handler.serialize(packet: .handleReply(packet), to: &buffer))
		XCTAssertEqual(buffer, ByteBuffer(bytes: [
			// Id (UInt32 Network Order: 3)
			0x00, 0x00, 0x00, 0x03,
			// Handle string length (UInt32 Network Order: 1)
			0x00, 0x00, 0x00, 0x01,
			// Handle string data ("a")
			0x61,
		]))
	}

	func testSerializeWrongPacket() {
		let handler = getHandler()
		let packet = InitializePacketV3(version: .v3, extensionData: [])
		var buffer = ByteBuffer()

		XCTAssertFalse(handler.serialize(packet: .initializeV3(packet), to: &buffer))
		XCTAssertEqual(ByteBuffer(), buffer)
	}

	static var allTests = [
		// Test deserialize(from:)
		("testDeserializeValid", testDeserializeValid),
		("testDeserializeNotEnoughData", testDeserializeNotEnoughData),
		("testDeserializeInvalidVersion", testDeserializeInvalidString),
		// Test serialize(packet:to:)
		("testSerializeValid", testSerializeValid),
		("testSerializeWrongPacket", testSerializeWrongPacket),
	]
}
