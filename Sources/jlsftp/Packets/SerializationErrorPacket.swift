import Foundation

public class SerializationErrorPacket: Packet {
	public let errorMessage: String

	public init(errorMessage: String) {
		self.errorMessage = errorMessage
	}
}
