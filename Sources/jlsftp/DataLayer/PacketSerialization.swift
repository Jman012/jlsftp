import Foundation

public enum DeserializationError: Error, Equatable {
	case invalidType
	case payloadTooShort
	case invalidDataPayload(reason: String)
}

public protocol PacketSerialization {

	func deserialize(rawPacket: RawPacket) -> Result<Packet, DeserializationError>
}
