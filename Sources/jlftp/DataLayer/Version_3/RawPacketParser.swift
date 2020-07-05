import Foundation

extension jlftp.DataLayer.Version_3 {

	public class RawPacketParser {

		public enum ParsingError: Error {
			/// Input data is empty.
			case noData
			/// There is not enough data to parse the length field.
			case noLength
			/// There is not enough data to parse the type field.
			case noType
			/// There is no payload associated with the packet (length is 0).
			case noDataPayload
			/// The overall size of the given data does not match the reported length of the payload.
			case lengthMismatch
		}

		let sshProtocolParser: SSHProtocolParser

		init(sshProtocolParser: SSHProtocolParser) {
			self.sshProtocolParser = sshProtocolParser
		}

		/**
		 Parses a data packet from the network stream into a `RawPacket`.

		 - Parameter data: The data to parse from the network stream, in Network
		 Byte Order.
		 */
		public func parseData(from data: Data) -> Result<RawPacket, ParsingError> {
			// Can not parse empty data
			if data.isEmpty {
				return .failure(.noData)
			}

			// Parse length
			let (optLength, remainingDataAfterLength) = sshProtocolParser.parseUInt32(from: data)
			guard let length = optLength else {
				return .failure(.noLength)
			}

			// Do not parse outside the bounds of the inputted data, nor if
			// more data was supplied.
			if length != remainingDataAfterLength.count {
				return .failure(.lengthMismatch)
			}

			// Parse type
			let (optType, remainingDataAfterType) = sshProtocolParser.parseByte(from: remainingDataAfterLength)
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
