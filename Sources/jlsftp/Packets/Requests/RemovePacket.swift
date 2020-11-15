import Foundation

/**
  Removes a remote file.

 - Since: sftp v3
 - Note: Expected Response Packet:
   * Success => [StatusReplyPacket](x-source-tag://StatusReplyPacket)
   * Failure => [StatusReplyPacket](x-source-tag://StatusReplyPacket)
 */
public struct RemovePacket: BasePacket, Equatable {

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
