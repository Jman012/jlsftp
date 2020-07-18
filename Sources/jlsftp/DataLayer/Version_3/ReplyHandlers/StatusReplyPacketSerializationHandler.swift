import Foundation

extension jlsftp.DataLayer.Version_3 {

	public class StatusReplyPacketSerializationHandler: SftpVersion3PacketSerializationHandler {

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

			// Code
			let (optCode, remainingDataAfterCode) = sshProtocolSerialization.deserializeUInt32(from: remainingDataAfterId)
			guard let code = optCode else {
				return .failure(.payloadTooShort)
			}
			guard let errorStatusCode = ErrorStatusCodeV3(rawValue: code) else {
				return .failure(.invalidDataPayload(reason: "Could not parse the error status code with value '\(code)'"))
			}

			// Error Message
			let (optErrorMessage, remainingDataAfterMessage) = sshProtocolSerialization.deserializeString(from: remainingDataAfterCode)
			guard let errorMessage = optErrorMessage else {
				return .failure(.payloadTooShort)
			}

			// Language Tag
			let (optLangTag, _) = sshProtocolSerialization.deserializeString(from: remainingDataAfterMessage)
			guard let langTag = optLangTag else {
				return .failure(.payloadTooShort)
			}

			return .success(StatusReplyPacket(id: id, errorStatusCode: errorStatusCode.errorStatusCode, errorMessage: errorMessage, languageTag: langTag))
		}
	}
}
