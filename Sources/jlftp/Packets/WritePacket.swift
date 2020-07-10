import Foundation

public class WritePacket: BasePacket {

	public let id: PacketId
	public let handle: FileHandle
	public let offset: UInt64
	public let data: Data

	public init(id: PacketId, handle: FileHandle, offset: UInt64, data: Data) {
		self.id = id
		self.handle = handle
		self.offset = offset
		self.data = data
	}
}
