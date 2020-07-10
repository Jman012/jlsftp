import Foundation

/**
  Renames a remote resource.

 - Since: sftp v3
 */
public class RenamePacket: BasePacket {

	/**
	 Request identifier.

	 - Since: sftp v3
	 */
	public let id: PacketId
	/**
	  Current path of the remote resource, that will turn into `newPath`.

	  - Since: sftp v3
	 */
	public let oldPath: String
	/**
	  Desired new path of the remote resource located at `oldPath`.

	 - Since: sftp v3
	 */
	public let newPath: String

	public init(id: PacketId, oldPath: String, newPath: String) {
		self.id = id
		self.oldPath = oldPath
		self.newPath = newPath
	}
}
