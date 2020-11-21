import Foundation
import NIO

extension jlsftp.DataLayer.Version_3 {

	public class MakeDirectoryPacketSerializationHandler: PacketSerializationHandler {

		public func deserialize(buffer: inout ByteBuffer) -> Result<Packet, PacketSerializationHandlerError> {
			// Id
			guard let id = buffer.readInteger(endianness: .big, as: UInt32.self) else {
				return .failure(.needMoreData)
			}

			// Path
			let pathResult = buffer.readSftpString()
			guard case let .success(path) = pathResult else {
				return .failure(pathResult.error!.customMapError(wrapper: "Failed to deserialize path"))
			}

			// File Attributes
			let fileAttrsSerialization = FileAttributesSerializationV3()
			let fileAttrsResult = fileAttrsSerialization.deserialize(from: &buffer)
			guard case let .success(fileAttrs) = fileAttrsResult else {
				return .failure(fileAttrsResult.error!.customMapError(wrapper: "Failed to deserialize file attributes"))
			}

			return .success(.makeDirectory(MakeDirectoryPacket(id: id, path: path, fileAttributes: fileAttrs)))
		}

		public func serialize(packet: Packet, to buffer: inout ByteBuffer) -> Bool {
			guard case let .makeDirectory(makeDirectoryPacket) = packet else {
				return false
			}

			// Id
			buffer.writeInteger(makeDirectoryPacket.id, endianness: .big, as: UInt32.self)

			// Path
			guard buffer.writeSftpString(makeDirectoryPacket.path) else {
				return false
			}

			// File Attributes
			let fileAttrsSerialization = FileAttributesSerializationV3()
			guard fileAttrsSerialization.serialize(fileAttrs: makeDirectoryPacket.fileAttributes, to: &buffer) else {
				return false
			}

			return true
		}
	}
}
