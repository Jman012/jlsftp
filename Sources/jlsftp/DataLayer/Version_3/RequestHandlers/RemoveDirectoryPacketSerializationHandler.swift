import Foundation
import NIO

extension jlsftp.DataLayer.Version_3 {

	public class RemoveDirectoryPacketSerializationHandler: PacketSerializationHandler {

		public func deserialize(buffer: inout ByteBuffer) -> Result<Packet, PacketSerializationHandlerError> {
			// Id
			guard let id = buffer.readInteger(endianness: .big, as: UInt32.self) else {
				return .failure(.needMoreData)
			}

			// Path
			let pathResult = buffer.readSftpString()
			guard case let .success(path) = pathResult else {
				return .failure(pathResult.error!.customMapError(wrapper: "Failed to deserialize filename"))
			}

			return .success(RemoveDirectoryPacket(id: id, path: path))
		}
	}
}
