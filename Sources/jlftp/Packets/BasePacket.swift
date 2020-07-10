import Foundation

public protocol BasePacket: Packet {

	var id: PacketId { get }
}
