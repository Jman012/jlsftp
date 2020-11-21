import Foundation
import NIO

extension jlsftp.DataLayer.Version_3 {

	public class HandleReplyPacketSerializationHandler: PacketSerializationHandler {

		public func deserialize(buffer: inout ByteBuffer) -> Result<Packet, PacketSerializationHandlerError> {
			// Id
			guard let id = buffer.readInteger(endianness: .big, as: UInt32.self) else {
				return .failure(.needMoreData)
			}

			// Handle
			let handleResult = buffer.readSftpString()
			guard case let .success(handle) = handleResult else {
				return .failure(handleResult.error!.customMapError(wrapper: "Failed to deserialize handle"))
			}

			return .success(.handleReply(HandleReplyPacket(id: id, handle: handle)))
		}

		public func serialize(packet: Packet, to buffer: inout ByteBuffer) -> Bool {
			guard case let .handleReply(handleReplyPacket) = packet else {
				return false
			}

			// Id
			buffer.writeInteger(handleReplyPacket.id, endianness: .big, as: UInt32.self)

			// Handle
			guard buffer.writeSftpString(handleReplyPacket.handle) else {
				return false
			}

			return true
		}
	}
}
