import Foundation

public class RemovePacket: BasePacket {

	public let id: PacketId
	public let filename: String

	public init(id: PacketId, filename: String) {
		self.id = id
		self.filename = filename
	}
}
