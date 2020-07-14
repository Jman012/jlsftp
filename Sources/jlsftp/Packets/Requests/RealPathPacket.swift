import Foundation

/**
  Retrieves the canonical path of a remote resource.

 - Since: sftp v3
 - Note: Expected Response Packet:
   * Success => [NameReplyPacket](x-source-tag://NameReplyPacket)
   * Failure => [StatusReplyPacket](x-source-tag://StatusReplyPacket)
 */
public class RealPathPacket: BasePacket {

	/**
	 Request identifier.

	 - Since: sftp v3
	 */
	public let id: PacketId
	/**
	  Path of the remote resource to retrieve the real path.

	  - Since: sftp v3
	 */
	public let path: String

	public init(id: PacketId, path: String) {
		self.id = id
		self.path = path
	}
}
