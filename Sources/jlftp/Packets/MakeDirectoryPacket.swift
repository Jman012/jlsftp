import Foundation

public class MakeDirectoryPacket: BasePacket {

	public let id: PacketId
	public let path: String
	public let fileAttributes: FileAttributes

	public init(id: PacketId, path: String, fileAttributes: FileAttributes) {
		self.id = id
		self.path = path
		self.fileAttributes = fileAttributes
	}
}
