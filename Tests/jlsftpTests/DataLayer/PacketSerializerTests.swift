import NIO
import XCTest
@testable import jlsftp

final class PacketSerializerTests: XCTestCase {

	class MockHandler: PacketSerializationHandler {
		var isDeserializeCalled = false
		var isSerializeCalled = false

		func deserialize(buffer _: inout ByteBuffer) -> Result<Packet, PacketSerializationHandlerError> {
			isDeserializeCalled = true
			return .failure(.needMoreData)
		}

		func serialize(packet _: Packet, to _: inout ByteBuffer) -> Bool {
			isSerializeCalled = true
			return false
		}
	}

	func testCreateSerializer() {
		let v3 = BasePacketSerializer.createSerializer(fromSftpVersion: .v3)
		_ = BasePacketSerializer.createSerializer(fromSftpVersion: .v4)
		_ = BasePacketSerializer.createSerializer(fromSftpVersion: .v5)
		_ = BasePacketSerializer.createSerializer(fromSftpVersion: .v6)

		XCTAssert(v3 is jlsftp.DataLayer.Version_3.PacketSerializerV3)
		// Todo
	}

	func testDeserializeHandled() {
		let mockNotSupportedHandler = MockHandler()
		let mockHandler = MockHandler()
		var buffer = ByteBuffer()

		let serializer = BasePacketSerializer(
			handlers: [.initialize: mockHandler],
			unhandledTypeHandler: mockNotSupportedHandler)

		let result = serializer.deserialize(packetType: jlsftp.DataLayer.PacketType.initialize, buffer: &buffer)

		XCTAssertEqual(.needMoreData, result.error)
		XCTAssertTrue(mockHandler.isDeserializeCalled)
		XCTAssertFalse(mockNotSupportedHandler.isDeserializeCalled)
	}

	func testDeserializeUnhandled() {
		let mockNotSupportedHandler = MockHandler()
		let mockHandler = MockHandler()
		var buffer = ByteBuffer()

		let serializer = BasePacketSerializer(
			handlers: [.initialize: mockHandler],
			unhandledTypeHandler: mockNotSupportedHandler)

		let result = serializer.deserialize(packetType: jlsftp.DataLayer.PacketType.version, buffer: &buffer)

		XCTAssertEqual(.needMoreData, result.error)
		XCTAssertFalse(mockHandler.isDeserializeCalled)
		XCTAssertTrue(mockNotSupportedHandler.isDeserializeCalled)
	}

	static var allTests = [
		("testCreateSerializer", testCreateSerializer),
		("testDeserializeHandled", testDeserializeHandled),
		("testDeserializeUnhandled", testDeserializeUnhandled),
	]
}
