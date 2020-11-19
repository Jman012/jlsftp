import NIO
import NIOTestUtils
import XCTest
@testable import jlsftp

final class SftpPacketDecoderTests: XCTestCase {

	private class MockSerializer: PacketSerializer {

		typealias Handle = (jlsftp.DataLayer.PacketType, inout ByteBuffer) -> Result<Packet, PacketSerializationHandlerError>

		var isDeserializeCalled = false
		var deserializeHandle: Handle

		init(deserializeHandle: @escaping Handle) {
			self.deserializeHandle = deserializeHandle
		}

		func deserialize(packetType: jlsftp.DataLayer.PacketType, buffer: inout ByteBuffer) -> Result<Packet, PacketSerializationHandlerError> {
			isDeserializeCalled = true
			return deserializeHandle(packetType, &buffer)
		}
	}

//	func testRealSinglePacket() throws {
//		var buffer = ByteBuffer(bytes: [
//			// Length (UInt32 Network Order: 1+4=5)
//			0x00, 0x00, 0x00, 0x05,
//			// Type (UInt8 SSH_FXP_INIT=1)
//			0x01,
//			// Version (UInt32 Network Order: 3)
//			0x00, 0x00, 0x00, 0x03,
//		])
//
//		let decoder = SftpPacketDecoder(packetSerializer: jlsftp.DataLayer.Version_3.PacketSerializerV3())
//
//		let channel = EmbeddedChannel()
//		_ = try channel.pipeline.addHandler(ByteToMessageHandler(decoder)).wait()
//
//		try channel.writeInbound(buffer)
//
//		guard let actualOutput = try channel.readInbound(as: Packet.self) else {
//			XCTFail()
//			return
//		}
//	}

	func testValidPacketsNoBody() {
		var expectedInOuts: [(ByteBuffer, [MessagePart])] = []

		// Single init packet
		expectedInOuts.append((ByteBuffer(bytes: [
			// Length (UInt32 Network Order: 1+4=5)
			0x00, 0x00, 0x00, 0x05,
			// Type (UInt8 SSH_FXP_INIT=1)
			0x01,
			// Version (UInt32 Network Order: 3)
			0x00, 0x00, 0x00, 0x03,
		]), [
			.header(.initializeV3(InitializePacketV3(version: .v3, extensionData: []))),
		]))

		// Init then version packets (wouldn't happen but it's simpler to test)
		expectedInOuts.append((ByteBuffer(bytes: [
			// Init packet:
			// Length (UInt32 Network Order: 1+4=5)
			0x00, 0x00, 0x00, 0x05,
			// Type (UInt8 SSH_FXP_INIT=1)
			0x01,
			// Version (UInt32 Network Order: 3)
			0x00, 0x00, 0x00, 0x03,

			// Version packet:
			// Length (UInt32 Network Order: 1+4=5)
			0x00, 0x00, 0x00, 0x05,
			// Type (UInt8 SSH_FXP_VERSION=2)
			0x02,
			// Version (UInt32 Network Order: 4)
			0x00, 0x00, 0x00, 0x04,
		]), [
			.header(.initializeV3(InitializePacketV3(version: .v3, extensionData: []))),
			.header(.version(VersionPacket(version: .v4, extensionData: []))),
		]))

		XCTAssertNoThrow(try ByteToMessageDecoderVerifier.verifyDecoder(inputOutputPairs: expectedInOuts,
																		decoderFactory: {
																			SftpPacketDecoder(packetSerializer: BasePacketSerializer.createSerializer(fromSftpVersion: .v3))
																		}))
	}

	func testInvalidEmptyLength() {
		var expectedInOuts: [(ByteBuffer, [MessagePart])] = []

		// Empty length
		expectedInOuts.append((ByteBuffer(bytes: [
			// Length (UInt32 Network Order: 0)
			0x00, 0x00, 0x00, 0x00,
		]), [
			.header(.serializationError(SerializationErrorPacket(errorMessage: "Packet length is invalid (0). Treating as corrupted."))),
		]))

		XCTAssertNoThrow(try ByteToMessageDecoderVerifier.verifyDecoder(inputOutputPairs: expectedInOuts,
																		decoderFactory: {
																			SftpPacketDecoder(packetSerializer: BasePacketSerializer.createSerializer(fromSftpVersion: .v3))
																		}))
	}

	func testInvalidTypeMaliciousLength() {
		var expectedInOuts: [(ByteBuffer, [MessagePart])] = []

		// Invalid packet type with malicious length
		expectedInOuts.append((ByteBuffer(bytes: [
			// Length (UInt32 Network Order: 10_001)
			0x00, 0x00, 0x27, 0x11,
			// Packet Type (UInt8: 0)
			0x00,
		]), [
			.header(.serializationError(SerializationErrorPacket(errorMessage: "Unknown packet type (0) was sent with potentially malicious packet length (10001)")))
		]))

		XCTAssertNoThrow(try ByteToMessageDecoderVerifier.verifyDecoder(inputOutputPairs: expectedInOuts,
																		decoderFactory: {
																			SftpPacketDecoder(packetSerializer: BasePacketSerializer.createSerializer(fromSftpVersion: .v3))
																		}))
	}

	func testInvalidTypeRecoverableLength() {
		var expectedInOuts: [(ByteBuffer, [MessagePart])] = []

		// Invalid packet type with recoverable length
		expectedInOuts.append((ByteBuffer(bytes: [
			// Length (UInt32 Network Order: 17)
			0x00, 0x00, 0x00, 0x11,
			// Packet Type (UInt8: 0)
			0x00,
			// Some data (16 bytes)
			0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
			0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
		]), [
			.header(.serializationError(SerializationErrorPacket(errorMessage: "Unknown packet type (0)")))
		]))

		// Invalid packet type with recoverable length (alternate)
		expectedInOuts.append((ByteBuffer(bytes: [
			// Length (UInt32 Network Order: 1)
			0x00, 0x00, 0x00, 0x01,
			// Packet Type (UInt8: 255)
			0xFF,
		]), [
			.header(.serializationError(SerializationErrorPacket(errorMessage: "Unknown packet type (255)")))
		]))

		XCTAssertNoThrow(try ByteToMessageDecoderVerifier.verifyDecoder(inputOutputPairs: expectedInOuts,
																		decoderFactory: {
																			SftpPacketDecoder(packetSerializer: BasePacketSerializer.createSerializer(fromSftpVersion: .v3))
																		}))
	}

	func testInvalidDeserializationError() {
		var expectedInOuts: [(ByteBuffer, [MessagePart])] = []

		// Deserialization error (HandleReplyPacket with bad string)
		expectedInOuts.append((ByteBuffer(bytes: [
			// Length (UInt32 Network Order: 10)
			0x00, 0x00, 0x00, 0x0A,
			// Packet Type (UInt8: 102)
			0x66,
			// Id (UInt32 Network Order: 5)
			0x00, 0x00, 0x00, 0x05,
			// Handle string length (UInt32 Network Order: 1)
			0x00, 0x00, 0x00, 0x01,
			// Handle data (invalid UTF8)
			0xFF,
		]), [
			.header(.serializationError(SerializationErrorPacket(errorMessage: "Closing connection due to unexpected error reading network stream: Failed to deserialize handle: Invalid UTF8 string data")))
		]))

		XCTAssertNoThrow(try ByteToMessageDecoderVerifier.verifyDecoder(inputOutputPairs: expectedInOuts,
																		decoderFactory: {
																			SftpPacketDecoder(packetSerializer: BasePacketSerializer.createSerializer(fromSftpVersion: .v3))
																		}))
	}

	func testNeedsLength() throws {
		let mockSerializer = MockSerializer(deserializeHandle: { _, _ in
			return .success(.initializeV3(InitializePacketV3(version: .v3, extensionData: [])))
		})
		let decoder = SftpPacketDecoder(packetSerializer: mockSerializer)

		let channel = EmbeddedChannel()
		_ = try channel.pipeline.addHandler(ByteToMessageHandler(decoder)).wait()
		var buffer = channel.allocator.buffer(capacity: 1024)
	}

	static var allTests = [
		("testValidPacketsNoBody", testValidPacketsNoBody),
		("testInvalidEmptyLength", testInvalidEmptyLength),
		("testInvalidTypeMaliciousLength", testInvalidTypeMaliciousLength),
		("testInvalidTypeRecoverableLength", testInvalidTypeRecoverableLength),
		("testInvalidDeserializationError", testInvalidDeserializationError),
	]
}
