import Foundation
import NIO

extension jlsftp.SftpProtocol.Version_3 {

	public class RemovePacketSerializationHandler: PacketSerializationHandler {

		public func deserialize(from buffer: inout ByteBuffer) -> Result<Packet, PacketDeserializationHandlerError> {
			// Id
			guard let id = buffer.readInteger(endianness: .big, as: UInt32.self) else {
				return .failure(.needMoreData)
			}

			// Filename
			let filenameResult = buffer.readSftpString()
			guard case let .success(filename) = filenameResult else {
				return .failure(filenameResult.error!.customMapError(wrapper: "Failed to deserialize filename"))
			}

			return .success(.remove(RemovePacket(id: id, filename: filename)))
		}

		public func serialize(packet: Packet, to buffer: inout ByteBuffer) -> PacketSerializationHandlerError? {
			guard case let .remove(removePacket) = packet else {
				return .wrongPacketInternalError
			}

			// Id
			buffer.writeInteger(removePacket.id, endianness: .big, as: UInt32.self)

			// Filename
			buffer.writeSftpString(removePacket.filename)

			return nil
		}
	}
}
