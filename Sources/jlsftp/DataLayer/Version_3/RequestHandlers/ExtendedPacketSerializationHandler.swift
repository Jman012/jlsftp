import Foundation
import NIO

extension jlsftp.DataLayer.Version_3 {

	public class ExtendedPacketSerializationHandler: PacketSerializationHandler {

		public func deserialize(from buffer: inout ByteBuffer) -> Result<Packet, PacketSerializationHandlerError> {
			// Id
			guard let id = buffer.readInteger(endianness: .big, as: UInt32.self) else {
				return .failure(.needMoreData)
			}

			// Extended Request
			let extendedRequestResult = buffer.readSftpString()
			guard case let .success(extendedRequest) = extendedRequestResult else {
				return .failure(extendedRequestResult.error!.customMapError(wrapper: "Failed to deserialize extended request"))
			}

			return .success(.extended(ExtendedPacket(id: id, extendedRequest: extendedRequest)))
		}

		public func serialize(packet: Packet, to buffer: inout ByteBuffer) -> Bool {
			guard case let .extended(extendedPacket) = packet else {
				return false
			}

			// Id
			buffer.writeInteger(extendedPacket.id, endianness: .big, as: UInt32.self)

			// Extended Request
			guard buffer.writeSftpString(extendedPacket.extendedRequest) else {
				return false
			}

			return true
		}
	}
}
