import NIO
import NIOTestUtils
import XCTest
@testable import jlsftp

final class SftpPacketDecoderTests: XCTestCase {

	/// Tests that normal packets are handled correctly.
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

	/// Tests that a length of 0 is handled correctly.
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

	/// Tests that malicious lengths with unknown types are handled correctly.
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

	/// Tests that unknown packet types with lenient payloads are passed on.
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

	/// Tests that deserialization errors are handled correctly.
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

	/// Tests that leftover bytes are handled correctly.
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

	func testValidBodyAllAtOnce() throws {
		let channel = EmbeddedChannel()
		_ = try channel.pipeline.addHandler(ByteToMessageHandler(SftpPacketDecoder(packetSerializer: BasePacketSerializer.createSerializer(fromSftpVersion: .v3)))).wait()

		var buffer = channel.allocator.buffer(capacity: 64)
		buffer.writeBytes([
			// Length (UInt32 Network Order: 1+17+16=34)
			0x00, 0x00, 0x00, 0x22,
			// Type (UInt8 SSH_FXP_WRITE=6)
			0x06,
			// Id (UInt32 Network Order: 2)
			0x00, 0x00, 0x00, 0x02,
			// Handle string length (UInt32 Network Order: 1)
			0x00, 0x00, 0x00, 0x01,
			// Handle string data ("a")
			0x61,
			// Offset (UInt64 Network Order: 10)
			0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0A,
			// Write Data (16 bytes)
			0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77,
			0x88, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF,
		])

		channel.pipeline.fireChannelRead(NIOAny(buffer))

		let messagePartHeader: MessagePart? = try channel.readInbound()
		XCTAssertEqual(messagePartHeader, .header(.write(WritePacket(id: 2, handle: "a", offset: 10))))
		XCTAssertNoThrow(try channel.throwIfErrorCaught())

		let messagePartBody: MessagePart? = try channel.readInbound()
		XCTAssertEqual(messagePartBody, .body(ByteBuffer(bytes: [
			0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77,
			0x88, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF,
		])))
		XCTAssertNoThrow(try channel.throwIfErrorCaught())
	}

	func testValidBodyIncremental() throws {
		let channel = EmbeddedChannel()
		_ = try channel.pipeline.addHandler(ByteToMessageHandler(SftpPacketDecoder(packetSerializer: BasePacketSerializer.createSerializer(fromSftpVersion: .v3)))).wait()

		var buffer = channel.allocator.buffer(capacity: 64)
		buffer.writeBytes([
			// Length (UInt32 Network Order: 1+17+16=34)
			0x00, 0x00, 0x00, 0x22,
			// Type (UInt8 SSH_FXP_WRITE=6)
			0x06,
			// Id (UInt32 Network Order: 2)
			0x00, 0x00, 0x00, 0x02,
			// Handle string length (UInt32 Network Order: 1)
			0x00, 0x00, 0x00, 0x01,
			// Handle string data ("a")
			0x61,
			// Offset (UInt64 Network Order: 10)
			0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0A,
		])

		channel.pipeline.fireChannelRead(NIOAny(buffer))
		let messagePartHeader: MessagePart? = try channel.readInbound()
		XCTAssertEqual(messagePartHeader, .header(.write(WritePacket(id: 2, handle: "a", offset: 10))))
		XCTAssertNoThrow(try channel.throwIfErrorCaught())

		buffer.moveWriterIndex(to: 0)
		buffer.writeBytes([
			0x00,
		])
		channel.pipeline.fireChannelRead(NIOAny(buffer))
		var messagePartBody: MessagePart? = try channel.readInbound()
		XCTAssertEqual(messagePartBody, .body(ByteBuffer(bytes: [
			0x00,
		])))

		buffer.moveWriterIndex(to: 0)
		buffer.writeBytes([
			0x11, 0x22,
		])
		channel.pipeline.fireChannelRead(NIOAny(buffer))
		messagePartBody = try channel.readInbound()
		XCTAssertEqual(messagePartBody, .body(ByteBuffer(bytes: [
			0x11, 0x22,
		])))

		buffer.moveWriterIndex(to: 0)
		buffer.writeBytes([
			0x33, 0x44,
		])
		channel.pipeline.fireChannelRead(NIOAny(buffer))
		buffer.moveWriterIndex(to: 0)
		buffer.writeBytes([
			0x55, 0x66,
		])
		channel.pipeline.fireChannelRead(NIOAny(buffer))
		messagePartBody = try channel.readInbound()
		XCTAssertEqual(messagePartBody, .body(ByteBuffer(bytes: [
			0x33, 0x44,
		])))
		messagePartBody = try channel.readInbound()
		XCTAssertEqual(messagePartBody, .body(ByteBuffer(bytes: [
			0x55, 0x66,
		])))
	}

	func testDecoderError() {
		XCTAssertEqual("Packet length is invalid (0). Treating as corrupted.", SftpPacketDecoder.DecoderError.emptyPacketPossiblyCorrupt.description)
		XCTAssertEqual("Unknown packet type (2) was sent with potentially malicious packet length (1)", SftpPacketDecoder.DecoderError.unknownPacketTypePossiblyMalicious(packetLength: 1, packetTypeInt: 2).description)
		XCTAssertEqual("Closing connection due to unexpected error reading network stream: test", SftpPacketDecoder.DecoderError.deserializationError(errorMessage: "test").description)
		XCTAssertEqual("Actual packet length did not match specific length (leftover bytes: 1)", SftpPacketDecoder.DecoderError.leftoverPacketBytes(mismatchLength: 1).description)
	}

	static var allTests = [
		("testValidPacketsNoBody", testValidPacketsNoBody),
		("testInvalidEmptyLength", testInvalidEmptyLength),
		("testInvalidTypeMaliciousLength", testInvalidTypeMaliciousLength),
		("testInvalidTypeRecoverableLength", testInvalidTypeRecoverableLength),
		("testInvalidDeserializationError", testInvalidDeserializationError),
		("testMismatchedPacketLengthForSerializedPacket", testMismatchedPacketLengthForSerializedPacket),
		("testValidBodyAllAtOnce", testValidBodyAllAtOnce),
		("testValidBodyIncremental", testValidBodyIncremental),
		("testDecoderError", testDecoderError),
	]
}
