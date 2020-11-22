import Foundation
import NIO

extension jlsftp.SftpProtocol.Version_3 {

	public class WritePacketSerializationHandler: PacketSerializationHandler {

		public func deserialize(from buffer: inout ByteBuffer) -> Result<Packet, PacketSerializationHandlerError> {
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

		public func serialize(packet: Packet, to buffer: inout ByteBuffer) -> Bool {
			guard case let .write(writePacket) = packet else {
				return false
			}

			// Id
			buffer.writeInteger(writePacket.id, endianness: .big, as: UInt32.self)

			// Handle
			guard buffer.writeSftpString(writePacket.handle) else {
				return false
			}

			// Offtset
			buffer.writeInteger(writePacket.offset, endianness: .big, as: UInt64.self)

			return true
		}
	}
}
