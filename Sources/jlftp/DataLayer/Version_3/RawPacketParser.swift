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

		/**
		 Parses a data packet from the network stream into a `RawPacket`.

		 - Parameter data: The data to parse from the network stream, in Network
		 Byte Order.
		 */
		public func parseData(from data: Data) -> Result<RawPacket, ParsingError> {
			if data.isEmpty {
				return .failure(.noData)
			}

			// Requires at least 4 bytes to read the `length`.
			if data.count < 4 {
				return .failure(.noLength)
			}

			// Requires at least 4 bytes to read the `length`.
			// Requires 1 more byte to read the `type`.
			if data.count < 5 {
				return .failure(.noType)
			}

			// Parse length
			let length: UInt32 = data.subdata(in: 0..<4).to(UInt32.self, from: .networkOrder)!
			if length == 0 || length == 1 {
				return .failure(.noDataPayload)
			}

			// Do not parse outside the bounds of the inputted data, nor if
			// more data was supplied.
			if (length + 4) != data.count {
				return .failure(.lengthMismatch)
			}

			// Parse type
			let type: UInt8 = data[4]

			// Retrieve data payload
			let dataPayload = data.subdata(in: 5..<data.count)

			return .success(RawPacket(length: length, type: type, dataPayload: dataPayload))
		}
	}
}
