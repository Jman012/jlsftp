import Foundation

/**
  Sets the file attributes of an opened handle.

 - Since: sftp v3
 */
public class SetHandleStatusPacket: BasePacket {

	/**
	 Request identifier.

	 - Since: sftp v3
	 */
	public let id: PacketId
	/**
	  Previously opened handle of the remote resource to set the status.

	  - Since: sftp v3
	 */
	public let handle: String
	/**
	  New file attributes to be set on the `handle`.

	  - Since: sftp v3
	 */
	public let fileAttributes: FileAttributes

	public init(id: PacketId, handle: String, fileAttributes: FileAttributes) {
		self.id = id
		self.handle = handle
		self.fileAttributes = fileAttributes
	}
}
