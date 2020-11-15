import NIO
import XCTest
@testable import jlsftp

final class StatusPacketSerializationHandlerTests: XCTestCase {

	private func getHandler() -> jlsftp.DataLayer.Version_3.StatusPacketSerializationHandler {
		return jlsftp.DataLayer.Version_3.StatusPacketSerializationHandler()
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
		])

		let result = handler.deserialize(buffer: &buffer)

		XCTAssertNoThrow(try result.get())
		let packet = try! result.get()
		guard case let .status(statusPacket) = packet else {
			XCTFail()
			return
		}

		XCTAssertEqual(0, buffer.readableBytes)
		XCTAssertEqual(3, statusPacket.id)
		XCTAssertEqual("a", statusPacket.path)
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
