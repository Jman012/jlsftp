import NIO
import XCTest
@testable import jlsftp

final class NameReplyPacketSerializationHandlerTests: XCTestCase {

	private func getHandler() -> jlsftp.DataLayer.Version_3.NameReplyPacketSerializationHandler {
		return jlsftp.DataLayer.Version_3.NameReplyPacketSerializationHandler()
	}

	func testValid() {
		let handler = getHandler()
		var buffer = ByteBuffer(bytes: [
			// Version (UInt32 Network Order: 3)
			0x00, 0x00, 0x00, 0x03,
			// Extensions (nil)
		])

		let result = handler.deserialize(buffer: &buffer)

		guard case let .success(packet) = result else {
			XCTFail("Expected success. Instead, got '\(result)'")
			return
		}
		XCTAssert(packet is VersionPacket)
		let versionPacket = packet as! VersionPacket

		XCTAssertEqual(jlsftp.DataLayer.SftpVersion.v3, versionPacket.version)
		XCTAssertEqual(0, versionPacket.extensionData.count)
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

	func testInvalidVersion() {
		let handler = getHandler()
		let buffers = [
			ByteBuffer(bytes: [
				// Version (UInt32 Network Order: 0)
				0x00, 0x00, 0x00, 0x00,
			]),
			ByteBuffer(bytes: [
				// Version (UInt32 Network Order: 255)
				0x00, 0x00, 0x00, 0xFF,
			]),
		]

		for var buffer in buffers {
			let result = handler.deserialize(buffer: &buffer)

			guard case .failure(.invalidData(reason: _)) = result else {
				XCTFail("Expected failure. Instead, got '\(result)'")
				return
			}
		}
	}

	func testExtension() {
		let handler = getHandler()
		var buffer = ByteBuffer(bytes: [
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

		let result = handler.deserialize(buffer: &buffer)

		guard case let .success(packet) = result else {
			XCTFail("Expected success. Instead, got '\(result)'")
			return
		}
		XCTAssert(packet is VersionPacket)
		let versionPacket = packet as! VersionPacket

		XCTAssertEqual(jlsftp.DataLayer.SftpVersion.v3, versionPacket.version)
		XCTAssertEqual(1, versionPacket.extensionData.count)
		XCTAssertEqual("A", versionPacket.extensionData.first!.name)
		XCTAssertEqual("B", versionPacket.extensionData.first!.data)
	}

	func testExtensionMultiple() {
		let handler = getHandler()
		var buffer = ByteBuffer(bytes: [
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

		let result = handler.deserialize(buffer: &buffer)

		guard case let .success(packet) = result else {
			XCTFail("Expected success. Instead, got '\(result)'")
			return
		}
		XCTAssert(packet is VersionPacket)
		let versionPacket = packet as! VersionPacket

		XCTAssertEqual(jlsftp.DataLayer.SftpVersion.v3, versionPacket.version)
		XCTAssertEqual(2, versionPacket.extensionData.count)
		XCTAssertEqual("A@a.com", versionPacket.extensionData.first!.name)
		XCTAssertEqual("B", versionPacket.extensionData.first!.data)
		XCTAssertEqual("B@b.com", versionPacket.extensionData[1].name)
		XCTAssertEqual("C", versionPacket.extensionData[1].data)
	}

	static var allTests = [
		("testValid", testValid),
		("testNotEnoughData", testNotEnoughData),
		("testInvalidVersion", testInvalidVersion),
		("testExtension", testExtension),
		("testExtensionMultiple", testExtensionMultiple),
	]
}
