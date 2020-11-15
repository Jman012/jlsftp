import Foundation

/**
  Writes data to a remote file.

 - Since: sftp v3
 - Note: Expected Response Packet:
   * Success => [StatusReplyPacket](x-source-tag://StatusReplyPacket)
   * Failure => [StatusReplyPacket](x-source-tag://StatusReplyPacket)
 */
public struct WritePacket: BasePacket, Equatable {

	/**
	 Request identifier.

	 - Since: sftp v3
	 */
	public let id: PacketId
	/**
	  Previously opened handle of the remote file to write.

	  - Since: sftp v3
	 */
	public let handle: FileHandle
	/**
	  The offset position of the `handle` to start writing data.

	  - Remark: This can lay otuside the current size of the file. Any data
	  between the end of the file and this offset will be filled with zeroes.
	  In most operating systems, this may be represented as gaps in the file, and
	  not take up physical space.
	  - Since: sftp v3
	 */
	public let offset: UInt64

	public init(id: PacketId, handle: FileHandle, offset: UInt64) {
		self.id = id
		self.handle = handle
		self.offset = offset
	}
}
