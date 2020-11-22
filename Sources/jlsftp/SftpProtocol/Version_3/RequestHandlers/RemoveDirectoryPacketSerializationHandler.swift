import Foundation
import NIO

extension jlsftp.SftpProtocol.Version_3 {

	public class RemoveDirectoryPacketSerializationHandler: PacketSerializationHandler {

		public func deserialize(from buffer: inout ByteBuffer) -> Result<Packet, PacketDeserializationHandlerError> {
			// Id
			guard let id = buffer.readInteger(endianness: .big, as: UInt32.self) else {
				return .failure(.needMoreData)
			}

			// Path
			let pathResult = buffer.readSftpString()
			guard case let .success(path) = pathResult else {
				return .failure(pathResult.error!.customMapError(wrapper: "Failed to deserialize filename"))
			}

			return .success(.removeDirectory(RemoveDirectoryPacket(id: id, path: path)))
		}

		public func serialize(packet: Packet, to buffer: inout ByteBuffer) -> PacketSerializationHandlerError? {
			guard case let .removeDirectory(removeDirectoryPacket) = packet else {
				return .wrongPacketInternalError
			}

			// Id
			buffer.writeInteger(removeDirectoryPacket.id, endianness: .big, as: UInt32.self)

			// Path
			buffer.writeSftpString(removeDirectoryPacket.path)

			return nil
		}
	}
}
