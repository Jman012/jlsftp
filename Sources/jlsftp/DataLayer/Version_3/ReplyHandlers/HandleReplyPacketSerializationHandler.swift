import Foundation
import NIO

extension jlsftp.DataLayer.Version_3 {

	public class HandleReplyPacketSerializationHandler: PacketSerializationHandler {

		public func deserialize(buffer: inout ByteBuffer) -> Result<Packet, PacketSerializationHandlerError> {
			// Id
			guard let id = buffer.readInteger(endianness: .big, as: UInt32.self) else {
				return .failure(.needMoreData)
			}

			// Handle
			let handleResult = buffer.readSftpString()
			guard case let .success(handle) = handleResult else {
				return .failure(.invalidData(reason: "Failed to deserialize handle: \(handleResult.error!)"))
			}

			return .success(HandleReplyPacket(id: id, handle: handle))
		}
	}
}
