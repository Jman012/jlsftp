import Foundation

public struct RawPacket {
	public let length: UInt32
	public let type: UInt8
	public let dataPayload: Data
}

extension RawPacket: Equatable {}
