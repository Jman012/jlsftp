import NIO
import XCTest
@testable import jlsftp

final class CreateSymbolicLinkSerializationHandlerTests: XCTestCase {

	private func getHandler() -> jlsftp.DataLayer.Version_3.CreateSymbolicLinkPacketSerializationHandler {
		return jlsftp.DataLayer.Version_3.CreateSymbolicLinkPacketSerializationHandler()
	}

	// MARK: Test deserialize(buffer:)

	func testDeserializeValid() {
		let handler = getHandler()
		var buffer = ByteBuffer(bytes: [
			// Id (UInt32 Network Order: 3)
			0x00, 0x00, 0x00, 0x03,
			// Link Path string length (UInt32 Network Order: 1)
			0x00, 0x00, 0x00, 0x01,
			// Link Path string data ("a")
			0x61,
			// Target Path string length (UInt32 Network Order: 1)
			0x00, 0x00, 0x00, 0x01,
			// Target Path string data ("b")
			0x62,
		])

		let result = handler.deserialize(from: &buffer)

		XCTAssertNoThrow(try result.get())
		let packet = try! result.get()
		guard case let .createSymbolicLink(createSymbolicLinkPacket) = packet else {
			XCTFail()
			return
		}

		XCTAssertEqual(0, buffer.readableBytes)
		XCTAssertEqual(3, createSymbolicLinkPacket.id)
		XCTAssertEqual("a", createSymbolicLinkPacket.linkPath)
		XCTAssertEqual("b", createSymbolicLinkPacket.targetPath)
	}

	func testDeserializeNotEnoughData() {
		let handler = getHandler()
		let buffers = [
			// No Id
			ByteBuffer(bytes: []),
			ByteBuffer(bytes: [0x03]),
			ByteBuffer(bytes: [0x00, 0x03]),
			ByteBuffer(bytes: [0x00, 0x00, 0x03]),
			// Id, no linkPath
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03]),
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03,
							   0x00]),
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03,
							   0x00, 0x00, 0x00, 0x01]),
			// Id, linkPath, no targetPath
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
		let packet = CreateSymbolicLinkPacket(id: 3, linkPath: "a", targetPath: "b")
		var buffer = ByteBuffer()

		XCTAssertTrue(handler.serialize(packet: .createSymbolicLink(packet), to: &buffer))
		XCTAssertEqual(buffer, ByteBuffer(bytes: [
			// Id (UInt32 Network Order: 3)
			0x00, 0x00, 0x00, 0x03,
			// Link Path string length (UInt32 Network Order: 1)
			0x00, 0x00, 0x00, 0x01,
			// Link Path string data ("a")
			0x61,
			// Target Path string length (UInt32 Network Order: 1)
			0x00, 0x00, 0x00, 0x01,
			// Target Path string data ("b")
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
