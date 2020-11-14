import Foundation
import NIO

extension jlsftp.DataLayer.Version_3 {

	public class RenamePacketSerializationHandler: PacketSerializationHandler {

		public func deserialize(buffer: inout ByteBuffer) -> Result<Packet, PacketSerializationHandlerError> {
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

			return .success(RenamePacket(id: id, oldPath: oldPath, newPath: newPath))
		}
	}
}
