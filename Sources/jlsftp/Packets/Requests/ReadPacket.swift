import Foundation

/**
  Reads the contents of a remote file.

 - Since: sftp v3
 - Note: Expected Response Packet:
   * Success => [DataReplyPacket](x-source-tag://DataReplyPacket)
   * Failure => [StatusReplyPacket](x-source-tag://StatusReplyPacket)
 */
public class ReadPacket: BasePacket {

	/**
	 Request identifier.

	 - Since: sftp v3
	 */
	public let id: PacketId
	/**
	 Previously opened handle of the file to read the contents of.

	  - Since: sftp v3
	 */
	public let handle: FileHandle
	/**
	 Offset of the file. Any data is returned starting at this offset.

	  - Since: sftp v3
	 */
	public let offset: UInt64
	/**
	 The maximum amount of data to return starting at the `offset`.

	  - Since: sftp v3
	 */
	public let length: UInt32

	public init(id: PacketId,
				handle: FileHandle,
				offset: UInt64,
				length: UInt32) {
		self.id = id
		self.handle = handle
		self.offset = offset
		self.length = length
	}
}
