import Foundation

extension jlsftp.DataLayer.Version_3 {

	public class RawPacketSerializationV3: RawPacketSerialization {

		let sshProtocolSerialization: SSHProtocolSerialization

		init(sshProtocolSerialization: SSHProtocolSerialization) {
			self.sshProtocolSerialization = sshProtocolSerialization
		}

		/**
		 Deserializes a data packet from the network stream into a `RawPacket`.

		 - Parameter data: The data to deserialize from the network stream, in Network
		 Byte Order.
		 */
		public func deserialize(from data: Data) -> Result<RawPacket, ParsingError> {
			// Can not parse empty data
			if data.isEmpty {
				return .failure(.noData)
			}

			// Parse length
			let (optLength, remainingDataAfterLength) = sshProtocolSerialization.deserializeUInt32(from: data)
			guard let length = optLength else {
				return .failure(.noLength)
			}

			// Do not parse outside the bounds of the inputted data, nor if
			// more data was supplied.
			if length != remainingDataAfterLength.count {
				return .failure(.lengthMismatch)
			}

			// Parse type
			let (optType, remainingDataAfterType) = sshProtocolSerialization.deserializeByte(from: remainingDataAfterLength)
			guard let type = optType else {
				return .failure(.noType)
			}

			// Data Payload
			let dataPayload = remainingDataAfterType
			guard !dataPayload.isEmpty else {
				return .failure(.noDataPayload)
			}

			return .success(RawPacket(length: length, type: type, dataPayload: dataPayload))
		}
	}
}
