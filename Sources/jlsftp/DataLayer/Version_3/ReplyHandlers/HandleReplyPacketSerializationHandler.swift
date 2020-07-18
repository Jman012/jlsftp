import Foundation

extension jlsftp.DataLayer.Version_3 {

	public class HandleReplyPacketSerializationHandler: SftpVersion3PacketSerializationHandler {

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

			// Handle
			let (optHandle, _) = sshProtocolSerialization.deserializeString(from: remainingDataAfterId)
			guard let handle = optHandle else {
				return .failure(.payloadTooShort)
			}

			return .success(HandleReplyPacket(id: id, handle: handle))
		}
	}
}
