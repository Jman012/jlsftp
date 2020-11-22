import Foundation
import NIO

extension jlsftp.SftpProtocol.Version_3 {

	public class CreateSymbolicLinkPacketSerializationHandler: PacketSerializationHandler {

		public func deserialize(from buffer: inout ByteBuffer) -> Result<Packet, PacketSerializationHandlerError> {
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

		public func serialize(packet: Packet, to buffer: inout ByteBuffer) -> Bool {
			guard case let .createSymbolicLink(createSymbolicLinkPacket) = packet else {
				return false
			}

			// Id
			buffer.writeInteger(createSymbolicLinkPacket.id, endianness: .big, as: UInt32.self)

			// Link Path
			guard buffer.writeSftpString(createSymbolicLinkPacket.linkPath) else {
				return false
			}

			// Target Path
			guard buffer.writeSftpString(createSymbolicLinkPacket.targetPath) else {
				return false
			}

			return true
		}
	}
}
