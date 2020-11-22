import Foundation
import NIO

extension jlsftp.SftpProtocol.Version_3 {

	public class VersionPacketSerializationHandler: PacketSerializationHandler {

		public func deserialize(from buffer: inout ByteBuffer) -> Result<Packet, PacketDeserializationHandlerError> {
			// Version
			guard let versionByte = buffer.readInteger(endianness: .big, as: UInt32.self) else {
				return .failure(.needMoreData)
			}

			guard let sftpVersion = jlsftp.SftpProtocol.SftpVersion(rawValue: versionByte) else {
				return .failure(.invalidData(reason: "Version field \(versionByte) is not supported."))
			}

			// Rest of the data: extension data of the form of pairs of strings
			var extensionDataResults: [ExtensionData] = []
			var index = 0
			while buffer.readableBytes > 0 {
				let extensionNameResult = buffer.readSftpString()
				guard case let .success(extensionName) = extensionNameResult else {
					return .failure(extensionNameResult.error!.customMapError(wrapper: "Failed to deserialize extension name at index \(index)"))
				}

				let extensionDataResult = buffer.readSftpString()
				guard case let .success(extensionData) = extensionDataResult else {
					return .failure(extensionDataResult.error!.customMapError(wrapper: "Failed to deserialize extension data at index \(index)"))
				}

				extensionDataResults.append(ExtensionData(name: extensionName, data: extensionData))
				index += 1
			}

			return .success(.version(VersionPacket(version: sftpVersion, extensionData: extensionDataResults)))
		}

		public func serialize(packet: Packet, to buffer: inout ByteBuffer) -> PacketSerializationHandlerError? {
			guard case let .version(versionPacket) = packet else {
				return .wrongPacketInternalError
			}

			// Version
			buffer.writeInteger(versionPacket.version.rawValue, endianness: .big, as: UInt32.self)

			// Extension Data
			for extensionDatum in versionPacket.extensionData {
				// Extension Name
				buffer.writeSftpString(extensionDatum.name)

				// Extension data
				buffer.writeSftpString(extensionDatum.data)
			}

			return nil
		}
	}
}
