import Foundation

public class OpenPacket: BasePacket {

	public let id: PacketId
	public let filename: String
	public let pflags: PFlags
	public let fileAttributes: FileAttributes

	public init(id: PacketId,
				filename: String,
				pflags: PFlags,
				fileAttributes: FileAttributes) {
		self.id = id
		self.filename = filename
		self.pflags = pflags
		self.fileAttributes = fileAttributes
	}
}
