import Foundation
import NIO

extension jlsftp.SftpProtocol.Version_3 {

	public class StatusReplyPacketSerializationHandler: PacketSerializationHandler {

		public func deserialize(from buffer: inout ByteBuffer) -> Result<Packet, PacketDeserializationHandlerError> {
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

			return .success(.statusReply(StatusReplyPacket(id: id, statusCode: statusCodeV3.statusCode, errorMessage: errorMessage, languageTag: langTag)))
		}

		public func serialize(packet: Packet, to buffer: inout ByteBuffer) -> PacketSerializationHandlerError? {
			guard case let .statusReply(statusReplyPacket) = packet else {
				return .wrongPacketInternalError
			}

			// Id
			buffer.writeInteger(statusReplyPacket.id, endianness: .big, as: UInt32.self)

			// Code
			buffer.writeInteger(StatusCodeV3(from: statusReplyPacket.statusCode).rawValue, endianness: .big, as: UInt32.self)

			// Error Message
			buffer.writeSftpString(statusReplyPacket.errorMessage)

			// Language Tag
			buffer.writeSftpString(statusReplyPacket.languageTag)

			return nil
		}
	}
}
