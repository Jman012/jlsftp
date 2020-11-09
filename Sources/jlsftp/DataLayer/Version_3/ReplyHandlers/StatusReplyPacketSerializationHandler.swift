import Foundation
import NIO

extension jlsftp.DataLayer.Version_3 {

	public class StatusReplyPacketSerializationHandler: PacketSerializationHandler {

		public func deserialize(buffer: inout ByteBuffer) -> Result<Packet, PacketSerializationHandlerError> {
			// Id
			guard let id = buffer.readInteger(endianness: .big, as: UInt32.self) else {
				return .failure(.needMoreData)
			}

			// Code
			guard let codeInt = buffer.readInteger(endianness: .big, as: UInt32.self) else {
				return .failure(.needMoreData)
			}
			guard let errorStatusCode = ErrorStatusCodeV3(rawValue: codeInt) else {
				return .failure(.invalidData(reason: "Failed to parse error status code with value '\(codeInt)'"))
			}

			// Error Message
			let errorMessageResult = buffer.readSftpString()
			guard case let .success(errorMessage) = errorMessageResult else {
				return .failure(.invalidData(reason: "Failed to deserialize error message: \(errorMessageResult.error!)"))
			}

			// Language Tag
			let langTagResult = buffer.readSftpString()
			guard case let .success(langTag) = langTagResult else {
				return .failure(.invalidData(reason: "Failed to deserialize language tag: \(langTagResult.error!)"))
			}

			return .success(StatusReplyPacket(id: id, errorStatusCode: errorStatusCode.errorStatusCode, errorMessage: errorMessage, languageTag: langTag))
		}
	}
}
