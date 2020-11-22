import NIO
import XCTest
@testable import jlsftp

final class RenamePacketSerializationHandlerTests: XCTestCase {

	private func getHandler() -> jlsftp.DataLayer.Version_3.RenamePacketSerializationHandler {
		return jlsftp.DataLayer.Version_3.RenamePacketSerializationHandler()
	}

	// MARK: Test deserialize(buffer:)

	func testDeserializeValid() {
		let handler = getHandler()
		var buffer = ByteBuffer(bytes: [
			// Id (UInt32 Network Order: 3)
			0x00, 0x00, 0x00, 0x03,
			// OldPath string length (UInt32 Network Order: 1)
			0x00, 0x00, 0x00, 0x01,
			// OldPath string data ("a")
			0x61,
			// NewPath string length (UInt32 Network Order: 1)
			0x00, 0x00, 0x00, 0x01,
			// NewPath string data ("b")
			0x62,
		])

		let result = handler.deserialize(from: &buffer)

		XCTAssertNoThrow(try result.get())
		let packet = try! result.get()
		guard case let .rename(renamePacket) = packet else {
			XCTFail()
			return
		}

		XCTAssertEqual(0, buffer.readableBytes)
		XCTAssertEqual(3, renamePacket.id)
		XCTAssertEqual("a", renamePacket.oldPath)
		XCTAssertEqual("b", renamePacket.newPath)
	}

	func testDeserializeNotEnoughData() {
		let handler = getHandler()
		let buffers = [
			// No Id
			ByteBuffer(bytes: []),
			ByteBuffer(bytes: [0x03]),
			ByteBuffer(bytes: [0x00, 0x03]),
			ByteBuffer(bytes: [0x00, 0x00, 0x03]),
			// Id, no oldPath
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03]),
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03,
							   0x00]),
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03,
							   0x00, 0x00, 0x00, 0x01]),
			// Id, oldPath, no newPath
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03,
							   0x00, 0x00, 0x00, 0x01, 0x61,
							   0x00]),
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03,
							   0x00, 0x00, 0x00, 0x01, 0x61,
							   0x00, 0x00, 0x00, 0x01]),
		]

		for var buffer in buffers {
			let result = handler.deserialize(from: &buffer)

			XCTAssertEqual(.needMoreData, result.error)
		}
	}

	// MARK: Test serialize(packet:to:)

	func testSerializeValid() {
		let handler = getHandler()
		let packet = RenamePacket(id: 3, oldPath: "a", newPath: "b")
		var buffer = ByteBuffer()

		XCTAssertTrue(handler.serialize(packet: .rename(packet), to: &buffer))
		XCTAssertEqual(buffer, ByteBuffer(bytes: [
			// Id (UInt32 Network Order: 3)
			0x00, 0x00, 0x00, 0x03,
			// Old Path string length (UInt32 Network Order: 1)
			0x00, 0x00, 0x00, 0x01,
			// Old Path string data ("a")
			0x61,
			// New Path string length (UInt32 Network Order: 1)
			0x00, 0x00, 0x00, 0x01,
			// New Path string data ("b")
			0x62,
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
