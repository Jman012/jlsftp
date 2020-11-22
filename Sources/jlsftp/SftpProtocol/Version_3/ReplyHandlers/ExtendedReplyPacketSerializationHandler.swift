import Foundation
import NIO

extension jlsftp.SftpProtocol.Version_3 {

	public class ExtendedReplyPacketSerializationHandler: PacketSerializationHandler {

		public func deserialize(from buffer: inout ByteBuffer) -> Result<Packet, PacketDeserializationHandlerError> {
			// Id
			guard let id = buffer.readInteger(endianness: .big, as: UInt32.self) else {
				return .failure(.needMoreData)
			}

			return .success(.extendedReply(ExtendedReplyPacket(id: id)))
		}

		public func serialize(packet: Packet, to buffer: inout ByteBuffer) -> PacketSerializationHandlerError? {
			guard case let .extendedReply(extendedReplyPacket) = packet else {
				return .wrongPacketInternalError
			}

			// Id
			buffer.writeInteger(extendedReplyPacket.id, endianness: .big, as: UInt32.self)

			return nil
		}
	}
}
