import Foundation
import NIO

extension ByteBuffer {

	mutating func readSftpString() -> Result<String, PacketDeserializationHandlerError> {
		guard let length = self.readInteger(endianness: .big, as: UInt32.self) else {
			return .failure(.needMoreData)
		}

		guard let bytes = self.readBytes(length: Int(length)) else {
			return .failure(.needMoreData)
		}

		// SSH protocol dictates UTF-8/ASCII encoding
		guard let string = String(bytes: bytes, encoding: .utf8) else {
			return .failure(.invalidData(reason: "Invalid UTF8 string data"))
		}

		return .success(string)
	}

	mutating func writeSftpString(_ value: String) {
		let bytes = Array(value.utf8)
		precondition(UInt32(exactly: bytes.count) != nil, "A string object could not be sent over the wire, as it is too large.")
		let bytesCount = UInt32(exactly: bytes.count)!

		self.writeInteger(bytesCount, endianness: .big, as: UInt32.self)
		self.writeBytes(bytes)
	}
}
