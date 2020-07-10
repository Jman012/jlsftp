import Foundation

public class ScanDirectoryPacket: BasePacket {

	public let id: PacketId
	public let path: String

	public init(id: PacketId, path: String) {
		self.id = id
		self.path = path
	}
}
