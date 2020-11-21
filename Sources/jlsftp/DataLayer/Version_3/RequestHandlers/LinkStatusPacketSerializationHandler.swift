import Foundation
import NIO

extension jlsftp.DataLayer.Version_3 {

	public class LinkStatusPacketSerializationHandler: PacketSerializationHandler {

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

			return .success(.linkStatus(LinkStatusPacket(id: id, path: path)))
		}

		public func serialize(packet: Packet, to buffer: inout ByteBuffer) -> Bool {
			guard case let .linkStatus(linkStatusPacket) = packet else {
				return false
			}

			// Id
			buffer.writeInteger(linkStatusPacket.id, endianness: .big, as: UInt32.self)

			// Path
			guard buffer.writeSftpString(linkStatusPacket.path) else {
				return false
			}

			return true
		}
	}
}
