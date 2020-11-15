import Foundation

/**
 A generic request packet supplying extension data.

 - Since: sftp v3
 - Note: Expected Response Packet:
 * Success => Any reply packet
 * Failure => [StatusReplyPacket](x-source-tag://StatusReplyPacket) (specifically
   with `SSH_FX_OP_UNSUPPORTED`.
 */
public struct ExtendedPacket: BasePacket, Equatable {

	/**
	 Request identifier.

	 - Since: sftp v3
	 */
	public let id: PacketId
	/**
	 Request identifier, of the form "name@domain".

	 - Since: sftp v3
	 */
	public let extendedRequest: String

	public init(id: PacketId, extendedRequest: String) {
		self.id = id
		self.extendedRequest = extendedRequest
	}
}
