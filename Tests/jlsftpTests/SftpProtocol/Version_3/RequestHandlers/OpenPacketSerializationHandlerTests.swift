import NIO
import XCTest
@testable import jlsftp

final class OpenPacketSerializationHandlerTests: XCTestCase {

	private func getHandler() -> jlsftp.SftpProtocol.Version_3.OpenPacketSerializationHandler {
		return jlsftp.SftpProtocol.Version_3.OpenPacketSerializationHandler()
	}

	// MARK: Test deserialize(buffer:)

	func testDeserializeValid() {
		let handler = getHandler()
		var buffer = ByteBuffer(bytes: [
			// Id (UInt32 Network Order: 3)
			0x00, 0x00, 0x00, 0x03,
			// Filename string length (UInt32 Network Order: 1)
			0x00, 0x00, 0x00, 0x01,
			// Filename string data ("a")
			0x61,
			// Open Flags (UInt32 Network Order: 1 Read)
			0x00, 0x00, 0x00, 0x01,
			// File Attributes: Flags (minimal) (UInt32)
			0x00, 0x00, 0x00, 0x00,
		])

		let result = handler.deserialize(from: &buffer)

		XCTAssertNoThrow(try result.get())
		let packet = try! result.get()
		guard case let .open(openPacket) = packet else {
			XCTFail()
			return
		}

		XCTAssertEqual(0, buffer.readableBytes)
		XCTAssertEqual(3, openPacket.id)
		XCTAssertEqual("a", openPacket.filename)
		XCTAssertEqual(OpenFlags([.read]), openPacket.pflags)
		XCTAssertEqual(nil, openPacket.fileAttributes.sizeBytes)
		XCTAssertEqual(nil, openPacket.fileAttributes.userId)
		XCTAssertEqual(nil, openPacket.fileAttributes.groupId)
		XCTAssertEqual(nil, openPacket.fileAttributes.permissions)
		XCTAssertEqual(nil, openPacket.fileAttributes.accessDate)
		XCTAssertEqual(nil, openPacket.fileAttributes.modifyDate)
		XCTAssertEqual([], openPacket.fileAttributes.extensionData)
	}

	func testDeserializeNotEnoughData() {
		let handler = getHandler()
		let buffers = [
			// No Id
			ByteBuffer(bytes: []),
			ByteBuffer(bytes: [0x03]),
			ByteBuffer(bytes: [0x00, 0x03]),
			ByteBuffer(bytes: [0x00, 0x00, 0x03]),
			// Id, no filename
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03]),
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03, 0x00]),
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03,
							   0x00, 0x00, 0x00, 0x01]),
			// Id, filename, no flags
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03,
							   0x00, 0x00, 0x00, 0x00]),
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03,
							   0x00, 0x00, 0x00, 0x00,
							   0x00]),
			// Id, filename, flags, no attrs
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03,
							   0x00, 0x00, 0x00, 0x00,
							   0x00, 0x00, 0x00, 0x00]),
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03,
							   0x00, 0x00, 0x00, 0x00,
							   0x00, 0x00, 0x00, 0x00,
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
		let packet = OpenPacket(id: 3, filename: "a", pflags: OpenFlags([.read]), fileAttributes: .empty)
		var buffer = ByteBuffer()

		XCTAssertNil(handler.serialize(packet: .open(packet), to: &buffer))
		XCTAssertEqual(buffer, ByteBuffer(bytes: [
			// Id (UInt32 Network Order: 3)
			0x00, 0x00, 0x00, 0x03,
			// Filename string length (UInt32 Network Order: 1)
			0x00, 0x00, 0x00, 0x01,
			// Filename string data ("a")
			0x61,
			// Open Flags (UInt32 Network Order: 1 Read)
			0x00, 0x00, 0x00, 0x01,
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
