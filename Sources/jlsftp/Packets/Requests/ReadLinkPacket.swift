import Foundation

/**
  Retrieves information about a remote symbolic link.

 - Since: sftp v3
 - Note: Expected Response Packet:
   * Success => [NameReplyPacket](x-source-tag://NameReplyPacket)
   * Failure => [StatusReplyPacket](x-source-tag://StatusReplyPacket)
 */
public struct ReadLinkPacket: BasePacket, Equatable {

	/**
	 Request identifier.

	 - Since: sftp v3
	 */
	public let id: PacketId
	/**
	 Path of the remote resource to read the link information.

	  - Since: sftp v3
	 */
	public let path: String

	public init(id: PacketId, path: String) {
		self.id = id
		self.path = path
	}
}
