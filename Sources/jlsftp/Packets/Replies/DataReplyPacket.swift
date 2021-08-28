import Foundation

/**
 Returns the requested data of a file.

 - Tag: DataReplyPacket
 - Since: sftp v3
 */
public struct DataReplyPacket: BasePacket, Equatable {

	/**
	 Request identifier.

	  - Since: sftp v3
	 */
	public let id: PacketId

	/**
	 The length of the data to follow.

	  - Since: sftp v3
	*/
	public let dataLength: UInt32

	public init(id: PacketId, dataLength: UInt32) {
		self.id = id
		self.dataLength = dataLength
	}
}
