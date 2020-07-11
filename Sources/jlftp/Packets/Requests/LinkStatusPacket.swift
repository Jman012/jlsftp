import Foundation

/**
  Retrieves the file attributes of a remote symbolic link.

 - Since: sftp v3
 - Note: Expected Response Packet:
   * Success => [FileAttributesReplyPacket](x-source-tag://FileAttributesReplyPacket)
   * Failure => [StatusReplyPacket](x-source-tag://StatusReplyPacket)
 */
public class LinkStatusPacket: BasePacket {

	/**
	 Request identifier.

	 - Since: sftp v3
	 */
	public let id: PacketId
	/**
	  Path of a remote resource.

	  - Since: sftp v3
	 */
	public let path: String

	public init(id: PacketId, path: String) {
		self.id = id
		self.path = path
	}
}
