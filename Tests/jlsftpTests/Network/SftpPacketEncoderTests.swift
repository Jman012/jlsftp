import NIO
import NIOTestUtils
import XCTest
@testable import jlsftp

final class SftpPacketEncoderTests: XCTestCase {

	func testValid() {
		let mockSerializer = MockSerializer()
		mockSerializer.serializeHandler = { _, buffer in
			buffer.writeBytes([0x05])
			return nil
		}
		let encoder = SftpPacketEncoder(serializer: mockSerializer, allocator: ByteBufferAllocator())
		var buffer = ByteBuffer()

		XCTAssertNoThrow(try encoder.encode(data: .header(.initializeV3(InitializePacketV3(version: .v3, extensionData: [])), 0), out: &buffer))
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
		let encoder = SftpPacketEncoder(serializer: mockSerializer, allocator: ByteBufferAllocator())
		var buffer = ByteBuffer()

		XCTAssertThrowsError(try encoder.encode(data: .header(.initializeV3(InitializePacketV3(version: .v3, extensionData: [])), 0), out: &buffer)) { error in
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
		let encoder = SftpPacketEncoder(serializer: mockSerializer, allocator: ByteBufferAllocator())
		var buffer = ByteBuffer()

		XCTAssertNoThrow(try encoder.encode(data: .header(.nopDebug(NOPDebugPacket(message: "test")), 0), out: &buffer))
		// Ensure that nothing was written
		XCTAssertEqual(buffer, ByteBuffer(bytes: []))
	}

	func testBody() {
		let mockSerializer = MockSerializer()
		mockSerializer.serializeHandler = { _, buffer in
			buffer.writeBytes([0x05])
			return nil
		}
		let encoder = SftpPacketEncoder(serializer: mockSerializer, allocator: ByteBufferAllocator())
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
		let encoder = SftpPacketEncoder(serializer: mockSerializer, allocator: ByteBufferAllocator())
		var buffer = ByteBuffer()

		XCTAssertNoThrow(try encoder.encode(data: .end, out: &buffer))
		// Ensure that nothing was written.
		XCTAssertEqual(buffer, ByteBuffer(bytes: []))
	}

	func testCompletePacket() {
		let mockSerializer = MockSerializer()
		mockSerializer.serializeHandler = { _, buffer in
			buffer.writeBytes([0x05, 0x06])
			return nil
		}
		let encoder = SftpPacketEncoder(serializer: mockSerializer, allocator: ByteBufferAllocator())
		var buffer = ByteBuffer()

		XCTAssertNoThrow(try encoder.encode(data: .header(.dataReply(.init(id: 1)), 10), out: &buffer))
		// Ensure that the proper length (1 for packetType, 2 for serialization,
		// 10 for body = 0x0D) was written, plus the serialized data.
		XCTAssertEqual(buffer, ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x0D, jlsftp.SftpProtocol.PacketType.dataReply.rawValue, 0x05, 0x06]))

		XCTAssertNoThrow(try encoder.encode(data: .body(ByteBuffer(bytes: [0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01])), out: &buffer))
		// Ensure that the body was written properly.
		XCTAssertEqual(buffer, ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x0D, jlsftp.SftpProtocol.PacketType.dataReply.rawValue, 0x05, 0x06, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01]))

		XCTAssertNoThrow(try encoder.encode(data: .end, out: &buffer))
		// Ensure that the end was ignored properly.
		XCTAssertEqual(buffer, ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x0D, jlsftp.SftpProtocol.PacketType.dataReply.rawValue, 0x05, 0x06, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01]))
	}

	static var allTests = [
		("testValid", testValid),
		("testInvalid", testInvalid),
		("testNopSkip", testNopSkip),
		("testBody", testBody),
		("testEnd", testEnd),
	]
}
