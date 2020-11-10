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
			guard let statusCodeV3 = StatusCodeV3(rawValue: codeInt) else {
				return .failure(.invalidData(reason: "Failed to parse status code with value '\(codeInt)'"))
			}

			// Error Message
			let errorMessageResult = buffer.readSftpString()
			guard case let .success(errorMessage) = errorMessageResult else {
				return .failure(errorMessageResult.error!.customMapError(wrapper: "Failed to deserialize error message"))
			}

			// Language Tag
			let langTagResult = buffer.readSftpString()
			guard case let .success(langTag) = langTagResult else {
				return .failure(langTagResult.error!.customMapError(wrapper: "Failed to deserialize language tag"))
			}

			return .success(StatusReplyPacket(id: id, statusCode: statusCodeV3.statusCode, errorMessage: errorMessage, languageTag: langTag))
		}
	}
}
