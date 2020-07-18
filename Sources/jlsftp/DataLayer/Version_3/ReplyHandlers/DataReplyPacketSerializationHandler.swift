import Foundation

extension jlsftp.DataLayer.Version_3 {

	public class DataReplyPacketSerializationHandler: SftpVersion3PacketSerializationHandler {

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

			// Data
			let (optResultData, _) = sshProtocolSerialization.deserializeData(from: remainingDataAfterId)
			guard let resultData = optResultData else {
				return .failure(.payloadTooShort)
			}

			return .success(DataReplyPacket(id: id, data: resultData))
		}
	}
}
