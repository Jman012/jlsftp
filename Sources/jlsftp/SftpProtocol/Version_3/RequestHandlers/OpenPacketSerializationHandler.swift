import Foundation
import NIO

extension jlsftp.SftpProtocol.Version_3 {

	public class OpenPacketSerializationHandler: PacketSerializationHandler {

		public func deserialize(from buffer: inout ByteBuffer) -> Result<Packet, PacketDeserializationHandlerError> {
			// Id
			guard let id = buffer.readInteger(endianness: .big, as: UInt32.self) else {
				return .failure(.needMoreData)
			}

			// Filename
			let filenameResult = buffer.readSftpString()
			guard case let .success(filename) = filenameResult else {
				return .failure(filenameResult.error!.customMapError(wrapper: "Failed to deserialize filename"))
			}

			// Open Flags
			guard let pflags = buffer.readInteger(endianness: .big, as: UInt32.self) else {
				return .failure(.needMoreData)
			}
			let openFlagsV3 = OpenFlagsV3(rawValue: UInt8(clamping: pflags))

			// File Attributes
			let fileAttrSerializationV3 = FileAttributesSerializationV3()
			let fileAttrResult = fileAttrSerializationV3.deserialize(from: &buffer)
			guard case let .success(fileAttrs) = fileAttrResult else {
				return .failure(fileAttrResult.error!)
			}

			return .success(.open(OpenPacket(id: id, filename: filename, pflags: openFlagsV3.openFlags, fileAttributes: fileAttrs)))
		}

		public func serialize(packet: Packet, to buffer: inout ByteBuffer) -> PacketSerializationHandlerError? {
			guard case let .open(openPacket) = packet else {
				return .wrongPacketInternalError
			}

			// Id
			buffer.writeInteger(openPacket.id, endianness: .big, as: UInt32.self)

			// Filename
			buffer.writeSftpString(openPacket.filename)

			// Open Flags
			let openFlagsV3 = OpenFlagsV3(openFlags: openPacket.pflags)
			buffer.writeInteger(UInt32(openFlagsV3.rawValue), endianness: .big, as: UInt32.self)

			// File Attributes
			let fileAttrSerializationV3 = FileAttributesSerializationV3()
			fileAttrSerializationV3.serialize(fileAttrs: openPacket.fileAttributes, to: &buffer)

			return nil
		}
	}
}
