import Foundation
import NIO

extension jlsftp.SftpProtocol.Version_3 {

	public class ReadPacketSerializationHandler: PacketSerializationHandler {

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

			// Length
			guard let length = buffer.readInteger(endianness: .big, as: UInt32.self) else {
				return .failure(.needMoreData)
			}

			return .success(.read(ReadPacket(id: id, handle: handle, offset: offset, length: length)))
		}

		public func serialize(packet: Packet, to buffer: inout ByteBuffer) -> PacketSerializationHandlerError? {
			guard case let .read(readPacket) = packet else {
				return .wrongPacketInternalError
			}

			// Id
			buffer.writeInteger(readPacket.id, endianness: .big, as: UInt32.self)

			// Handle
			buffer.writeSftpString(readPacket.handle)

			// Offset
			buffer.writeInteger(readPacket.offset, endianness: .big, as: UInt64.self)

			// Length
			buffer.writeInteger(readPacket.length, endianness: .big, as: UInt32.self)

			return nil
		}
	}
}
