import NIO
import XCTest
@testable import jlsftp

final class NameReplyPacketSerializationHandlerTests: XCTestCase {

	private func getHandler() -> jlsftp.DataLayer.Version_3.NameReplyPacketSerializationHandler {
		return jlsftp.DataLayer.Version_3.NameReplyPacketSerializationHandler()
	}

	func testValidMinimal() {
		let handler = getHandler()
		var buffer = ByteBuffer(bytes: [
			// Id (UInt32 Network Order: 3)
			0x00, 0x00, 0x00, 0x03,
			// Count (UInt32 Network Order: 0)
			0x00, 0x00, 0x00, 0x00,
		])

		let result = handler.deserialize(buffer: &buffer)

		guard case let .success(packet) = result else {
			XCTFail("Expected success. Instead, got '\(result)'")
			return
		}
		XCTAssert(packet is NameReplyPacket)
		let nameReplyPacket = packet as! NameReplyPacket

		XCTAssertEqual(3, nameReplyPacket.id)
		XCTAssertEqual(0, nameReplyPacket.names.count)
	}

	func testValidSingle() {
		let handler = getHandler()
		var buffer = ByteBuffer(bytes: [
			// Id (UInt32 Network Order: 3)
			0x00, 0x00, 0x00, 0x03,
			// Count (UInt32 Network Order: 1)
			0x00, 0x00, 0x00, 0x01,
			// Filename string length (UInt32 Network Order: 1)
			0x00, 0x00, 0x00, 0x01,
			// Filename string data ("a")
			0x61,
			// LongName string length (UInt32 Network Order: 1)
			0x00, 0x00, 0x00, 0x01,
			// LongName string data ("b")
			0x62,
			// File Attributes: Flags (minimal) (UInt32)
			0x00, 0x00, 0x00, 0x00,
		])

		let result = handler.deserialize(buffer: &buffer)

		guard case let .success(packet) = result else {
			XCTFail("Expected success. Instead, got '\(result)'")
			return
		}
		XCTAssert(packet is NameReplyPacket)
		let nameReplyPacket = packet as! NameReplyPacket

		XCTAssertEqual(3, nameReplyPacket.id)
		XCTAssertEqual(1, nameReplyPacket.names.count)
		let name = nameReplyPacket.names[0]
		XCTAssertEqual("a", name.filename)
		XCTAssertEqual("b", name.longName)
		let fileAttrs = name.fileAttributes
		XCTAssert(fileAttrs.sizeBytes == nil && fileAttrs.userId == nil
			&& fileAttrs.groupId == nil && fileAttrs.permissions == nil
			&& fileAttrs.accessDate == nil && fileAttrs.modifyDate == nil
			&& fileAttrs.extensionData.isEmpty)
	}

	func testNotEnoughData() {
		let handler = getHandler()
		let buffers = [
			// Partial id
			ByteBuffer(bytes: []),
			ByteBuffer(bytes: [0x03]),
			ByteBuffer(bytes: [0x00, 0x03]),
			ByteBuffer(bytes: [0x00, 0x00, 0x03]),
			// Id, no count
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03]),
			// Id, partial count
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03, 0x00]),
			// Id, non-zero count, no names
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
		("testValidMinimal", testValidMinimal),
		("testValidSingle", testValidSingle),
		("testNotEnoughData", testNotEnoughData),
	]
}
