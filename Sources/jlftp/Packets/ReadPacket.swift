import Foundation

public class ReadPacket: BasePacket {

	public let id: PacketId
	public let handle: FileHandle
	public let offset: UInt64
	public let length: UInt32

	public init(id: PacketId,
				handle: FileHandle,
				offset: UInt64,
				length: UInt32) {
		self.id = id
		self.handle = handle
		self.offset = offset
		self.length = length
	}
}
