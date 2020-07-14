import Foundation

/**
 Sets the file attributes of a remote resource.

 - Since: sftp v3
 - Note: Expected Response Packet:
   * Success => [StatusReplyPacket](x-source-tag://StatusReplyPacket)
   * Failure => [StatusReplyPacket](x-source-tag://StatusReplyPacket)
 */
public class SetStatusPacket: BasePacket {

	/**
	 Request identifier.

	 - Since: sftp v3
	 */
	public let id: PacketId
	/**
	  Path of the remote resource to set the status.

	 - Since: sftp v3
	 */
	public let path: String
	/**
	  New file attributes to be set on the remote resource at the `path`.

	 - Since: sftp v3
	 */
	public let fileAttributes: FileAttributes

	public init(id: PacketId, path: String, fileAttributes: FileAttributes) {
		self.id = id
		self.path = path
		self.fileAttributes = fileAttributes
	}
}
