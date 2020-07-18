import Foundation

extension jlsftp.DataLayer.Version_3 {

	public class NameReplyPacketSerializationHandler: SftpVersion3PacketSerializationHandler {

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

			// Count
			let (optCount, remainingDataAfterCount) = sshProtocolSerialization.deserializeUInt32(from: remainingDataAfterId)
			guard let count = optCount else {
				return .failure(.payloadTooShort)
			}

			let fileAttrSerializationV3 = FileAttributesSerializationV3(sshProtocolSerialization: sshProtocolSerialization)
			var remainingData: Data = remainingDataAfterCount
			var names: [NameReplyPacket.Name] = []
			for index in 0..<count {
				var optFilename, optLongName: String?

				(optFilename, remainingData) = sshProtocolSerialization.deserializeString(from: remainingData)
				guard let filename = optFilename else {
					return .failure(.payloadTooShort)
				}

				(optLongName, remainingData) = sshProtocolSerialization.deserializeString(from: remainingData)
				guard let longName = optLongName else {
					return .failure(.payloadTooShort)
				}

				let fileAttrsResult = fileAttrSerializationV3.deserialize(from: remainingData)
				switch fileAttrsResult {
				case let .failure(.couldNotDeserialize(errorMsg)):
					return .failure(.invalidDataPayload(reason: "Could not parse file attributes at index '\(index)': \(errorMsg)"))
				case let .success((fileAttrs, remainingDataAfterFileAttrs)):
					remainingData = remainingDataAfterFileAttrs
					names.append(NameReplyPacket.Name(filename: filename, longName: longName, fileAttributes: fileAttrs))
				}
			}

			return .success(NameReplyPacket(id: id, names: names))
		}
	}
}
