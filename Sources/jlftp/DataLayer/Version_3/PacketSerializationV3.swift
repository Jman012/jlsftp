import Foundation

public protocol SftpVersion3PacketSerializationHandler {
	/**
	 Deserializes the data payload of an sftp packet into the correct packet structure.

	 - Parameter data: The data payload from a `RawPacket`m in Network Byte
	 Order.
	 */
	func deserialize(fromPayload data: Data) -> Result<Packet, DeserializationError>
}

extension jlftp.DataLayer.Version_3 {

	public class PacketSerializationV3: PacketSerialization {

		let initializePacketSerialization: SftpVersion3PacketSerializationHandler
		let versionPacketSerialization: SftpVersion3PacketSerializationHandler

		public init(
			initializePacketSerialization: SftpVersion3PacketSerializationHandler,
			versionPacketSerialization: SftpVersion3PacketSerializationHandler
		) {
			self.initializePacketSerialization = initializePacketSerialization
			self.versionPacketSerialization = versionPacketSerialization
		}

		public func deserialize(rawPacket: RawPacket) -> Result<Packet, DeserializationError> {

			let packetTypeOpt = jlftp.DataLayer.Version_3.PacketType(rawValue: rawPacket.type)

			guard let packetType = packetTypeOpt else {
				return .failure(.invalidType)
			}

			switch packetType {
			case .initialize:
				return initializePacketSerialization.deserialize(fromPayload: rawPacket.dataPayload)

			case .version:
				return versionPacketSerialization.deserialize(fromPayload: rawPacket.dataPayload)

			default:
				return .failure(.invalidType)
			}
		}
	}
}
