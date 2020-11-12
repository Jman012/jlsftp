import NIO
import XCTest
@testable import jlsftp

final class StatusReplyPacketSerializationHandlerTests: XCTestCase {

	private func getHandler() -> jlsftp.DataLayer.Version_3.StatusReplyPacketSerializationHandler {
		return jlsftp.DataLayer.Version_3.StatusReplyPacketSerializationHandler()
	}

	func testValid() {
		let handler = getHandler()
		var buffer = ByteBuffer(bytes: [
			// Id (UInt32 Network Order: 3)
			0x00, 0x00, 0x00, 0x03,
			// Status Code (UInt32 Network Order: 1 EOF)
			0x00, 0x00, 0x00, 0x01,
			// Error Message string length (UInt32 Network Order: 1)
			0x00, 0x00, 0x00, 0x01,
			// Error Message data ("a")
			0x61,
			// Lang Tag string length (UInt32 Network Order: 1)
			0x00, 0x00, 0x00, 0x01,
			// Lang Tag data ("b")
			0x62,
		])

		let result = handler.deserialize(buffer: &buffer)

		XCTAssertNoThrow(try result.get())
		let packet = try! result.get()
		XCTAssert(packet is StatusReplyPacket)
		let statusReplyPacket = packet as! StatusReplyPacket

		XCTAssertEqual(0, buffer.readableBytes)
		XCTAssertEqual(3, statusReplyPacket.id)
		XCTAssertEqual(StatusCode.endOfFile, statusReplyPacket.statusCode)
		XCTAssertEqual("a", statusReplyPacket.errorMessage)
		XCTAssertEqual("b", statusReplyPacket.languageTag)
	}

	func testNotEnoughData() {
		let handler = getHandler()
		let buffers = [
			// Partial id
			ByteBuffer(bytes: []),
			ByteBuffer(bytes: [0x03]),
			ByteBuffer(bytes: [0x00, 0x03]),
			ByteBuffer(bytes: [0x00, 0x00, 0x03]),
			// Id, no status code
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03]),
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03, 0x00]),
			// Id, status code, no message
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03,
							   0x00, 0x00, 0x00, 0x00]),
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03,
							   0x00, 0x00, 0x00, 0x00,
							   0x00]),
			// Id, status code, message, no lang tag
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03,
							   0x00, 0x00, 0x00, 0x00,
							   0x00, 0x00, 0x00, 0x01, 0x61]),
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03,
							   0x00, 0x00, 0x00, 0x00,
							   0x00, 0x00, 0x00, 0x01, 0x61,
							   0x00]),
		]

		for var buffer in buffers {
			let result = handler.deserialize(buffer: &buffer)

			XCTAssertEqual(.needMoreData, result.error)
		}
	}

	func testInvalidStatusCode() {
		let handler = getHandler()
		var buffer = ByteBuffer(bytes: [
			// Id (UInt32 Network Order: 3)
			0x00, 0x00, 0x00, 0x03,
			// Status Code (UInt32 Network Order: 255 ??)
			0x00, 0x00, 0x00, 0xFF,
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
		("testInvalidStatusCode", testInvalidStatusCode),
	]
}
