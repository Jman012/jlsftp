import Foundation

/**
 Closes an opened handle.

  - Since: sftp v3
 */
public class ClosePacket: BasePacket {

	/**
	  Request identifier.

	  - Since: sftp v3
	 */
	public let id: PacketId
	/**
	  Previously opened handle of a file or directory to close.

	  - Since: sftp v3
	 */
	public let handle: FileHandle

	public init(id: PacketId, handle: String) {
		self.id = id
		self.handle = handle
	}
}
