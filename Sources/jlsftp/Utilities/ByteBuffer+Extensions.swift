import Foundation
import NIO

extension ByteBuffer {

	mutating func readSftpString() -> Result<String, PacketSerializationHandlerError> {
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
}
