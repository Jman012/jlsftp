import Foundation
import NIO

public enum PacketSerializationHandlerError: Error {
	case needMoreData
	case invalidData(reason: String)
}

public protocol PacketSerializationHandler {

	func deserialize(buffer: inout ByteBuffer) -> Result<Packet, PacketSerializationHandlerError>
}
