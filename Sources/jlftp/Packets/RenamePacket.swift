import Foundation

public class RenamePacket: BasePacket {

	public let id: PacketId
	public let oldPath: String
	public let newPath: String

	public init(id: PacketId, oldPath: String, newPath: String) {
		self.id = id
		self.oldPath = oldPath
		self.newPath = newPath
	}
}
