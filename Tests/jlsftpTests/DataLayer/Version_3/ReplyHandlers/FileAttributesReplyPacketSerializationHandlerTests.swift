import NIO
import XCTest
@testable import jlsftp

final class FileAttributesReplyPacketSerializationHandlerTests: XCTestCase {

	private func getHandler() -> jlsftp.DataLayer.Version_3.FileAttributesReplyPacketSerializationHandler {
		return jlsftp.DataLayer.Version_3.FileAttributesReplyPacketSerializationHandler()
	}

	func testValid() {
		let handler = getHandler()
		var buffer = ByteBuffer(bytes: [
			// Id (UInt32 Network Order: 3)
			0x00, 0x00, 0x00, 0x03,
			// File Attributes: Flags (minimal) (UInt32)
			0x00, 0x00, 0x00, 0x00,
		])

		let result = handler.deserialize(buffer: &buffer)

		guard case let .success(packet) = result else {
			XCTFail("Expected success. Instead, got '\(result)'")
			return
		}
		XCTAssert(packet is FileAttributesReplyPacket)
		let fileAttrsReplyPacket = packet as! FileAttributesReplyPacket

		XCTAssertEqual(3, fileAttrsReplyPacket.id)
		XCTAssertEqual(nil, fileAttrsReplyPacket.fileAttributes.sizeBytes)
		XCTAssertEqual(nil, fileAttrsReplyPacket.fileAttributes.userId)
		XCTAssertEqual(nil, fileAttrsReplyPacket.fileAttributes.groupId)
		XCTAssertEqual(nil, fileAttrsReplyPacket.fileAttributes.permissions)
		XCTAssertEqual(nil, fileAttrsReplyPacket.fileAttributes.accessDate)
		XCTAssertEqual(nil, fileAttrsReplyPacket.fileAttributes.modifyDate)
		XCTAssertEqual([], fileAttrsReplyPacket.fileAttributes.extensionData)
	}

	func testNotEnoughData() {
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
			let result = handler.deserialize(buffer: &buffer)

			guard case .failure(.needMoreData) = result else {
				XCTFail("Expected failure. Instead, got '\(result)'")
				return
			}
		}
	}

	static var allTests = [
		("testValid", testValid),
		("testNotEnoughData", testNotEnoughData),
	]
}
