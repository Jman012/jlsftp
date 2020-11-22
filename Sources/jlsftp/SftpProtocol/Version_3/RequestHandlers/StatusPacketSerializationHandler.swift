import Foundation
import NIO

extension jlsftp.SftpProtocol.Version_3 {

	public class StatusPacketSerializationHandler: PacketSerializationHandler {

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

			return .success(.status(StatusPacket(id: id, path: path)))
		}

		public func serialize(packet: Packet, to buffer: inout ByteBuffer) -> PacketSerializationHandlerError? {
			guard case let .status(statusPacket) = packet else {
				return .wrongPacketInternalError
			}

			// Id
			buffer.writeInteger(statusPacket.id, endianness: .big, as: UInt32.self)

			// Path
			buffer.writeSftpString(statusPacket.path)

			return nil
		}
	}
}
