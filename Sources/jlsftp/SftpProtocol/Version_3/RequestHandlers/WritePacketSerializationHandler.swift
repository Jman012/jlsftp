import Foundation
import NIO

extension jlsftp.SftpProtocol.Version_3 {

	public class WritePacketSerializationHandler: PacketSerializationHandler {

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

			// Offset
			guard let offset = buffer.readInteger(endianness: .big, as: UInt64.self) else {
				return .failure(.needMoreData)
			}

			return .success(.write(WritePacket(id: id, handle: handle, offset: offset)))
		}

		public func serialize(packet: Packet, to buffer: inout ByteBuffer) -> PacketSerializationHandlerError? {
			guard case let .write(writePacket) = packet else {
				return .wrongPacketInternalError
			}

			// Id
			buffer.writeInteger(writePacket.id, endianness: .big, as: UInt32.self)

			// Handle
			buffer.writeSftpString(writePacket.handle)

			// Offtset
			buffer.writeInteger(writePacket.offset, endianness: .big, as: UInt64.self)

			return nil
		}
	}
}
