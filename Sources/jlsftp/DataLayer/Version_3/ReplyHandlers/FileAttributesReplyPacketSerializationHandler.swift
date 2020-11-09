import Foundation
import NIO

extension jlsftp.DataLayer.Version_3 {

	public class FileAttributesReplyPacketSerializationHandler: PacketSerializationHandler {

		public func deserialize(buffer: inout ByteBuffer) -> Result<Packet, PacketSerializationHandlerError> {
			// Id
			guard let id = buffer.readInteger(endianness: .big, as: UInt32.self) else {
				return .failure(.needMoreData)
			}

			// File Attributes
			let fileAttrSerializationV3 = FileAttributesSerializationV3()
			let fileAttrResult = fileAttrSerializationV3.deserialize(from: &buffer)

			guard case let .success(fileAttrs) = fileAttrResult else {
				return .failure(fileAttrResult.error!)
			}

			return .success(FileAttributesReplyPacket(id: id, fileAttributes: fileAttrs))
		}
	}
}
