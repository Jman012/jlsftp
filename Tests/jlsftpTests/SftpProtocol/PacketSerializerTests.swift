import NIO
import XCTest
@testable import jlsftp

final class PacketSerializerTests: XCTestCase {

	func testCreateSerializer() {
		let v3 = BasePacketSerializer.createSerializer(fromSftpVersion: .v3)
		_ = BasePacketSerializer.createSerializer(fromSftpVersion: .v4)
		_ = BasePacketSerializer.createSerializer(fromSftpVersion: .v5)
		_ = BasePacketSerializer.createSerializer(fromSftpVersion: .v6)

		XCTAssert(v3 is jlsftp.SftpProtocol.Version_3.PacketSerializerV3)
		// Todo
	}

	func testDeserializeHandled() {
		let mockNotSupportedHandler = MockHandler()
		let mockHandler = MockHandler()
		var buffer = ByteBuffer()

		let serializer = BasePacketSerializer(
			handlers: [.initialize: mockHandler],
			unhandledTypeHandler: mockNotSupportedHandler)

		let result = serializer.deserialize(packetType: jlsftp.SftpProtocol.PacketType.initialize, buffer: &buffer)

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

		let result = serializer.deserialize(packetType: jlsftp.SftpProtocol.PacketType.version, buffer: &buffer)

		XCTAssertEqual(.needMoreData, result.error)
		XCTAssertFalse(mockHandler.isDeserializeCalled)
		XCTAssertTrue(mockNotSupportedHandler.isDeserializeCalled)
	}

	func testSerializeHandled() {
		let mockNotSupportedHandler = MockHandler()
		mockNotSupportedHandler.serializeReturn = nil
		let mockHandler = MockHandler()
		mockHandler.serializeReturn = nil
		var buffer = ByteBuffer()

		let serializer = BasePacketSerializer(
			handlers: [.initialize: mockHandler],
			unhandledTypeHandler: mockNotSupportedHandler)

		let result = serializer.serialize(packet: .initializeV3(InitializePacketV3(version: .v3, extensionData: [])), to: &buffer)

		XCTAssertEqual(result, nil)
		XCTAssertTrue(mockHandler.isSerializeCalled)
		XCTAssertFalse(mockNotSupportedHandler.isSerializeCalled)
	}

	func testSerializeUnhandled() {
		let mockNotSupportedHandler = MockHandler()
		mockNotSupportedHandler.serializeReturn = nil
		let mockHandler = MockHandler()
		mockHandler.serializeReturn = nil
		var buffer = ByteBuffer()

		let serializer = BasePacketSerializer(
			handlers: [.initialize: mockHandler],
			unhandledTypeHandler: mockNotSupportedHandler)

		let result = serializer.serialize(packet: .version(VersionPacket(version: .v3, extensionData: [])), to: &buffer)

		XCTAssertEqual(result, .missingPacketSerializationHandler)
		XCTAssertFalse(mockHandler.isSerializeCalled)
		XCTAssertFalse(mockNotSupportedHandler.isSerializeCalled)
	}

	func testSerializeNOP() {
		let mockNotSupportedHandler = MockHandler()
		mockNotSupportedHandler.serializeReturn = nil
		let mockHandler = MockHandler()
		mockHandler.serializeReturn = nil
		var buffer = ByteBuffer()

		let serializer = BasePacketSerializer(
			handlers: [.initialize: mockHandler],
			unhandledTypeHandler: mockNotSupportedHandler)

		let result = serializer.serialize(packet: .nopDebug(NOPDebugPacket(message: "test")), to: &buffer)

		XCTAssertEqual(result, .packetNotSerializable)
		XCTAssertFalse(mockHandler.isSerializeCalled)
		XCTAssertFalse(mockNotSupportedHandler.isSerializeCalled)
	}

	static var allTests = [
		("testCreateSerializer", testCreateSerializer),
		("testDeserializeHandled", testDeserializeHandled),
		("testDeserializeUnhandled", testDeserializeUnhandled),
		("testSerializeHandled", testSerializeHandled),
		("testSerializeUnhandled", testSerializeUnhandled),
	]
}
