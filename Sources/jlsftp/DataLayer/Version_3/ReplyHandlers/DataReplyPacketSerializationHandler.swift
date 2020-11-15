import Foundation
import NIO

extension jlsftp.DataLayer.Version_3 {

	public class DataReplyPacketSerializationHandler: PacketSerializationHandler {

		public func deserialize(buffer: inout ByteBuffer) -> Result<Packet, PacketSerializationHandlerError> {
			// Id
			guard let id = buffer.readInteger(endianness: .big, as: UInt32.self) else {
				return .failure(.needMoreData)
			}

			return .success(.dataReply(DataReplyPacket(id: id)))
		}
	}
}
