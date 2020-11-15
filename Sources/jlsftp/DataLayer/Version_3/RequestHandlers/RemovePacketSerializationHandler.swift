import Foundation
import NIO

extension jlsftp.DataLayer.Version_3 {

	public class RemovePacketSerializationHandler: PacketSerializationHandler {

		public func deserialize(buffer: inout ByteBuffer) -> Result<Packet, PacketSerializationHandlerError> {
			// Id
			guard let id = buffer.readInteger(endianness: .big, as: UInt32.self) else {
				return .failure(.needMoreData)
			}

			// Filename
			let filenameResult = buffer.readSftpString()
			guard case let .success(filename) = filenameResult else {
				return .failure(filenameResult.error!.customMapError(wrapper: "Failed to deserialize filename"))
			}

			return .success(.remove(RemovePacket(id: id, filename: filename)))
		}
	}
}
