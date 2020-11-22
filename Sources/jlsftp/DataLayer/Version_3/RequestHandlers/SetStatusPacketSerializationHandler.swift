import Foundation
import NIO

extension jlsftp.DataLayer.Version_3 {

	public class SetStatusPacketSerializationHandler: PacketSerializationHandler {

		public func deserialize(from buffer: inout ByteBuffer) -> Result<Packet, PacketSerializationHandlerError> {
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

			return .success(.setStatus(SetStatusPacket(id: id, path: path, fileAttributes: fileAttrs)))
		}

		public func serialize(packet: Packet, to buffer: inout ByteBuffer) -> Bool {
			guard case let .setStatus(setStatusPacket) = packet else {
				return false
			}

			// Id
			buffer.writeInteger(setStatusPacket.id, endianness: .big, as: UInt32.self)

			// Path
			guard buffer.writeSftpString(setStatusPacket.path) else {
				return false
			}

			// File Attributes
			let fileAttrsSerializationV3 = FileAttributesSerializationV3()
			guard fileAttrsSerializationV3.serialize(fileAttrs: setStatusPacket.fileAttributes, to: &buffer) else {
				return false
			}

			return true
		}
	}
}
