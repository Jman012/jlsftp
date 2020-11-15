import Foundation

/**
  Retrieves the file attributes of a remote handle.

 - Since: sftp v3
 - Note: Expected Response Packet:
   * Success => [FileAttributesReplyPacket](x-source-tag://FileAttributesReplyPacket)
   * Failure => [StatusReplyPacket](x-source-tag://StatusReplyPacket)
 */
public struct HandleStatusPacket: BasePacket, Equatable {

	/**
	 Request identifier.

	 - Since: sftp v3
	 */
	public let id: PacketId
	/**
	 Previously opened handle of the file or directory to retrieve the status.

	 - Since: sftp v3
	 */
	public let handle: String

	public init(id: PacketId, handle: String) {
		self.id = id
		self.handle = handle
	}
}
