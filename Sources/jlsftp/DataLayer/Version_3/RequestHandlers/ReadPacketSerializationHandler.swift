import Foundation
import NIO

extension jlsftp.DataLayer.Version_3 {

	public class ReadPacketSerializationHandler: PacketSerializationHandler {

		public func deserialize(buffer: inout ByteBuffer) -> Result<Packet, PacketSerializationHandlerError> {
			// Id
			guard let id = buffer.readInteger(endianness: .big, as: UInt32.self) else {
				return .failure(.needMoreData)
			}

			// Handle
			let handleResult = buffer.readSftpString()
			guard case let .success(handle) = handleResult else {
				return .failure(handleResult.error!.customMapError(wrapper: "Failed to deserialize handle"))
			}

			// Offset
			guard let offset = buffer.readInteger(endianness: .big, as: UInt64.self) else {
				return .failure(.needMoreData)
			}

			// Length
			guard let length = buffer.readInteger(endianness: .big, as: UInt32.self) else {
				return .failure(.needMoreData)
			}

			return .success(ReadPacket(id: id, handle: handle, offset: offset, length: length))
		}
	}
}
