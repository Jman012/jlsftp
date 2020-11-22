import Foundation
import NIO

extension jlsftp.SftpProtocol.Version_3 {

	public class RemovePacketSerializationHandler: PacketSerializationHandler {

		public func deserialize(from buffer: inout ByteBuffer) -> Result<Packet, PacketSerializationHandlerError> {
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

		public func serialize(packet: Packet, to buffer: inout ByteBuffer) -> Bool {
			guard case let .remove(removePacket) = packet else {
				return false
			}

			// Id
			buffer.writeInteger(removePacket.id, endianness: .big, as: UInt32.self)

			// Filename
			guard buffer.writeSftpString(removePacket.filename) else {
				return false
			}

			return true
		}
	}
}
