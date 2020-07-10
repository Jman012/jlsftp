import Foundation

public class ClosePacket: BasePacket {

	public let id: PacketId
	public let handle: FileHandle

	public init(id: PacketId, handle: String) {
		self.id = id
		self.handle = handle
	}
}
