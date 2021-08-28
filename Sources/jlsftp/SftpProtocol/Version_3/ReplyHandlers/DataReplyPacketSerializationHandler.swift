import Foundation
import NIO

extension jlsftp.SftpProtocol.Version_3 {

	public class DataReplyPacketSerializationHandler: PacketSerializationHandler {

		public func deserialize(from buffer: inout ByteBuffer) -> Result<Packet, PacketDeserializationHandlerError> {
			// Id
			guard let id = buffer.readInteger(endianness: .big, as: UInt32.self) else {
				return .failure(.needMoreData)
			}

			// Data Length
			guard let dataLength = buffer.readInteger(endianness: .big, as: UInt32.self) else {
				return .failure(.needMoreData)
			}

			return .success(.dataReply(DataReplyPacket(id: id, dataLength: dataLength)))
		}

		public func serialize(packet: Packet, to buffer: inout ByteBuffer) -> PacketSerializationHandlerError? {
			guard case let .dataReply(dataReplyPacket) = packet else {
				return .wrongPacketInternalError
			}

			// Id
			buffer.writeInteger(dataReplyPacket.id, endianness: .big, as: UInt32.self)

			// Data Length
			buffer.writeInteger(dataReplyPacket.dataLength, endianness: .big, as: UInt32.self)

			return nil
		}
	}
}
