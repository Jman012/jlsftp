import Foundation
import NIO

extension jlsftp.SftpProtocol.Version_3 {

	public class NameReplyPacketSerializationHandler: PacketSerializationHandler {

		public func deserialize(from buffer: inout ByteBuffer) -> Result<Packet, PacketDeserializationHandlerError> {
			// Id
			guard let id = buffer.readInteger(endianness: .big, as: UInt32.self) else {
				return .failure(.needMoreData)
			}

			// Names Count
			guard let count = buffer.readInteger(endianness: .big, as: UInt32.self) else {
				return .failure(.needMoreData)
			}

			let fileAttrSerializationV3 = FileAttributesSerializationV3()
			var names: [NameReplyPacket.Name] = []
			for index in 0..<count {
				// Filename
				let filenameResult = buffer.readSftpString()
				guard case let .success(filename) = filenameResult else {
					return .failure(filenameResult.error!.customMapError(wrapper: "Failed to deserialize filename at index \(index)"))
				}

				// Long Name
				let longNameResult = buffer.readSftpString()
				guard case let .success(longName) = longNameResult else {
					return .failure(longNameResult.error!.customMapError(wrapper: "Failed to deserialize longName at index \(index)"))
				}

				// File Attributes
				let fileAttrsResult = fileAttrSerializationV3.deserialize(from: &buffer)
				guard case let .success(fileAttrs) = fileAttrsResult else {
					return .failure(fileAttrsResult.error!.customMapError(wrapper: "Failed to deserialize file attributes at index \(index)"))
				}

				names.append(NameReplyPacket.Name(filename: filename, longName: longName, fileAttributes: fileAttrs))
			}

			return .success(.nameReply(NameReplyPacket(id: id, names: names)))
		}

		public func serialize(packet: Packet, to buffer: inout ByteBuffer) -> PacketSerializationHandlerError? {
			guard case let .nameReply(nameReplyPacket) = packet else {
				return .wrongPacketInternalError
			}

			// Id
			buffer.writeInteger(nameReplyPacket.id, endianness: .big, as: UInt32.self)

			// Names Count
			precondition(UInt32(exactly: nameReplyPacket.names.count) != nil,
						 "A name reply packet (SSH_FXP_NAME) could not be serialized: Too many names (above UInt32.max)") // Who has over 4 billion files in a folder?
			let namesCount = UInt32(exactly: nameReplyPacket.names.count)!
			buffer.writeInteger(namesCount, endianness: .big, as: UInt32.self)

			let fileAttrSerializationV3 = FileAttributesSerializationV3()
			for name in nameReplyPacket.names {
				// Filename
				buffer.writeSftpString(name.filename)
				// Long Name
				buffer.writeSftpString(name.longName)
				// File Attributes
				fileAttrSerializationV3.serialize(fileAttrs: name.fileAttributes, to: &buffer)
			}

			return nil
		}
	}
}
