import Foundation
import NIO

extension jlsftp.SftpProtocol.Version_3 {

	public class HandleStatusPacketSerializationHandler: PacketSerializationHandler {

		public func deserialize(from buffer: inout ByteBuffer) -> Result<Packet, PacketDeserializationHandlerError> {
			// Id
			guard let id = buffer.readInteger(endianness: .big, as: UInt32.self) else {
				return .failure(.needMoreData)
			}

			// Handle
			let handleResult = buffer.readSftpString()
			guard case let .success(handle) = handleResult else {
				return .failure(handleResult.error!.customMapError(wrapper: "Failed to deserialize handle"))
			}

			return .success(.handleStatus(HandleStatusPacket(id: id, handle: handle)))
		}

		public func serialize(packet: Packet, to buffer: inout ByteBuffer) -> PacketSerializationHandlerError? {
			guard case let .handleStatus(handleStatusPacket) = packet else {
				return .wrongPacketInternalError
			}

			// Id
			buffer.writeInteger(handleStatusPacket.id, endianness: .big, as: UInt32.self)

			// Handle
			buffer.writeSftpString(handleStatusPacket.handle)

			return nil
		}
	}
}
