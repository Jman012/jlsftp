import NIO
import XCTest
@testable import jlsftp

final class SetHandleStatusPacketSerializationHandlerTests: XCTestCase {

	private func getHandler() -> jlsftp.DataLayer.Version_3.SetHandleStatusPacketSerializationHandler {
		return jlsftp.DataLayer.Version_3.SetHandleStatusPacketSerializationHandler()
	}

	func testValid() {
		let handler = getHandler()
		var buffer = ByteBuffer(bytes: [
			// Id (UInt32 Network Order: 3)
			0x00, 0x00, 0x00, 0x03,
			// Handle string length (UInt32 Network Order: 1)
			0x00, 0x00, 0x00, 0x01,
			// Handle string data ("a")
			0x61,
			// File Attributes: Flags (minimal) (UInt32)
			0x00, 0x00, 0x00, 0x00,
		])

		let result = handler.deserialize(buffer: &buffer)

		XCTAssertNoThrow(try result.get())
		let packet = try! result.get()
		XCTAssert(packet is SetHandleStatusPacket)
		let setHandleStatusPacket = packet as! SetHandleStatusPacket

		XCTAssertEqual(0, buffer.readableBytes)
		XCTAssertEqual(3, setHandleStatusPacket.id)
		XCTAssertEqual("a", setHandleStatusPacket.handle)
		XCTAssertEqual(nil, setHandleStatusPacket.fileAttributes.sizeBytes)
		XCTAssertEqual(nil, setHandleStatusPacket.fileAttributes.userId)
		XCTAssertEqual(nil, setHandleStatusPacket.fileAttributes.groupId)
		XCTAssertEqual(nil, setHandleStatusPacket.fileAttributes.permissions)
		XCTAssertEqual(nil, setHandleStatusPacket.fileAttributes.accessDate)
		XCTAssertEqual(nil, setHandleStatusPacket.fileAttributes.modifyDate)
		XCTAssertEqual([], setHandleStatusPacket.fileAttributes.extensionData)
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