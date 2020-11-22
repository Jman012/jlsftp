import Foundation
import NIO

extension jlsftp.SftpProtocol.Version_3 {

	public class CreateSymbolicLinkPacketSerializationHandler: PacketSerializationHandler {

		public func deserialize(from buffer: inout ByteBuffer) -> Result<Packet, PacketDeserializationHandlerError> {
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

			return .success(.createSymbolicLink(CreateSymbolicLinkPacket(id: id, linkPath: linkPath, targetPath: targetPath)))
		}

		public func serialize(packet: Packet, to buffer: inout ByteBuffer) -> PacketSerializationHandlerError? {
			guard case let .createSymbolicLink(createSymbolicLinkPacket) = packet else {
				return .wrongPacketInternalError
			}

			// Id
			buffer.writeInteger(createSymbolicLinkPacket.id, endianness: .big, as: UInt32.self)

			// Link Path
			buffer.writeSftpString(createSymbolicLinkPacket.linkPath)

			// Target Path
			buffer.writeSftpString(createSymbolicLinkPacket.targetPath)

			return nil
		}
	}
}
