import Foundation
import NIO

extension jlsftp.SftpProtocol.Version_3 {

	public class FileAttributesReplyPacketSerializationHandler: PacketSerializationHandler {

		public func deserialize(from buffer: inout ByteBuffer) -> Result<Packet, PacketDeserializationHandlerError> {
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

			return .success(.attributesReply(FileAttributesReplyPacket(id: id, fileAttributes: fileAttrs)))
		}

		public func serialize(packet: Packet, to buffer: inout ByteBuffer) -> PacketSerializationHandlerError? {
			guard case let .attributesReply(fileAttrsPacket) = packet else {
				return .wrongPacketInternalError
			}

			// Id
			buffer.writeInteger(fileAttrsPacket.id, endianness: .big, as: UInt32.self)

			// File Attributes
			let fileAttrsSerialization = FileAttributesSerializationV3()
			fileAttrsSerialization.serialize(fileAttrs: fileAttrsPacket.fileAttributes, to: &buffer)

			return nil
		}
	}
}
