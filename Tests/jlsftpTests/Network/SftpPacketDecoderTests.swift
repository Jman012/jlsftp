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

	func testInvalidEmptyLength() throws {
		let channel = EmbeddedChannel()
		_ = try channel.pipeline.addHandler(ByteToMessageHandler(SftpPacketDecoder(packetSerializer: BasePacketSerializer.createSerializer(fromSftpVersion: .v3)))).wait()

		var buffer = channel.allocator.buffer(capacity: 64)
		buffer.writeBytes([
			// Length (UInt32 Network Order: 0)
			0x00, 0x00, 0x00, 0x00,
		])

		channel.pipeline.fireChannelRead(NIOAny(buffer))
		XCTAssertNoThrow(XCTAssertNil(try channel.readInbound()))
		XCTAssertThrowsError(try channel.throwIfErrorCaught()) { error in
			XCTAssert(error is SftpPacketDecoder.DecoderError)
			XCTAssertEqual(error as! SftpPacketDecoder.DecoderError, SftpPacketDecoder.DecoderError.emptyPacketPossiblyCorrupt)
		}
	}

	func testInvalidTypeMaliciousLength() throws {
		let channel = EmbeddedChannel()
		_ = try channel.pipeline.addHandler(ByteToMessageHandler(SftpPacketDecoder(packetSerializer: BasePacketSerializer.createSerializer(fromSftpVersion: .v3)))).wait()

		var buffer = channel.allocator.buffer(capacity: 64)
		buffer.writeBytes([
			// Length (UInt32 Network Order: 10_001)
			0x00, 0x00, 0x27, 0x11,
			// Packet Type (UInt8: 0)
			0x00,
		])

		channel.pipeline.fireChannelRead(NIOAny(buffer))
		XCTAssertNoThrow(XCTAssertNil(try channel.readInbound()))
		XCTAssertThrowsError(try channel.throwIfErrorCaught()) { error in
			XCTAssert(error is SftpPacketDecoder.DecoderError)
			XCTAssertEqual(error as! SftpPacketDecoder.DecoderError, SftpPacketDecoder.DecoderError.unknownPacketTypePossiblyMalicious(packetLength: 10001, packetTypeInt: 0))
		}
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
			.header(.nopDebug(NOPDebugPacket(message: "Unknown packet type '0'"))),
		]))

		// Invalid packet type with recoverable length (alternate)
		expectedInOuts.append((ByteBuffer(bytes: [
			// Length (UInt32 Network Order: 1)
			0x00, 0x00, 0x00, 0x01,
			// Packet Type (UInt8: 255)
			0xFF,
		]), [
			.header(.nopDebug(NOPDebugPacket(message: "Unknown packet type '255'"))),
		]))

		XCTAssertNoThrow(try ByteToMessageDecoderVerifier.verifyDecoder(inputOutputPairs: expectedInOuts,
																		decoderFactory: {
																			SftpPacketDecoder(packetSerializer: BasePacketSerializer.createSerializer(fromSftpVersion: .v3))
		}))
	}

	func testInvalidDeserializationError() throws {
		let channel = EmbeddedChannel()
		_ = try channel.pipeline.addHandler(ByteToMessageHandler(SftpPacketDecoder(packetSerializer: BasePacketSerializer.createSerializer(fromSftpVersion: .v3)))).wait()

		var buffer = channel.allocator.buffer(capacity: 64)
		buffer.writeBytes([
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
		])

		channel.pipeline.fireChannelRead(NIOAny(buffer))
		XCTAssertNoThrow(XCTAssertNil(try channel.readInbound()))
		XCTAssertThrowsError(try channel.throwIfErrorCaught()) { error in
			XCTAssert(error is SftpPacketDecoder.DecoderError)
			XCTAssertEqual(error as! SftpPacketDecoder.DecoderError, SftpPacketDecoder.DecoderError.deserializationError(errorMessage: "Failed to deserialize handle: Invalid UTF8 string data"))
		}
	}

	func testMismatchedPacketLengthForSerializedPacket() throws {
		let channel = EmbeddedChannel()
		_ = try channel.pipeline.addHandler(ByteToMessageHandler(SftpPacketDecoder(packetSerializer: BasePacketSerializer.createSerializer(fromSftpVersion: .v3)))).wait()

		var buffer = channel.allocator.buffer(capacity: 64)
		buffer.writeBytes([
			// Length (UInt32 Network Order: 1+9+1=11)
			0x00, 0x00, 0x00, 0x0B,
			// Type (UInt8 SSH_FXP_CLOSE=4)
			0x04,
			// Id (UInt32 Network Order: 2)
			0x00, 0x00, 0x00, 0x02,
			// Handle string length (UInt32 Network Order: 1)
			0x00, 0x00, 0x00, 0x01,
			// Handle string data ("a")
			0x61,
			// Leftover byte
			0xFF,
		])

		channel.pipeline.fireChannelRead(NIOAny(buffer))
		let messagePart: MessagePart? = try channel.readInbound()
		XCTAssertEqual(messagePart, .header(.close(ClosePacket(id: 2, handle: "a"))))
		XCTAssertThrowsError(try channel.throwIfErrorCaught()) { error in
			XCTAssert(error is SftpPacketDecoder.DecoderError)
			XCTAssertEqual(error as! SftpPacketDecoder.DecoderError, SftpPacketDecoder.DecoderError.leftoverPacketBytes(mismatchLength: 1))
		}
	}

//	func testValidBody

	static var allTests = [
		("testValidPacketsNoBody", testValidPacketsNoBody),
		("testInvalidEmptyLength", testInvalidEmptyLength),
		("testInvalidTypeMaliciousLength", testInvalidTypeMaliciousLength),
		("testInvalidTypeRecoverableLength", testInvalidTypeRecoverableLength),
		("testInvalidDeserializationError", testInvalidDeserializationError),
	]
}
