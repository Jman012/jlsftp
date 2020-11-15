import NIO
import XCTest
@testable import jlsftp

final class InitializePacketSerializationHandlerTests: XCTestCase {

	private func getHandler() -> jlsftp.DataLayer.Version_3.InitializePacketSerializationHandler {
		return jlsftp.DataLayer.Version_3.InitializePacketSerializationHandler()
	}

	func testValid() {
		let handler = getHandler()
		var buffer = ByteBuffer(bytes: [
			// Version (UInt32 Network Order: 3)
			0x00, 0x00, 0x00, 0x03,
			// Extensions (nil)
		])

		let result = handler.deserialize(buffer: &buffer)

		XCTAssertNoThrow(try result.get())
		let packet = try! result.get()
		guard case let .initializeV3(initPacket) = packet else {
			XCTFail()
			return
		}

		XCTAssertEqual(0, buffer.readableBytes)
		XCTAssertEqual(jlsftp.DataLayer.SftpVersion.v3, initPacket.version)
		XCTAssertEqual(0, initPacket.extensionData.count)
	}

	func testNotEnoughData() {
		let handler = getHandler()
		let buffers = [
			// No version
			ByteBuffer(bytes: []),
			ByteBuffer(bytes: [0x03]),
			ByteBuffer(bytes: [0x00, 0x03]),
			ByteBuffer(bytes: [0x00, 0x00, 0x03]),
			// Version, no extension name
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03,
							   0x00]),
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03,
							   0x00, 0x00, 0x00, 0x01]),
			// Version, extension name, no extension data
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03,
							   0x00, 0x00, 0x00, 0x01, 0x61]),
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03,
							   0x00, 0x00, 0x00, 0x01, 0x61,
							   0x00]),
			ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x03,
							   0x00, 0x00, 0x00, 0x01, 0x61,
							   0x00, 0x00, 0x00, 0x01]),
		]

		for var buffer in buffers {
			let result = handler.deserialize(buffer: &buffer)

			XCTAssertEqual(.needMoreData, result.error)
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

		XCTAssertNoThrow(try result.get())
		let packet = try! result.get()
		guard case let .initializeV3(initPacket) = packet else {
			XCTFail()
			return
		}

		XCTAssertEqual(0, buffer.readableBytes)
		XCTAssertEqual(jlsftp.DataLayer.SftpVersion.v3, initPacket.version)
		XCTAssertEqual(1, initPacket.extensionData.count)
		XCTAssertEqual("A", initPacket.extensionData.first!.name)
		XCTAssertEqual("B", initPacket.extensionData.first!.data)
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

		XCTAssertNoThrow(try result.get())
		let packet = try! result.get()
		guard case let .initializeV3(initPacket) = packet else {
			XCTFail()
			return
		}

		XCTAssertEqual(0, buffer.readableBytes)
		XCTAssertEqual(jlsftp.DataLayer.SftpVersion.v3, initPacket.version)
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
