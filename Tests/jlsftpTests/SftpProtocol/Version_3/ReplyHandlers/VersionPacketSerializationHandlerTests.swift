import NIO
import XCTest
@testable import jlsftp

final class VersionPacketSerializationHandlerTests: XCTestCase {

	private func getHandler() -> jlsftp.SftpProtocol.Version_3.VersionPacketSerializationHandler {
		return jlsftp.SftpProtocol.Version_3.VersionPacketSerializationHandler()
	}

	// MARK: Test deserialize(buffer:)

	func testDeserializeValid() {
		let handler = getHandler()
		var buffer = ByteBuffer(bytes: [
			// Version (UInt32 Network Order: 3)
			0x00, 0x00, 0x00, 0x03,
			// Extensions (nil)
		])

		let result = handler.deserialize(from: &buffer)

		XCTAssertNoThrow(try result.get())
		let packet = try! result.get()
		guard case let .version(versionPacket) = packet else {
			XCTFail()
			return
		}

		XCTAssertEqual(0, buffer.readableBytes)
		XCTAssertEqual(jlsftp.SftpProtocol.SftpVersion.v3, versionPacket.version)
		XCTAssertEqual(0, versionPacket.extensionData.count)
	}

	func testDeserializeNotEnoughData() {
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
			let result = handler.deserialize(from: &buffer)

			XCTAssertEqual(.needMoreData, result.error)
		}
	}

	func testDeserializeInvalidVersion() {
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
			let result = handler.deserialize(from: &buffer)

			guard case .failure(.invalidData(reason: _)) = result else {
				XCTFail("Expected failure. Instead, got '\(result)'")
				return
			}
		}
	}

	func testDeserializeExtension() {
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

		let result = handler.deserialize(from: &buffer)

		XCTAssertNoThrow(try result.get())
		let packet = try! result.get()
		guard case let .version(versionPacket) = packet else {
			XCTFail()
			return
		}

		XCTAssertEqual(0, buffer.readableBytes)
		XCTAssertEqual(jlsftp.SftpProtocol.SftpVersion.v3, versionPacket.version)
		XCTAssertEqual(1, versionPacket.extensionData.count)
		XCTAssertEqual("A", versionPacket.extensionData.first!.name)
		XCTAssertEqual("B", versionPacket.extensionData.first!.data)
	}

	func testDeserializeExtensionMultiple() {
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

		let result = handler.deserialize(from: &buffer)

		XCTAssertNoThrow(try result.get())
		let packet = try! result.get()
		guard case let .version(versionPacket) = packet else {
			XCTFail()
			return
		}

		XCTAssertEqual(0, buffer.readableBytes)
		XCTAssertEqual(jlsftp.SftpProtocol.SftpVersion.v3, versionPacket.version)
		XCTAssertEqual(2, versionPacket.extensionData.count)
		XCTAssertEqual("A@a.com", versionPacket.extensionData.first!.name)
		XCTAssertEqual("B", versionPacket.extensionData.first!.data)
		XCTAssertEqual("B@b.com", versionPacket.extensionData[1].name)
		XCTAssertEqual("C", versionPacket.extensionData[1].data)
	}

	// MARK: Test serialize(packet:to:)

	func testSerializeValidEmpty() {
		let handler = getHandler()
		let packet = VersionPacket(version: .v3, extensionData: [])
		var buffer = ByteBuffer()

		XCTAssertNil(handler.serialize(packet: .version(packet), to: &buffer))
		XCTAssertEqual(buffer, ByteBuffer(bytes: [
			// Version (UInt32 Network Order: 3)
			0x00, 0x00, 0x00, 0x03,
		]))
	}

	func testSerializeValidItems() {
		let handler = getHandler()
		let packet = VersionPacket(version: .v3, extensionData: [ExtensionData(name: "a", data: "b")])
		var buffer = ByteBuffer()

		XCTAssertNil(handler.serialize(packet: .version(packet), to: &buffer))
		XCTAssertEqual(buffer, ByteBuffer(bytes: [
			// Version (UInt32 Network Order: 3)
			0x00, 0x00, 0x00, 0x03,
			// Extension Datum #1 Name string length (UInt32 Network Order: 1)
			0x00, 0x00, 0x00, 0x01,
			// Extension Datum #1 Name string data ("a")
			0x61,
			// Extension Datum #1 Data string length (UInt32 Network Order: 1)
			0x00, 0x00, 0x00, 0x01,
			// Extension Datum #1 Data string data ("b")
			0x62,
		]))
	}

	func testSerializeWrongPacket() {
		let handler = getHandler()
		let packet = InitializePacketV3(version: .v3, extensionData: [])
		var buffer = ByteBuffer()

		XCTAssertEqual(handler.serialize(packet: .initializeV3(packet), to: &buffer), .wrongPacketInternalError)
		XCTAssertEqual(ByteBuffer(), buffer)
	}

	static var allTests = [
		// Test deserialize(from:)
		("testDeserializeValid", testDeserializeValid),
		("testDeserializeNotEnoughData", testDeserializeNotEnoughData),
		("testDeserializeInvalidVersion", testDeserializeInvalidVersion),
		("testDeserializeExtension", testDeserializeExtension),
		("testDeserializeExtensionMultiple", testDeserializeExtensionMultiple),
		// Test serialize(packet:to:)
		("testSerializeValidEmpty", testSerializeValidEmpty),
		("testSerializeValidItems", testSerializeValidItems),
		("testSerializeWrongPacket", testSerializeWrongPacket),
	]
}
