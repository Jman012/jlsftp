import Foundation
import NIO

extension jlsftp.DataLayer.Version_3 {

	public class ReadLinkPacketSerializationHandler: PacketSerializationHandler {

		public func deserialize(from buffer: inout ByteBuffer) -> Result<Packet, PacketSerializationHandlerError> {
			// Id
			guard let id = buffer.readInteger(endianness: .big, as: UInt32.self) else {
				return .failure(.needMoreData)
			}

			// Path
			let pathResult = buffer.readSftpString()
			guard case let .success(path) = pathResult else {
				return .failure(pathResult.error!.customMapError(wrapper: "Failed to deserialize path"))
			}

			return .success(.readLink(ReadLinkPacket(id: id, path: path)))
		}

		public func serialize(packet: Packet, to buffer: inout ByteBuffer) -> Bool {
			guard case let .readLink(readLinkPacket) = packet else {
				return false
			}

			// Id
			buffer.writeInteger(readLinkPacket.id, endianness: .big, as: UInt32.self)

			// Path
			guard buffer.writeSftpString(readLinkPacket.path) else {
				return false
			}

			return true
		}
	}
}
