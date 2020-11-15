import Foundation

/**
 The base of all packets, except for `InitializePacket` and `VersionPacket`,
 used in request/response scenarios, which all contain an `id` field.
 */
public protocol BasePacket: Identifiable {

	/**
	  A unique identifier for a packet request/response combination.

	  - Remark: See `PacketId`
	  - Since: sftp v3
	 */
	var id: PacketId { get }
}
