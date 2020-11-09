import Foundation
import NIO

public struct RawPacket {
	public let length: UInt32
	public let type: UInt8
	public let dataPayload: Data
	public let dataStream: DataReadStream
	public let buffer: ByteBuffer
}
