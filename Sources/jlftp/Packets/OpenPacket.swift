import Foundation

/**
  Opens a remote file.

 - Since: sftp v3
 */
public class OpenPacket: BasePacket {

	/**
	 Request identifier.

	 - Since: sftp v3
	 */
	public let id: PacketId
	/**
	  Path of the remove file to open.

	  - Since: sftp v3
	 */
	public let filename: String
	/**
	  POSIX-style flags for opening the remote file.

	  - Since: sftp v3
	 */
	public let pflags: PFlags
	/**
	  Initial file attributes for the remote file, if it is being created.

	  - Since: sftp v3
	 */
	public let fileAttributes: FileAttributes

	public init(id: PacketId,
				filename: String,
				pflags: PFlags,
				fileAttributes: FileAttributes) {
		self.id = id
		self.filename = filename
		self.pflags = pflags
		self.fileAttributes = fileAttributes
	}
}
