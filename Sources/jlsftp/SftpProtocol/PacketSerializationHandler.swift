import Foundation
import NIO

public enum PacketDeserializationHandlerError: Error, Equatable {
	case needMoreData
	case invalidData(reason: String)

	public func customMapError(wrapper: String) -> Self {
		switch self {
		case .needMoreData:
			return .needMoreData
		case let .invalidData(reason: message):
			return .invalidData(reason: "\(wrapper): \(message)")
		}
	}
}

public enum PacketSerializationHandlerError: Error, Equatable {
	case wrongPacketInternalError
	case packetNotSerializable
	case missingPacketSerializationHandler
}

public protocol PacketSerializationHandler {

	func deserialize(from buffer: inout ByteBuffer) -> Result<Packet, PacketDeserializationHandlerError>

	func serialize(packet: Packet, to buffer: inout ByteBuffer) -> PacketSerializationHandlerError?
}
