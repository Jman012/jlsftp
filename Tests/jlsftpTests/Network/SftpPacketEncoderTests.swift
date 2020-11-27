import NIO
import NIOTestUtils
import XCTest
@testable import jlsftp

final class SftpPacketEncoderTests: XCTestCase {

	class MockSerializer: PacketSerializer {
		var serializeHandler: (Packet, inout ByteBuffer) -> PacketSerializationHandlerError? = { _, _ in
			return .wrongPacketInternalError
		}

		func deserialize(packetType _: jlsftp.SftpProtocol.PacketType, buffer _: inout ByteBuffer) -> Result<Packet, PacketDeserializationHandlerError> {
			XCTFail()
			return .failure(.needMoreData)
		}

		func serialize(packet: Packet, to buffer: inout ByteBuffer) -> PacketSerializationHandlerError? {
			return serializeHandler(packet, &buffer)
		}
	}

	func testValid() {
		let mockSerializer = MockSerializer()
		mockSerializer.serializeHandler = { _, buffer in
			buffer.writeBytes([0x05])
			return nil
		}
		let encoder = SftpPacketEncoder(serializer: mockSerializer)
		var buffer = ByteBuffer()

		XCTAssertNoThrow(try encoder.encode(data: .header(.initializeV3(InitializePacketV3(version: .v3, extensionData: []))), out: &buffer))
		XCTAssertEqual(buffer, ByteBuffer(bytes: [
			// Packet Length (UInt32 Network Order: 2)
			0x00, 0x00, 0x00, 0x02,
			// Packet Type (UInt8: SSH_FXP_INIT)
			0x01,
			// Mock Payload
			0x05,
		]))
	}

	func testInvalid() {
		let mockSerializer = MockSerializer()
		mockSerializer.serializeHandler = { _, buffer in
			buffer.writeBytes([0x05])
			return .wrongPacketInternalError
		}
		let encoder = SftpPacketEncoder(serializer: mockSerializer)
		var buffer = ByteBuffer()

		XCTAssertThrowsError(try encoder.encode(data: .header(.initializeV3(InitializePacketV3(version: .v3, extensionData: []))), out: &buffer)) { error in
			XCTAssert(error is SftpPacketEncoder.EncoderError)
			XCTAssertEqual(error as! SftpPacketEncoder.EncoderError, SftpPacketEncoder.EncoderError.failedToSerialize(message: "wrongPacketInternalError"))
		}
		// Ensure that any writes to the buffer were undone upon failure
		XCTAssertEqual(buffer, ByteBuffer(bytes: []))
	}

	func testNopSkip() {
		let mockSerializer = MockSerializer()
		mockSerializer.serializeHandler = { _, buffer in
			buffer.writeBytes([0x05])
			return nil
		}
		let encoder = SftpPacketEncoder(serializer: mockSerializer)
		var buffer = ByteBuffer()

		XCTAssertNoThrow(try encoder.encode(data: .header(.nopDebug(NOPDebugPacket(message: "test"))), out: &buffer))
		// Ensure that nothing was written
		XCTAssertEqual(buffer, ByteBuffer(bytes: []))
	}

	func testBody() {
		let mockSerializer = MockSerializer()
		mockSerializer.serializeHandler = { _, buffer in
			buffer.writeBytes([0x05])
			return nil
		}
		let encoder = SftpPacketEncoder(serializer: mockSerializer)
		var buffer = ByteBuffer()

		XCTAssertNoThrow(try encoder.encode(data: .body(ByteBuffer(bytes: [0x06])), out: &buffer))
		// Ensure that body was written plainly, without length/type prefix.
		XCTAssertEqual(buffer, ByteBuffer(bytes: [0x06]))
	}

	func testEnd() {
		let mockSerializer = MockSerializer()
		mockSerializer.serializeHandler = { _, buffer in
			buffer.writeBytes([0x05])
			return nil
		}
		let encoder = SftpPacketEncoder(serializer: mockSerializer)
		var buffer = ByteBuffer()

		XCTAssertNoThrow(try encoder.encode(data: .end, out: &buffer))
		// Ensure that nothing was written.
		XCTAssertEqual(buffer, ByteBuffer(bytes: []))
	}

	static var allTests = [
		("testValid", testValid),
		("testInvalid", testInvalid),
	]
}
