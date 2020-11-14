import NIO
import XCTest
@testable import jlsftp

final class SetStatusPacketSerializationHandlerTests: XCTestCase {

	private func getHandler() -> jlsftp.DataLayer.Version_3.SetStatusPacketSerializationHandler {
		return jlsftp.DataLayer.Version_3.SetStatusPacketSerializationHandler()
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
		XCTAssert(packet is SetStatusPacket)
		let setStatusPacket = packet as! SetStatusPacket

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
