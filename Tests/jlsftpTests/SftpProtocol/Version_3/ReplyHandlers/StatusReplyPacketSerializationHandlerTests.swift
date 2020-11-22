import NIO
import XCTest
@testable import jlsftp

final class StatusReplyPacketSerializationHandlerTests: XCTestCase {

	private func getHandler() -> jlsftp.SftpProtocol.Version_3.StatusReplyPacketSerializationHandler {
		return jlsftp.SftpProtocol.Version_3.StatusReplyPacketSerializationHandler()
	}

	// MARK: Test deserialize(buffer:)

	func testDeserializeValid() {
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

		let result = handler.deserialize(from: &buffer)

		XCTAssertNoThrow(try result.get())
		let packet = try! result.get()
		guard case let .statusReply(statusReplyPacket) = packet else {
			XCTFail()
			return
		}

		XCTAssertEqual(0, buffer.readableBytes)
		XCTAssertEqual(3, statusReplyPacket.id)
		XCTAssertEqual(StatusCode.endOfFile, statusReplyPacket.statusCode)
		XCTAssertEqual("a", statusReplyPacket.errorMessage)
		XCTAssertEqual("b", statusReplyPacket.languageTag)
	}

	func testDeserializeNotEnoughData() {
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
			let result = handler.deserialize(from: &buffer)

			XCTAssertEqual(.needMoreData, result.error)
		}
	}

	func testDeserializeInvalidStatusCode() {
		let handler = getHandler()
		var buffer = ByteBuffer(bytes: [
			// Id (UInt32 Network Order: 3)
			0x00, 0x00, 0x00, 0x03,
			// Status Code (UInt32 Network Order: 255 ??)
			0x00, 0x00, 0x00, 0xFF,
		])

		let result = handler.deserialize(from: &buffer)

		guard case .failure(.invalidData(reason: _)) = result else {
			XCTFail("Expected failure. Instead, got '\(result)'")
			return
		}
	}

	// MARK: Test serialize(packet:to:)

	func testSerializeValid() {
		let handler = getHandler()
		let packet = StatusReplyPacket(id: 3, statusCode: .endOfFile, errorMessage: "a", languageTag: "b")
		var buffer = ByteBuffer()

		XCTAssertNil(handler.serialize(packet: .statusReply(packet), to: &buffer))
		XCTAssertEqual(buffer, ByteBuffer(bytes: [
			// Id (UInt32 Network Order: 3)
			0x00, 0x00, 0x00, 0x03,
			// Status Code (UInt32 Network Order: 1)
			0x00, 0x00, 0x00, 0x01,
			// Error Message string length (UInt32 Network Order: 1)
			0x00, 0x00, 0x00, 0x01,
			// Error Message string data ("a")
			0x61,
			// Language Tag string length (UInt32 Network Order: 1)
			0x00, 0x00, 0x00, 0x01,
			// Language Tag string data ("b")
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
		("testDeserializeInvalidStatusCode", testDeserializeInvalidStatusCode),
		// Test serialize(packet:to:)
		("testSerializeValid", testSerializeValid),
		("testSerializeWrongPacket", testSerializeWrongPacket),
	]
}
