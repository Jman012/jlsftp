import Foundation

/**
 Creates a remote directory.

 - Since: sftp v3
 */
public class MakeDirectoryPacket: BasePacket {

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
