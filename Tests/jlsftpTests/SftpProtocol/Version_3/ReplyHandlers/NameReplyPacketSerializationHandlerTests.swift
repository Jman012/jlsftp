import NIO
import XCTest
@testable import jlsftp

final class NameReplyPacketSerializationHandlerTests: XCTestCase {

	private func getHandler() -> jlsftp.SftpProtocol.Version_3.NameReplyPacketSerializationHandler {
		return jlsftp.SftpProtocol.Version_3.NameReplyPacketSerializationHandler()
	}

	// MARK: Test deserialize(buffer:)

	func testDeserializeValidMinimal() {
		let handler = getHandler()
		var buffer = ByteBuffer(bytes: [
			// Id (UInt32 Network Order: 3)
			0x00, 0x00, 0x00, 0x03,
			// Count (UInt32 Network Order: 0)
			0x00, 0x00, 0x00, 0x00,
		])

		let result = handler.deserialize(from: &buffer)

		XCTAssertNoThrow(try result.get())
		let packet = try! result.get()
		guard case let .nameReply(nameReplyPacket) = packet else {
			XCTFail()
			return
		}

		XCTAssertEqual(0, buffer.readableBytes)
		XCTAssertEqual(3, nameReplyPacket.id)
		XCTAssertEqual(0, nameReplyPacket.names.count)
	}

	func testDeserializeValidSingle() {
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

		let result = handler.deserialize(from: &buffer)

		XCTAssertNoThrow(try result.get())
		let packet = try! result.get()
		guard case let .nameReply(nameReplyPacket) = packet else {
			XCTFail()
			return
		}

		XCTAssertEqual(0, buffer.readableBytes)
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

	func testDeserializeNotEnoughData() {
		let handler = getHandler()
		let buffers = [
			// Partial id
			ByteBuffer(bytes: []),
			ByteBuffer(bytes: [0x03]),
			ByteBuffer(bytes: [0x00, 0x03]),
			ByteBuffer(bytes: [0x00, 0x00, 0x03]),
			// Id, partial count
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03]),
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03,
							   0x00]),
			// Id, non-zero count, no filename
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03,
							   0x00, 0x00, 0x00, 0x01]),
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03,
							   0x00, 0x00, 0x00, 0x01,
							   0x00]),
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03,
							   0x00, 0x00, 0x00, 0x01,
							   0x00, 0x00, 0x00, 0x01]),
			// Id, non-zero count, filename, no longName
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03,
							   0x00, 0x00, 0x00, 0x01,
							   0x00, 0x00, 0x00, 0x01, 0x61]),
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03,
							   0x00, 0x00, 0x00, 0x01,
							   0x00, 0x00, 0x00, 0x01, 0x61,
							   0x00]),
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03,
							   0x00, 0x00, 0x00, 0x01,
							   0x00, 0x00, 0x00, 0x01, 0x61,
							   0x00, 0x00, 0x00, 0x01]),
			// Id, non-zero count, filename, longName, no fileAttrs
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03,
							   0x00, 0x00, 0x00, 0x01,
							   0x00, 0x00, 0x00, 0x01, 0x61,
							   0x00, 0x00, 0x00, 0x01, 0x62]),
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03,
							   0x00, 0x00, 0x00, 0x01,
							   0x00, 0x00, 0x00, 0x01, 0x61,
							   0x00, 0x00, 0x00, 0x01, 0x62, 0x00]),
		]

		for var buffer in buffers {
			let result = handler.deserialize(from: &buffer)

			XCTAssertEqual(.needMoreData, result.error)
		}
	}

	// MARK: Test serialize(packet:to:)

	func testSerializeValidEmpty() {
		let handler = getHandler()
		let packet = NameReplyPacket(id: 3, names: [])
		var buffer = ByteBuffer()

		XCTAssertNil(handler.serialize(packet: .nameReply(packet), to: &buffer))
		XCTAssertEqual(buffer, ByteBuffer(bytes: [
			// Id (UInt32 Network Order: 3)
			0x00, 0x00, 0x00, 0x03,
			// Names count (UInt32 Network Order: 0)
			0x00, 0x00, 0x00, 0x00,
		]))
	}

	func testSerializeValidItems() {
		let handler = getHandler()
		let packet = NameReplyPacket(id: 3, names: [
			NameReplyPacket.Name(
				filename: "a",
				longName: "b",
				fileAttributes: .empty),
		])
		var buffer = ByteBuffer()

		XCTAssertNil(handler.serialize(packet: .nameReply(packet), to: &buffer))
		XCTAssertEqual(buffer, ByteBuffer(bytes: [
			// Id (UInt32 Network Order: 3)
			0x00, 0x00, 0x00, 0x03,
			// Names count (UInt32 Network Order: 1)
			0x00, 0x00, 0x00, 0x01,
			// Filename string length (UInt32 Network Order: 1)
			0x00, 0x00, 0x00, 0x01,
			// Filename string data ("a")
			0x61,
			// Long Name string length (UInt32 Network Order: 1)
			0x00, 0x00, 0x00, 0x01,
			// Long Name string data ("b")
			0x62,
			// File Attributes Flags
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
		("testDeserializeValidMinimal", testDeserializeValidMinimal),
		("testDeserializeValidSingle", testDeserializeValidSingle),
		("testDeserializeNotEnoughData", testDeserializeNotEnoughData),
		// Test serialize(packet:to:)
		("testSerializeValid", testSerializeValidEmpty),
		("testSerializeValidItems", testSerializeValidItems),
		("testSerializeWrongPacket", testSerializeWrongPacket),
	]
}
