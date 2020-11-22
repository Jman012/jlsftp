import Foundation
import NIO

extension jlsftp.SftpProtocol.Version_3 {

	public class FileAttributesReplyPacketSerializationHandler: PacketSerializationHandler {

		public func deserialize(from buffer: inout ByteBuffer) -> Result<Packet, PacketSerializationHandlerError> {
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

		public func serialize(packet: Packet, to buffer: inout ByteBuffer) -> Bool {
			guard case let .attributesReply(fileAttrsPacket) = packet else {
				return false
			}

			// Id
			buffer.writeInteger(fileAttrsPacket.id, endianness: .big, as: UInt32.self)

			// File Attributes
			let fileAttrsSerialization = FileAttributesSerializationV3()
			guard fileAttrsSerialization.serialize(fileAttrs: fileAttrsPacket.fileAttributes, to: &buffer) else {
				return false
			}

			return true
		}
	}
}
