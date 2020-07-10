import Foundation

/**
  Removes a remote file.

 - Since: sftp v3
 */
public class RemovePacket: BasePacket {

	/**
	 Request identifier.

	 - Since: sftp v3
	 */
	public let id: PacketId
	/**
	 Path of the remote file to remove.

	  - Since: sftp v3
	 */
	public let filename: String

	public init(id: PacketId, filename: String) {
		self.id = id
		self.filename = filename
	}
}
