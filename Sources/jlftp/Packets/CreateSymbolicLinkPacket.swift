import Foundation

/**
 Creates a remote symbolic link.

 - Since: sftp v3
 */
public class CreateSymbolicLinkPacket: BasePacket {

	/**
	 Request identifier.

	 - Since: sftp v3
	 */
	public let id: PacketId
	/**
	 Remote path of where the link will reside.

	  - Since: sftp v3
	 */
	public let linkPath: String
	/**
	 Remote path of the existing resource that the symbolic link will link to.

	  - Since: sftp v3
	 */
	public let targetPath: String
}
