import Foundation

public enum ParsingError: Error {
	/// Input data is empty.
	case noData
	/// There is not enough data to parse the length field.
	case noLength(message: String)
	/// There is not enough data to parse the type field.
	case noType(message: String)
	/// There is no payload associated with the packet (length is 0).
	case noDataPayload
	/// The overall size of the given data does not match the reported length of the payload.
	case lengthMismatch

	public var description: String {
		switch self {
		case .noData:
			return ""
		case let .noLength(message: msg):
			return "Could not parse the length field from the packet: \(msg)"
		case let .noType(message: msg):
			return "Could not parse the type field from the packet: \(msg)"
		case .noDataPayload:
			return ""
		case .lengthMismatch:
			return ""
		}
	}
}

public protocol RawPacketSerialization {

	func deserialize(from data: Data) -> Result<RawPacket, ParsingError>
}
