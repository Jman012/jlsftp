import Foundation
import NIO

public enum PacketSerializationHandlerError: Error, Equatable {
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

public protocol PacketSerializationHandler {

	func deserialize(from buffer: inout ByteBuffer) -> Result<Packet, PacketSerializationHandlerError>

	func serialize(packet: Packet, to buffer: inout ByteBuffer) -> Bool
}
