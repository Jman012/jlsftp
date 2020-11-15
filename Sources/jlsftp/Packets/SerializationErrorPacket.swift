import Foundation

public struct SerializationErrorPacket: Equatable {
	public let errorMessage: String

	public init(errorMessage: String) {
		self.errorMessage = errorMessage
	}
}
