import Foundation
import NIO

extension jlsftp.SftpProtocol.Version_3 {

	public class SetHandleStatusPacketSerializationHandler: PacketSerializationHandler {

		public func deserialize(from buffer: inout ByteBuffer) -> Result<Packet, PacketDeserializationHandlerError> {
			// Id
			guard let id = buffer.readInteger(endianness: .big, as: UInt32.self) else {
				return .failure(.needMoreData)
			}

			// Handle
			let handleResult = buffer.readSftpString()
			guard case let .success(handle) = handleResult else {
				return .failure(handleResult.error!.customMapError(wrapper: "Failed to deserialize path"))
			}

			// File Attributes
			let fileAttrsSerialization = FileAttributesSerializationV3()
			let fileAttrsResult = fileAttrsSerialization.deserialize(from: &buffer)
			guard case let .success(fileAttrs) = fileAttrsResult else {
				return .failure(fileAttrsResult.error!.customMapError(wrapper: "Failed to deserialize file attributes"))
			}

			return .success(.setHandleStatus(SetHandleStatusPacket(id: id, handle: handle, fileAttributes: fileAttrs)))
		}

		public func serialize(packet: Packet, to buffer: inout ByteBuffer) -> PacketSerializationHandlerError? {
			guard case let .setHandleStatus(setHandleStatusPacket) = packet else {
				return .wrongPacketInternalError
			}

			// Id
			buffer.writeInteger(setHandleStatusPacket.id, endianness: .big, as: UInt32.self)

			// Handle
			buffer.writeSftpString(setHandleStatusPacket.handle)

			// File Attributes
			let fileAttrsSerializationV3 = FileAttributesSerializationV3()
			fileAttrsSerializationV3.serialize(fileAttrs: setHandleStatusPacket.fileAttributes, to: &buffer)

			return nil
		}
	}
}
