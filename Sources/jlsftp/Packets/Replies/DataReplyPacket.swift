import Foundation

/**
 Returns the requested data of a file.

 - Tag: DataReplyPacket
 - Since: sftp v3
 */
public class DataReplyPacket: BasePacket {

	/**
	  Request identifier.

	  - Since: sftp v3
	 */
	public let id: PacketId

	public init(id: PacketId) {
		self.id = id
	}
}
