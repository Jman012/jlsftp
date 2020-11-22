import Foundation
import NIO

extension jlsftp.SftpProtocol.Version_3 {

	public class RealPathPacketSerializationHandler: PacketSerializationHandler {

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

			return .success(.realPath(RealPathPacket(id: id, path: path)))
		}

		public func serialize(packet: Packet, to buffer: inout ByteBuffer) -> Bool {
			guard case let .realPath(realPathPacket) = packet else {
				return false
			}

			// Id
			buffer.writeInteger(realPathPacket.id, endianness: .big, as: UInt32.self)

			// Path
			guard buffer.writeSftpString(realPathPacket.path) else {
				return false
			}

			return true
		}
	}
}
