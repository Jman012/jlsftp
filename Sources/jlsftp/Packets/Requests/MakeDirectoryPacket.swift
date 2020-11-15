import Foundation

/**
 Creates a remote directory.

 - Since: sftp v3
 - Note: Expected Response Packet:
   * Success => [StatusReplyPacket](x-source-tag://StatusReplyPacket)
   * Failure => [StatusReplyPacket](x-source-tag://StatusReplyPacket)
 */
public struct MakeDirectoryPacket: BasePacket, Equatable {

	/**
	 Request identifier.

	 - Since: sftp v3
	 */
	public let id: PacketId
	/**
	  Path of the new remote directory.

	  - Since: sftp v3
	 */
	public let path: String
	/**
	  Desired file attributes of the new remote directory.

	  - Since: sftp v3
	 */
	public let fileAttributes: FileAttributes

	public init(id: PacketId, path: String, fileAttributes: FileAttributes) {
		self.id = id
		self.path = path
		self.fileAttributes = fileAttributes
	}
}
