import Foundation
import NIO

extension jlsftp.DataLayer.Version_3 {

	public class OpenDirectoryPacketSerializationHandler: PacketSerializationHandler {

		public func deserialize(buffer: inout ByteBuffer) -> Result<Packet, PacketSerializationHandlerError> {
			// Id
			guard let id = buffer.readInteger(endianness: .big, as: UInt32.self) else {
				return .failure(.needMoreData)
			}

			// Path
			let pathResult = buffer.readSftpString()
			guard case let .success(path) = pathResult else {
				return .failure(pathResult.error!.customMapError(wrapper: "Failed to deserialize path"))
			}

			return .success(.openDirectory(OpenDirectoryPacket(id: id, path: path)))
		}

		public func serialize(packet: Packet, to buffer: inout ByteBuffer) -> Bool {
			guard case let .openDirectory(openDirectoryPacket) = packet else {
				return false
			}

			// Id
			buffer.writeInteger(openDirectoryPacket.id, endianness: .big, as: UInt32.self)

			// Path
			guard buffer.writeSftpString(openDirectoryPacket.path) else {
				return false
			}

			return true
		}
	}
}
