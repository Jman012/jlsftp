import NIO
import XCTest
@testable import jlsftp

final class PacketSerializerTests: XCTestCase {

	class MockHandler: PacketSerializationHandler {
		public var isCalled = false

		func deserialize(buffer _: inout ByteBuffer) -> Result<Packet, PacketSerializationHandlerError> {
			isCalled = true
			return .failure(.needMoreData)
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
		XCTAssertTrue(mockHandler.isCalled)
		XCTAssertFalse(mockNotSupportedHandler.isCalled)
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
		XCTAssertFalse(mockHandler.isCalled)
		XCTAssertTrue(mockNotSupportedHandler.isCalled)
	}

	static var allTests = [
		("testCreateSerializer", testCreateSerializer),
		("testDeserializeHandled", testDeserializeHandled),
		("testDeserializeUnhandled", testDeserializeUnhandled),
	]
}
