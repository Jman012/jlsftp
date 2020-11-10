import NIO
import XCTest
@testable import jlsftp

final class DataReplyPacketSerializationHandlerTests: XCTestCase {

	private func getHandler() -> jlsftp.DataLayer.Version_3.DataReplyPacketSerializationHandler {
		return jlsftp.DataLayer.Version_3.DataReplyPacketSerializationHandler()
	}

	func testValid() {
		let handler = getHandler()
		var buffer = ByteBuffer(bytes: [
			// Id (UInt32 Network Order: 3)
			0x00, 0x00, 0x00, 0x03,
		])

		let result = handler.deserialize(buffer: &buffer)

		guard case let .success(packet) = result else {
			XCTFail("Expected success. Instead, got '\(result)'")
			return
		}
		XCTAssert(packet is DataReplyPacket)
		let dataReplyPacket = packet as! DataReplyPacket

		XCTAssertEqual(3, dataReplyPacket.id)
	}

	func testNotEnoughData() {
		let handler = getHandler()
		let buffers = [
			ByteBuffer(bytes: []),
			ByteBuffer(bytes: [0x03]),
			ByteBuffer(bytes: [0x03, 0x00]),
			ByteBuffer(bytes: [0x03, 0x00, 0x00]),
		]

		for var buffer in buffers {
			let result = handler.deserialize(buffer: &buffer)

			guard case .failure(.needMoreData) = result else {
				XCTFail("Expected failure. Instead, got '\(result)'")
				return
			}
		}
	}

	static var allTests = [
		("testValid", testValid),
		("testNotEnoughData", testNotEnoughData),
	]
}
