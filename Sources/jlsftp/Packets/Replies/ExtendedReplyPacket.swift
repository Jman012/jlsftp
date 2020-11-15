import Foundation

/**
 A reply to a generic request packet supplying extension data.

 - Since: sftp v3
 - Note: Expected Response Packet:
 */
public class ExtendedReplyPacket: BasePacket {

	/**
	 Request identifier.

	 - Since: sftp v3
	 */
	public let id: PacketId

	public init(id: PacketId) {
		self.id = id
	}
}
