import Foundation

/**
 Retrieves the file attributes of a remote resource.

 - Since: sftp v3
 - Note: Expected Response Packet:
   * Success => [FileAttributesReplyPacket](x-source-tag://FileAttributesReplyPacket)
   * Failure => [StatusReplyPacket](x-source-tag://StatusReplyPacket)
 */
public struct StatusPacket: BasePacket, Equatable {

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
