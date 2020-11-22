import NIO
import XCTest
@testable import jlsftp

final class FileAttributesReplyPacketSerializationHandlerTests: XCTestCase {

	private func getHandler() -> jlsftp.DataLayer.Version_3.FileAttributesReplyPacketSerializationHandler {
		return jlsftp.DataLayer.Version_3.FileAttributesReplyPacketSerializationHandler()
	}

	// MARK: Test deserialize(buffer:)

	func testDeserializeValid() {
		let handler = getHandler()
		var buffer = ByteBuffer(bytes: [
			// Id (UInt32 Network Order: 3)
			0x00, 0x00, 0x00, 0x03,
			// File Attributes: Flags (minimal) (UInt32)
			0x00, 0x00, 0x00, 0x00,
		])

		let result = handler.deserialize(from: &buffer)

		XCTAssertNoThrow(try result.get())
		let packet = try! result.get()
		guard case let .attributesReply(fileAttrsReplyPacket) = packet else {
			XCTFail()
			return
		}

		XCTAssertEqual(0, buffer.readableBytes)
		XCTAssertEqual(3, fileAttrsReplyPacket.id)
		XCTAssertEqual(nil, fileAttrsReplyPacket.fileAttributes.sizeBytes)
		XCTAssertEqual(nil, fileAttrsReplyPacket.fileAttributes.userId)
		XCTAssertEqual(nil, fileAttrsReplyPacket.fileAttributes.groupId)
		XCTAssertEqual(nil, fileAttrsReplyPacket.fileAttributes.permissions)
		XCTAssertEqual(nil, fileAttrsReplyPacket.fileAttributes.accessDate)
		XCTAssertEqual(nil, fileAttrsReplyPacket.fileAttributes.modifyDate)
		XCTAssertEqual([], fileAttrsReplyPacket.fileAttributes.extensionData)
	}

	func testDeserializeNotEnoughData() {
		let handler = getHandler()
		let buffers = [
			// No Id
			ByteBuffer(bytes: []),
			ByteBuffer(bytes: [0x03]),
			ByteBuffer(bytes: [0x00, 0x03]),
			ByteBuffer(bytes: [0x00, 0x00, 0x03]),
			// Id, no file attributes
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03]),
			// Id, partial attributes
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03, 0x00]),
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03, 0x00, 0x00]),
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00]),
			// Enable one flag which expects more data
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00, 0x01]),
		]

		for var buffer in buffers {
			let result = handler.deserialize(from: &buffer)

			XCTAssertEqual(.needMoreData, result.error)
		}
	}

	// MARK: Test serialize(packet:to:)

	func testSerializeValid() {
		let handler = getHandler()
		let packet = FileAttributesReplyPacket(id: 3, fileAttributes: FileAttributes(sizeBytes: nil, userId: nil, groupId: nil, permissions: nil, accessDate: nil, modifyDate: nil, extensionData: []))
		var buffer = ByteBuffer()

		XCTAssertTrue(handler.serialize(packet: .attributesReply(packet), to: &buffer))
		XCTAssertEqual(buffer, ByteBuffer(bytes: [
			// Id (UInt32 Network Order: 3)
			0x00, 0x00, 0x00, 0x03,
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
