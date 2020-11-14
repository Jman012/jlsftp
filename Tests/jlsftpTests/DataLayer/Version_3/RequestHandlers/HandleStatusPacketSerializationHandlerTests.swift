import NIO
import XCTest
@testable import jlsftp

final class HandleStatusPacketSerializationHandlerTests: XCTestCase {

	private func getHandler() -> jlsftp.DataLayer.Version_3.HandleStatusPacketSerializationHandler {
		return jlsftp.DataLayer.Version_3.HandleStatusPacketSerializationHandler()
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
		])

		let result = handler.deserialize(buffer: &buffer)

		XCTAssertNoThrow(try result.get())
		let packet = try! result.get()
		XCTAssert(packet is HandleStatusPacket)
		let handleStatusPacket = packet as! HandleStatusPacket

		XCTAssertEqual(0, buffer.readableBytes)
		XCTAssertEqual(3, handleStatusPacket.id)
		XCTAssertEqual("a", handleStatusPacket.handle)
	}

	func testNotEnoughData() {
		let handler = getHandler()
		let buffers = [
			// No Id
			ByteBuffer(bytes: []),
			ByteBuffer(bytes: [0x03]),
			ByteBuffer(bytes: [0x00, 0x03]),
			ByteBuffer(bytes: [0x00, 0x00, 0x03]),
			// Id, no handle
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03]),
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03, 0x00]),
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
