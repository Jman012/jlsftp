import NIO
import XCTest
@testable import jlsftp

final class SetStatusPacketSerializationHandlerTests: XCTestCase {

	private func getHandler() -> jlsftp.SftpProtocol.Version_3.SetStatusPacketSerializationHandler {
		return jlsftp.SftpProtocol.Version_3.SetStatusPacketSerializationHandler()
	}

	// MARK: Test deserialize(buffer:)

	func testDeserializeValid() {
		let handler = getHandler()
		var buffer = ByteBuffer(bytes: [
			// Id (UInt32 Network Order: 3)
			0x00, 0x00, 0x00, 0x03,
			// Path string length (UInt32 Network Order: 1)
			0x00, 0x00, 0x00, 0x01,
			// Path string data ("a")
			0x61,
			// File Attributes: Flags (minimal) (UInt32)
			0x00, 0x00, 0x00, 0x00,
		])

		let result = handler.deserialize(from: &buffer)

		XCTAssertNoThrow(try result.get())
		let packet = try! result.get()
		guard case let .setStatus(setStatusPacket) = packet else {
			XCTFail()
			return
		}

		XCTAssertEqual(0, buffer.readableBytes)
		XCTAssertEqual(3, setStatusPacket.id)
		XCTAssertEqual("a", setStatusPacket.path)
		XCTAssertEqual(nil, setStatusPacket.fileAttributes.sizeBytes)
		XCTAssertEqual(nil, setStatusPacket.fileAttributes.userId)
		XCTAssertEqual(nil, setStatusPacket.fileAttributes.groupId)
		XCTAssertEqual(nil, setStatusPacket.fileAttributes.permissions)
		XCTAssertEqual(nil, setStatusPacket.fileAttributes.accessDate)
		XCTAssertEqual(nil, setStatusPacket.fileAttributes.modifyDate)
		XCTAssertEqual([], setStatusPacket.fileAttributes.extensionData)
	}

	func testDeserializeNotEnoughData() {
		let handler = getHandler()
		let buffers = [
			// No Id
			ByteBuffer(bytes: []),
			ByteBuffer(bytes: [0x03]),
			ByteBuffer(bytes: [0x00, 0x03]),
			ByteBuffer(bytes: [0x00, 0x00, 0x03]),
			// Id, no path
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03]),
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03, 0x00]),
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03,
							   0x00, 0x00, 0x00, 0x01]),
			// Id, path, no file attributes
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03,
							   0x00, 0x00, 0x00, 0x01, 0x61]),
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03,
							   0x00, 0x00, 0x00, 0x01, 0x61,
							   0x00]),
		]

		for var buffer in buffers {
			let result = handler.deserialize(from: &buffer)

			XCTAssertEqual(.needMoreData, result.error)
		}
	}

	// MARK: Test serialize(packet:to:)

	func testSerializeValid() {
		let handler = getHandler()
		let packet = SetStatusPacket(id: 3, path: "a", fileAttributes: FileAttributes(sizeBytes: nil, userId: nil, groupId: nil, permissions: nil, accessDate: nil, modifyDate: nil, extensionData: []))
		var buffer = ByteBuffer()

		XCTAssertTrue(handler.serialize(packet: .setStatus(packet), to: &buffer))
		XCTAssertEqual(buffer, ByteBuffer(bytes: [
			// Id (UInt32 Network Order: 3)
			0x00, 0x00, 0x00, 0x03,
			// Path string length (UInt32 Network Order: 1)
			0x00, 0x00, 0x00, 0x01,
			// Path string data ("a")
			0x61,
			// File Attributes Flags (UInt32)
			0x00, 0x00, 0x00, 0x00,
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
