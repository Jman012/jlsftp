import Foundation

/**
 Retrieves the file attributes of a remote resource.

 - Since: sftp v3
 */
public class StatusPacket: BasePacket {

	/**
	 Request identifier.

	 - Since: sftp v3
	 */
	public let id: PacketId
	/**
	  Path of the remote resource to pull the status.

	 - Since: sftp v3
	 */
	public let path: String

	public init(id: PacketId, path: String) {
		self.id = id
		self.path = path
	}
}
