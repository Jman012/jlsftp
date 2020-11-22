import NIO
import XCTest
@testable import jlsftp

final class MakeDirectoryPacketSerializationHandlerTests: XCTestCase {

	private func getHandler() -> jlsftp.SftpProtocol.Version_3.MakeDirectoryPacketSerializationHandler {
		return jlsftp.SftpProtocol.Version_3.MakeDirectoryPacketSerializationHandler()
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
		guard case let .makeDirectory(makeDirectoryPacket) = packet else {
			XCTFail()
			return
		}

		XCTAssertEqual(0, buffer.readableBytes)
		XCTAssertEqual(3, makeDirectoryPacket.id)
		XCTAssertEqual("a", makeDirectoryPacket.path)
		XCTAssertEqual(nil, makeDirectoryPacket.fileAttributes.sizeBytes)
		XCTAssertEqual(nil, makeDirectoryPacket.fileAttributes.userId)
		XCTAssertEqual(nil, makeDirectoryPacket.fileAttributes.groupId)
		XCTAssertEqual(nil, makeDirectoryPacket.fileAttributes.permissions)
		XCTAssertEqual(nil, makeDirectoryPacket.fileAttributes.accessDate)
		XCTAssertEqual(nil, makeDirectoryPacket.fileAttributes.modifyDate)
		XCTAssertEqual([], makeDirectoryPacket.fileAttributes.extensionData)
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
		let packet = MakeDirectoryPacket(id: 3, path: "a", fileAttributes: FileAttributes(sizeBytes: nil, userId: nil, groupId: nil, permissions: nil, accessDate: nil, modifyDate: nil, extensionData: []))
		var buffer = ByteBuffer()

		XCTAssertNil(handler.serialize(packet: .makeDirectory(packet), to: &buffer))
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
