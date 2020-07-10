import Foundation

/**
  Retrieves information about a remote symbolic link.

 - Since: sftp v3
 */
public class ReadLinkPacket: BasePacket {

	/**
	 Request identifier.

	 - Since: sftp v3
	 */
	public let id: PacketId
	/**
	 Path of the remote resource to read the link information.

	  - Since: sftp v3
	 */
	public let path: String

	public init(id: PacketId, path: String) {
		self.id = id
		self.path = path
	}
}
