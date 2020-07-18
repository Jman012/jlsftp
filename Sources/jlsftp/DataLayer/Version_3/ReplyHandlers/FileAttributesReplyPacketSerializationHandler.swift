import Foundation

extension jlsftp.DataLayer.Version_3 {

	public class FileAttributesReplyPacketSerializationHandler: SftpVersion3PacketSerializationHandler {

		let sshProtocolSerialization: SSHProtocolSerialization

		init(sshProtocolSerialization: SSHProtocolSerialization) {
			self.sshProtocolSerialization = sshProtocolSerialization
		}

		public func deserialize(fromPayload data: Data) -> Result<Packet, DeserializationError> {
			// Id
			let (optId, remainingDataAfterId) = sshProtocolSerialization.deserializeUInt32(from: data)
			guard let id = optId else {
				return .failure(.payloadTooShort)
			}

			// File Attributes
			let fileAttrSerializationV3 = FileAttributesSerializationV3(sshProtocolSerialization: sshProtocolSerialization)
			let fileAttrResult = fileAttrSerializationV3.deserialize(from: remainingDataAfterId)
			switch fileAttrResult {
			case let .failure(.couldNotDeserialize(errorMsg)):
				return .failure(.invalidDataPayload(reason: "Could not parse file attributes: \(errorMsg)"))
			case let .success((fileAttrs, _)):
				return .success(FileAttributesReplyPacket(id: id, fileAttributes: fileAttrs))
			}
		}
	}
}
