import Foundation

/**
 Opens a remote file.

  - Since: sftp v3
  - Note: Expected Response Packet:
    * Success => [HandleReplyPacket](x-source-tag://HandleReplyPacket)
    * Failure => [StatusReplyPacket](x-source-tag://StatusReplyPacket)
  */
public struct OpenPacket: BasePacket, Equatable {

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
	public let pflags: OpenFlags
	/**
	  Initial file attributes for the remote file, if it is being created.

	  - Since: sftp v3
	 */
	public let fileAttributes: FileAttributes

	public init(id: PacketId,
				filename: String,
				pflags: OpenFlags,
				fileAttributes: FileAttributes) {
		self.id = id
		self.filename = filename
		self.pflags = pflags
		self.fileAttributes = fileAttributes
	}
}
