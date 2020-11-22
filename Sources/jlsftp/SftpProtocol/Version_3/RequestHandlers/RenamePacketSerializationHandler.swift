import Foundation
import NIO

extension jlsftp.SftpProtocol.Version_3 {

	public class RenamePacketSerializationHandler: PacketSerializationHandler {

		public func deserialize(from buffer: inout ByteBuffer) -> Result<Packet, PacketDeserializationHandlerError> {
			// Id
			guard let id = buffer.readInteger(endianness: .big, as: UInt32.self) else {
				return .failure(.needMoreData)
			}

			// Old Path
			let oldPathResult = buffer.readSftpString()
			guard case let .success(oldPath) = oldPathResult else {
				return .failure(oldPathResult.error!.customMapError(wrapper: "Failed to deserialize old path"))
			}

			// New Path
			let newPathResult = buffer.readSftpString()
			guard case let .success(newPath) = newPathResult else {
				return .failure(newPathResult.error!.customMapError(wrapper: "Failed to deserialize new path"))
			}

			return .success(.rename(RenamePacket(id: id, oldPath: oldPath, newPath: newPath)))
		}

		public func serialize(packet: Packet, to buffer: inout ByteBuffer) -> PacketSerializationHandlerError? {
			guard case let .rename(renamePacket) = packet else {
				return .wrongPacketInternalError
			}

			// Id
			buffer.writeInteger(renamePacket.id, endianness: .big, as: UInt32.self)

			// Old Path
			buffer.writeSftpString(renamePacket.oldPath)

			// New Path
			buffer.writeSftpString(renamePacket.newPath)

			return nil
		}
	}
}
