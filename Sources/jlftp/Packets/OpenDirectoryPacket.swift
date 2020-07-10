import Foundation

/**
 Opens a remote directory.

 - Since: sftp v3
 */
public class OpenDirectoryPacket: BasePacket {

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
