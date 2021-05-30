import Foundation
import NIO
import NIOTestUtils
import XCTest
@testable import jlsftp


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
