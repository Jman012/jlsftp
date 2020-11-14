import Foundation
import NIO

extension jlsftp.DataLayer.Version_3 {

	public class CreateSymbolicLinkPacketSerializationHandler: PacketSerializationHandler {

		public func deserialize(buffer: inout ByteBuffer) -> Result<Packet, PacketSerializationHandlerError> {
			// Id
			guard let id = buffer.readInteger(endianness: .big, as: UInt32.self) else {
				return .failure(.needMoreData)
			}

			// Link Path
			let linkPathResult = buffer.readSftpString()
			guard case let .success(linkPath) = linkPathResult else {
				return .failure(linkPathResult.error!.customMapError(wrapper: "Failed to deserialize link path"))
			}

			// Target Path
			let targetPathResult = buffer.readSftpString()
			guard case let .success(targetPath) = targetPathResult else {
				return .failure(targetPathResult.error!.customMapError(wrapper: "Failed to deserialize target path"))
			}

			return .success(CreateSymbolicLinkPacket(id: id, linkPath: linkPath, targetPath: targetPath))
		}
	}
}
