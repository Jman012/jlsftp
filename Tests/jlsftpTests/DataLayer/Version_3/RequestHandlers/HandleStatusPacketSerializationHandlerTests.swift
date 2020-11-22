import NIO
import XCTest
@testable import jlsftp

final class HandleStatusPacketSerializationHandlerTests: XCTestCase {

	private func getHandler() -> jlsftp.DataLayer.Version_3.HandleStatusPacketSerializationHandler {
		return jlsftp.DataLayer.Version_3.HandleStatusPacketSerializationHandler()
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
		guard case let .handleStatus(handleStatusPacket) = packet else {
			XCTFail()
			return
		}

		XCTAssertEqual(0, buffer.readableBytes)
		XCTAssertEqual(3, handleStatusPacket.id)
		XCTAssertEqual("a", handleStatusPacket.handle)
	}

	func testDeserializeNotEnoughData() {
		let handler = getHandler()
		let buffers = [
			// No Id
			ByteBuffer(bytes: []),
			ByteBuffer(bytes: [0x03]),
			ByteBuffer(bytes: [0x00, 0x03]),
			ByteBuffer(bytes: [0x00, 0x00, 0x03]),
			// Id, no handle
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03]),
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03, 0x00]),
		]

		for var buffer in buffers {
			let result = handler.deserialize(from: &buffer)

			XCTAssertEqual(.needMoreData, result.error)
		}
	}

	// MARK: Test serialize(packet:to:)

	func testSerializeValid() {
		let handler = getHandler()
		let packet = HandleStatusPacket(id: 3, handle: "a")
		var buffer = ByteBuffer()

		XCTAssertTrue(handler.serialize(packet: .handleStatus(packet), to: &buffer))
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
		// Test serialize(packet:to:)
		("testSerializeValid", testSerializeValid),
		("testSerializeWrongPacket", testSerializeWrongPacket),
	]
}
