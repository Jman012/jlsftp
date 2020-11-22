import Foundation
import NIO

extension jlsftp.DataLayer.Version_3 {

	public class DataReplyPacketSerializationHandler: PacketSerializationHandler {

		public func deserialize(from buffer: inout ByteBuffer) -> Result<Packet, PacketSerializationHandlerError> {
			// Id
			guard let id = buffer.readInteger(endianness: .big, as: UInt32.self) else {
				return .failure(.needMoreData)
			}

			return .success(.dataReply(DataReplyPacket(id: id)))
		}

		public func serialize(packet: Packet, to buffer: inout ByteBuffer) -> Bool {
			guard case let .dataReply(dataReplyPacket) = packet else {
				return false
			}

			// Id
			buffer.writeInteger(dataReplyPacket.id, endianness: .big, as: UInt32.self)

			return true
		}
	}
}
