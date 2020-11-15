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

	func testValid() {
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
//		expectedInOuts.append((ByteBuffer(bytes: [
//			// Init packet:
//			// Length (UInt32 Network Order: 1+4=5)
//			0x00, 0x00, 0x00, 0x05,
//			// Type (UInt8 SSH_FXP_INIT=1)
//			0x01,
//			// Version (UInt32 Network Order: 3)
//			0x00, 0x00, 0x00, 0x03,
//
//			// Version packet:
//			// Length (UInt32 Network Order: 1+4=5)
//			0x00, 0x00, 0x00, 0x05,
//			// Type (UInt8 SSH_FXP_VERSION=2)
//			0x02,
//			// Version (UInt32 Network Order: 4)
//			0x00, 0x00, 0x00, 0x04,
//		]), [
//			.header(.initializeV3(InitializePacketV3(version: .v3, extensionData: []))),
//			.header(.version(VersionPacket(version: .v4, extensionData: []))),
//		]))

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
		("testNeedsLength", testNeedsLength),
	]
}
