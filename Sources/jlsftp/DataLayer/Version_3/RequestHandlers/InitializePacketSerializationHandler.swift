import Foundation
import NIO

extension jlsftp.DataLayer.Version_3 {

	public class InitializePacketSerializationHandler: PacketSerializationHandler {

		public func deserialize(from buffer: inout ByteBuffer) -> Result<Packet, PacketSerializationHandlerError> {
			// Version
			guard let versionByte = buffer.readInteger(endianness: .big, as: UInt32.self) else {
				return .failure(.needMoreData)
			}

			guard let sftpVersion = jlsftp.DataLayer.SftpVersion(rawValue: versionByte) else {
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

			return .success(.initializeV3(InitializePacketV3(version: sftpVersion, extensionData: extensionDataResults)))
		}

		public func serialize(packet: Packet, to buffer: inout ByteBuffer) -> Bool {
			guard case let .initializeV3(initializePacket) = packet else {
				return false
			}

			// Version
			buffer.writeInteger(initializePacket.version.rawValue, endianness: .big, as: UInt32.self)

			// Extension Data
			for extensionDatum in initializePacket.extensionData {
				// Extension Name
				guard buffer.writeSftpString(extensionDatum.name) else {
					return false
				}

				// Extension data
				guard buffer.writeSftpString(extensionDatum.data) else {
					return false
				}
			}

			return true
		}
	}
}
