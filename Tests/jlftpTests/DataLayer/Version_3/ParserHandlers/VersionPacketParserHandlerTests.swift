import XCTest
@testable import jlftp

final class VersionPacketParserHandlerTests: XCTestCase {

	func testValid() {
		let handler = VersionPacketParserHandler()
		let dataPayload = Data([
			// Version (UInt32 Network Order: 3)
			0x00, 0x00, 0x00, 0x03,
			// Extensions (nil)
		])

		let result = handler.parse(fromPayload: dataPayload)

		guard case let .success(packet) = result else {
			XCTFail("Expected success. got '\(result)'")
			return
		}
		guard let initPacket = packet as? jlftp.Packets.InitializePacket else {
			XCTFail("Expected InitializePacket. Got '\(packet.self)'")
			return
		}

		XCTAssertEqual(jlftp.DataLayer.SftpVersion.v3, initPacket.version)
	}

	func testNotEnoughData() {
		let handler = VersionPacketParserHandler()
		let dataPayloads = [
			Data([]),
			Data([0x03]),
			Data([0x03, 0x00]),
			Data([0x03, 0x00, 0x00]),
		]

		for dataPayload in dataPayloads {
			let result = handler.parse(fromPayload: dataPayload)

			guard case .failure(.payloadTooShort) = result else {
				XCTFail("Expected failure. got '\(result)'")
				return
			}
		}
	}

	func testInvalidVersion() {
		let handler = VersionPacketParserHandler()
		let dataPayloads = [
			Data([
				// Version (UInt32 Network Order: 0)
				0x00, 0x00, 0x00, 0x00,
			]),
			Data([
				// Version (UInt32 Network Order: 255)
				0x00, 0x00, 0x00, 0xFF,
			]),
		]

		for dataPayload in dataPayloads {
			let result = handler.parse(fromPayload: dataPayload)

			guard case .failure(.invalidDataPayload(reason: _)) = result else {
				XCTFail("Expected failure. got '\(result)'")
				return
			}
		}
	}

	static var allTests = [
		("testValid", testValid),
		("testNotEnoughData", testNotEnoughData),
		("testInvalidVersion", testInvalidVersion),
	]
}
