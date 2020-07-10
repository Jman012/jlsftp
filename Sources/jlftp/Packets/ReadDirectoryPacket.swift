import Foundation

/**
  Retrieves the contents of a remote directory.

 - Since: sftp v3
 */
public class ReadDirectoryPacket: BasePacket {

	/**
	 Request identifier.

	 - Since: sftp v3
	 */
	public let id: PacketId
	/**
	 Previously opened handle of the directory to read.

	  - Since: sftp v3
	 */
	public let handle: String

	public init(id: PacketId, handle: String) {
		self.id = id
		self.handle = handle
	}
}
