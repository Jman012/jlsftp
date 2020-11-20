import Foundation

public struct NOPDebugPacket: Equatable {
	public let message: String

	public init(message: String) {
		self.message = message
	}
}
