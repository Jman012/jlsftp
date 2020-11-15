import Foundation

/**
 Opens a remote directory.

 - Since: sftp v3
 - Note: Expected Response Packet:
   * Success => [HandleReplyPacket](x-source-tag://HandleReplyPacket)
   * Failure => [StatusReplyPacket](x-source-tag://StatusReplyPacket)
 */
public struct OpenDirectoryPacket: BasePacket, Equatable {

	/**
	 Request identifier.

	 - Since: sftp v3
	 */
	public let id: PacketId
	/**
	  Path of the remote directory on the server to open.

	  - Since: sftp v3
	 */
	public let path: String

	public init(id: PacketId, path: String) {
		self.id = id
		self.path = path
	}
}
