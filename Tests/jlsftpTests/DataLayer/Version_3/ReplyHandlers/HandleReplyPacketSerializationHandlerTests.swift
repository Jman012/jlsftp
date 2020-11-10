import NIO
import XCTest
@testable import jlsftp

final class HandleReplyPacketSerializationHandlerTests: XCTestCase {

	private func getHandler() -> jlsftp.DataLayer.Version_3.HandleReplyPacketSerializationHandler {
		return jlsftp.DataLayer.Version_3.HandleReplyPacketSerializationHandler()
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

		guard case let .success(packet) = result else {
			XCTFail("Expected success. Instead, got '\(result)'")
			return
		}
		XCTAssert(packet is HandleReplyPacket)
		let handleReplyPacket = packet as! HandleReplyPacket

		XCTAssertEqual(3, handleReplyPacket.id)
		XCTAssertEqual("a", handleReplyPacket.handle)
	}

	func testNotEnoughData() {
		let handler = getHandler()
		let buffers = [
			// Partial Id
			ByteBuffer(bytes: []),
			ByteBuffer(bytes: [0x03]),
			ByteBuffer(bytes: [0x00, 0x03]),
			ByteBuffer(bytes: [0x00, 0x00, 0x03]),
			// Id, no handle
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03]),
			// Id, partial handle string length
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03, 0x00]),
			// Id, handle string length = 1, no data
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

	func testInvalidString() {
		let handler = getHandler()
		var buffer = ByteBuffer(bytes: [
			// Id (UInt32 Network Order: 3)
			0x00, 0x00, 0x00, 0x03,
			// Handle string length (UInt32 Network Order: 1)
			0x00, 0x00, 0x00, 0x01,
			// Handle string data (invalid UTF8)
			0xFF,
		])

		let result = handler.deserialize(buffer: &buffer)

		guard case .failure(.invalidData(reason: _)) = result else {
			XCTFail("Expected failure. Instead, got '\(result)'")
			return
		}
	}

	static var allTests = [
		("testValid", testValid),
		("testNotEnoughData", testNotEnoughData),
		("testInvalidVersion", testInvalidString),
	]
}
