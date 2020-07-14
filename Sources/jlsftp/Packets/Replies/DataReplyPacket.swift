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
	/**
	  Arbitrary byte sequence containing the requested data.

	  - Since: sftp v3
	 */
	public let data: Data

	public init(id: PacketId, data: Data) {
		self.id = id
		self.data = data
	}
}
