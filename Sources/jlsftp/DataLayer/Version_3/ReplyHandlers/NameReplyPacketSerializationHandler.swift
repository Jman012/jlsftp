import Foundation
import NIO

extension jlsftp.DataLayer.Version_3 {

	public class NameReplyPacketSerializationHandler: PacketSerializationHandler {

		public func deserialize(buffer: inout ByteBuffer) -> Result<Packet, PacketSerializationHandlerError> {
			// Id
			guard let id = buffer.readInteger(endianness: .big, as: UInt32.self) else {
				return .failure(.needMoreData)
			}

			// Count
			guard let count = buffer.readInteger(endianness: .big, as: UInt32.self) else {
				return .failure(.needMoreData)
			}

			let fileAttrSerializationV3 = FileAttributesSerializationV3()
			var names: [NameReplyPacket.Name] = []
			for index in 0..<count {
				let filenameResult = buffer.readSftpString()
				guard case let .success(filename) = filenameResult else {
					return .failure(filenameResult.error!.customMapError(wrapper: "Failed to deserialize filename at index \(index)"))
				}

				let longNameResult = buffer.readSftpString()
				guard case let .success(longName) = longNameResult else {
					return .failure(longNameResult.error!.customMapError(wrapper: "Failed to deserialize longName at index \(index)"))
				}

				let fileAttrsResult = fileAttrSerializationV3.deserialize(from: &buffer)
				guard case let .success(fileAttrs) = fileAttrsResult else {
					return .failure(fileAttrsResult.error!.customMapError(wrapper: "Failed to deserialize file attributes at index \(index)"))
				}

				names.append(NameReplyPacket.Name(filename: filename, longName: longName, fileAttributes: fileAttrs))
			}

			return .success(.nameReply(NameReplyPacket(id: id, names: names)))
		}
	}
}
