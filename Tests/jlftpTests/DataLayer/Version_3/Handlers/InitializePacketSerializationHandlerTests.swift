import XCTest
@testable import jlftp

final class InitializePacketSerializationHandlerTests: XCTestCase {

	private func getHandler() -> jlftp.DataLayer.Version_3.InitializePacketSerializationHandler {
		return jlftp.DataLayer.Version_3.InitializePacketSerializationHandler(sshProtocolSerialization: SSHProtocolSerializationDraft9())
	}

	func testValid() {
		let handler = getHandler()
		let dataPayload = Data([
			// Version (UInt32 Network Order: 3)
			0x00, 0x00, 0x00, 0x03,
			// Extensions (nil)
		])

		let result = handler.deserialize(fromPayload: dataPayload)

		guard case let .success(packet) = result else {
			XCTFail("Expected success. got '\(result)'")
			return
		}
		XCTAssert(packet is InitializePacket)
		let initPacket = packet as! InitializePacket

		XCTAssertEqual(jlftp.DataLayer.SftpVersion.v3, initPacket.version)
		XCTAssertEqual(0, initPacket.extensionData.count)
	}

	func testNotEnoughData() {
		let handler = getHandler()
		let dataPayloads = [
			Data([]),
			Data([0x03]),
			Data([0x03, 0x00]),
			Data([0x03, 0x00, 0x00]),
		]

		for dataPayload in dataPayloads {
			let result = handler.deserialize(fromPayload: dataPayload)

			guard case .failure(.payloadTooShort) = result else {
				XCTFail("Expected failure. got '\(result)'")
				return
			}
		}
	}

	func testInvalidVersion() {
		let handler = getHandler()
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
			let result = handler.deserialize(fromPayload: dataPayload)

			guard case .failure(.invalidDataPayload(reason: _)) = result else {
				XCTFail("Expected failure. got '\(result)'")
				return
			}
		}
	}

	func testExtension() {
		let handler = getHandler()
		let dataPayload = Data([
			// Version (UInt32 Network Byte Order: 3)
			0x00, 0x00, 0x00, 0x03,
			// Extension Name Length (UInt32 Network Byte Order: 1)
			0x00, 0x00, 0x00, 0x01,
			// Extension Name String ("A")
			65,
			// Extension Data Length (UInt32 Network Byte Order: 1)
			0x00, 0x00, 0x00, 0x01,
			// Extension Data String ("B")
			66,
		])

		let result = handler.deserialize(fromPayload: dataPayload)

		guard case let .success(packet) = result else {
			XCTFail("Expected success. got '\(result)'")
			return
		}
		XCTAssert(packet is InitializePacket)
		let initPacket = packet as! InitializePacket

		XCTAssertEqual(jlftp.DataLayer.SftpVersion.v3, initPacket.version)
		XCTAssertEqual(1, initPacket.extensionData.count)
		XCTAssertEqual("A", initPacket.extensionData.first!.name)
		XCTAssertEqual("B", initPacket.extensionData.first!.data)
	}

	func testExtensionMultiple() {
		let handler = getHandler()
		let dataPayload = Data([
			// Version (UInt32 Network Byte Order: 3)
			0x00, 0x00, 0x00, 0x03,
			// Extension Name Length (UInt32 Network Byte Order: 7)
			0x00, 0x00, 0x00, 0x07,
			// Extension Name String ("A@a.com")
			65, 64, 97, 46, 99, 111, 109,
			// Extension Data Length (UInt32 Network Byte Order: 1)
			0x00, 0x00, 0x00, 0x01,
			// Extension Data String ("B")
			66,
			// Extension Name Length (UInt32 Network Byte Order: 7)
			0x00, 0x00, 0x00, 0x07,
			// Extension Name String ("B@b.com")
			66, 64, 98, 46, 99, 111, 109,
			// Extension Data Length (UInt32 Network Byte Order: 1)
			0x00, 0x00, 0x00, 0x01,
			// Extension Data String ("C")
			67,
		])

		let result = handler.deserialize(fromPayload: dataPayload)

		guard case let .success(packet) = result else {
			XCTFail("Expected success. got '\(result)'")
			return
		}
		XCTAssert(packet is InitializePacket)
		let initPacket = packet as! InitializePacket

		XCTAssertEqual(jlftp.DataLayer.SftpVersion.v3, initPacket.version)
		XCTAssertEqual(2, initPacket.extensionData.count)
		XCTAssertEqual("A@a.com", initPacket.extensionData.first!.name)
		XCTAssertEqual("B", initPacket.extensionData.first!.data)
		XCTAssertEqual("B@b.com", initPacket.extensionData[1].name)
		XCTAssertEqual("C", initPacket.extensionData[1].data)
	}

	static var allTests = [
		("testValid", testValid),
		("testNotEnoughData", testNotEnoughData),
		("testInvalidVersion", testInvalidVersion),
		("testExtension", testExtension),
		("testExtensionMultiple", testExtensionMultiple),
	]
}