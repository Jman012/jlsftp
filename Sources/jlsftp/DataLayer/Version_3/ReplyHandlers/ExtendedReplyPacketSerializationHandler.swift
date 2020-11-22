import Foundation
import NIO

extension jlsftp.DataLayer.Version_3 {

	public class ExtendedReplyPacketSerializationHandler: PacketSerializationHandler {

		public func deserialize(from buffer: inout ByteBuffer) -> Result<Packet, PacketSerializationHandlerError> {
			// Id
			guard let id = buffer.readInteger(endianness: .big, as: UInt32.self) else {
				return .failure(.needMoreData)
			}

			return .success(.extendedReply(ExtendedReplyPacket(id: id)))
		}

		public func serialize(packet: Packet, to buffer: inout ByteBuffer) -> Bool {
			guard case let .extendedReply(extendedReplyPacket) = packet else {
				return false
			}

			// Id
			buffer.writeInteger(extendedReplyPacket.id, endianness: .big, as: UInt32.self)

			return true
		}
	}
}
