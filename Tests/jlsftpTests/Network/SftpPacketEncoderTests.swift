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

	/// Tests that normal packets are handled correctly.
	func testValid() {
		let mockSerializer = MockSerializer()
		mockSerializer.serializeHandler = { _, buffer in
			buffer.writeBytes([0x01])
			return nil
		}
		let encoder = SftpPacketEncoder(serializer: mockSerializer)
		var buffer = ByteBuffer()

		XCTAssertNoThrow(try encoder.encode(data: .initializeV3(InitializePacketV3(version: .v3, extensionData: [])), out: &buffer))
		XCTAssertEqual(buffer, ByteBuffer(bytes: [0x01]))
	}

	func testInvalid() {
		let mockSerializer = MockSerializer()
		mockSerializer.serializeHandler = { _, buffer in
			buffer.writeBytes([0x01])
			return .wrongPacketInternalError
		}
		let encoder = SftpPacketEncoder(serializer: mockSerializer)
		var buffer = ByteBuffer()

		XCTAssertThrowsError(try encoder.encode(data: .initializeV3(InitializePacketV3(version: .v3, extensionData: [])), out: &buffer)) { error in
			XCTAssert(error is SftpPacketEncoder.EncoderError)
			XCTAssertEqual(error as! SftpPacketEncoder.EncoderError, SftpPacketEncoder.EncoderError.failedToSerialize(message: "wrongPacketInternalError"))
		}
		// Ensure that any writes to the buffer were undone upon failure
		XCTAssertEqual(buffer, ByteBuffer(bytes: []))
	}

	static var allTests = [
		("testValid", testValid),
		("testInvalid", testInvalid),
	]
}
