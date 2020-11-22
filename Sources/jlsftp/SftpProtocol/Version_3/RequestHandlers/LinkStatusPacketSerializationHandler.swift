import Foundation
import NIO

extension jlsftp.SftpProtocol.Version_3 {

	public class LinkStatusPacketSerializationHandler: PacketSerializationHandler {

		public func deserialize(from buffer: inout ByteBuffer) -> Result<Packet, PacketDeserializationHandlerError> {
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

		public func serialize(packet: Packet, to buffer: inout ByteBuffer) -> PacketSerializationHandlerError? {
			guard case let .linkStatus(linkStatusPacket) = packet else {
				return .wrongPacketInternalError
			}

			// Id
			buffer.writeInteger(linkStatusPacket.id, endianness: .big, as: UInt32.self)

			// Path
			buffer.writeSftpString(linkStatusPacket.path)

			return nil
		}
	}
}
