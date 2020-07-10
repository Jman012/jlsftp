import Foundation

/**
  Retrieves the canonical path of a remote resource.

 - Since: sftp v3
 */
public class RealPathPacket: BasePacket {

	/**
	 Request identifier.

	 - Since: sftp v3
	 */
	public let id: PacketId
	/**
	  Path of the remote resource to retrieve the real path.

	  - Since: sftp v3
	 */
	public let path: String
}
