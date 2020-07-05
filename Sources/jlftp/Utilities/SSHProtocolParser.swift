import Foundation

/**
 Parses data types found in in the RFC 4251 family of "SSH Protocol
 Architecture" documents, for use in sftp communication packets.
 */
public protocol SSHProtocolParser {
	func parseByte(from data: Data) -> (byte: UInt8?, remainingData: Data.SubSequence)
	func parseUInt32(from data: Data) -> (int: UInt32?, remainingData: Data.SubSequence)
	func parseUInt64(from data: Data) -> (int: UInt64?, remainingData: Data.SubSequence)
	func parseString(from data: Data) -> (string: String?, remainingData: Data.SubSequence)
}

/**
 Draft 9 of the "SSH Protocol Architecture" data type parser. See:
 https://tools.ietf.org/html/draft-ietf-secsh-architecture-09. Referenced in
 sftp version 3.
 */
public class SSHProtocolParserDraft9: SSHProtocolParser {

	public func parseByte(from data: Data) -> (byte: UInt8?, remainingData: Data.SubSequence) {
		let (byteData, remainingData) = data.split(maxLength: UInt8.byteWidth)
		guard byteData.count == UInt8.byteWidth else {
			return (nil, data)
		}

		return (byteData.to(UInt8.self, from: .networkOrder), remainingData)
	}

	public func parseUInt32(from data: Data) -> (int: UInt32?, remainingData: Data.SubSequence) {
		let (byteData, remainingData) = data.split(maxLength: UInt32.byteWidth)
		guard byteData.count == UInt32.byteWidth else {
			return (nil, data)
		}

		return (byteData.to(UInt32.self, from: .networkOrder), remainingData)
	}

	public func parseUInt64(from data: Data) -> (int: UInt64?, remainingData: Data.SubSequence) {
		let (byteData, remainingData) = data.split(maxLength: UInt64.byteWidth)
		guard byteData.count == UInt64.byteWidth else {
			return (nil, data)
		}

		return (byteData.to(UInt64.self, from: .networkOrder), remainingData)
	}

	public func parseString(from data: Data) -> (string: String?, remainingData: Data.SubSequence) {
		let (stringLengthOpt, remainingData) = self.parseUInt32(from: data)
		guard let stringLength = stringLengthOpt else {
			return (nil, data)
		}

		if stringLength == 0 {
			return ("", remainingData)
		}

		let (stringFieldData, remainingData2) = remainingData.split(maxLength: Int(stringLength))
		guard stringFieldData.count == stringLength else {
			return (nil, data)
		}

		let stringContents = String(bytes: stringFieldData, encoding: .utf8)
		return (stringContents, remainingData2)
	}
}
