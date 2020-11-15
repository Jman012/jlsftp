import Foundation

public class SerializationErrorPacket {
	public let errorMessage: String

	public init(errorMessage: String) {
		self.errorMessage = errorMessage
	}
}
