import NIO
import XCTest
@testable import jlsftp

final class MakeDirectoryPacketSerializationHandlerTests: XCTestCase {

	private func getHandler() -> jlsftp.DataLayer.Version_3.MakeDirectoryPacketSerializationHandler {
		return jlsftp.DataLayer.Version_3.MakeDirectoryPacketSerializationHandler()
	}

	func testValid() {
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

		let result = handler.deserialize(buffer: &buffer)

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

	func testNotEnoughData() {
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
			let result = handler.deserialize(buffer: &buffer)

			XCTAssertEqual(.needMoreData, result.error)
		}
	}

	static var allTests = [
		("testValid", testValid),
		("testNotEnoughData", testNotEnoughData),
	]
}
