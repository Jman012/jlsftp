import NIO
import XCTest
@testable import jlsftp

final class OpenPacketSerializationHandlerTests: XCTestCase {

	private func getHandler() -> jlsftp.DataLayer.Version_3.OpenPacketSerializationHandler {
		return jlsftp.DataLayer.Version_3.OpenPacketSerializationHandler()
	}

	func testValid() {
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

		let result = handler.deserialize(buffer: &buffer)

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

	func testNotEnoughData() {
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
			let result = handler.deserialize(buffer: &buffer)

			XCTAssertEqual(.needMoreData, result.error)
		}
	}

	static var allTests = [
		("testValid", testValid),
		("testNotEnoughData", testNotEnoughData),
	]
}
