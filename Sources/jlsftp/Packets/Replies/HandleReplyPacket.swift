import Foundation

/**
 Returns the handle of an opened file or directory.

 - Tag: HandleReplyPacket
 - Since: sftp v3
 */
public struct HandleReplyPacket: BasePacket, Equatable {

	/**
	  Request identifier.

	  - Since: sftp v3
	 */
	public let id: PacketId
	/**
	  An arbitrary string that identifies an open file or directory on the
	  server.

	  - Since: sftp v3
	 */
	public let handle: String

	public init(id: PacketId, handle: String) {
		self.id = id
		self.handle = handle
	}
}
