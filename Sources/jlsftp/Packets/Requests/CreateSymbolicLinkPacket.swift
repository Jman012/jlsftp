import Foundation

/**
 Creates a remote symbolic link.

 - Since: sftp v3
 - Note: Expected Response Packet:
   * Success => [StatusReplyPacket](x-source-tag://StatusReplyPacket)
   * Failure => [StatusReplyPacket](x-source-tag://StatusReplyPacket)
 */
public class CreateSymbolicLinkPacket: BasePacket {

	/**
	 Request identifier.

	 - Since: sftp v3
	 */
	public let id: PacketId
	/**
	 Remote path of where the link will reside.

	  - Since: sftp v3
	 */
	public let linkPath: String
	/**
	 Remote path of the existing resource that the symbolic link will link to.

	  - Since: sftp v3
	 */
	public let targetPath: String

	public init(id: PacketId, linkPath: String, targetPath: String) {
		self.id = id
		self.linkPath = linkPath
		self.targetPath = targetPath
	}
}
