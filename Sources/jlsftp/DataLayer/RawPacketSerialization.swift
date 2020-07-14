import Foundation

public enum ParsingError: Error {
	/// Input data is empty.
	case noData
	/// There is not enough data to parse the length field.
	case noLength
	/// There is not enough data to parse the type field.
	case noType
	/// There is no payload associated with the packet (length is 0).
	case noDataPayload
	/// The overall size of the given data does not match the reported length of the payload.
	case lengthMismatch
}

public protocol RawPacketSerialization {

	func deserialize(from data: Data) -> Result<RawPacket, ParsingError>
}
