import Foundation
import NIO

public protocol PacketSerializer {
	func deserialize(packetType: jlsftp.DataLayer.PacketType, buffer: inout ByteBuffer) -> Result<Packet, PacketSerializationHandlerError>
	func serialize(packet: Packet, to buffer: inout ByteBuffer) -> Bool
}

public class BasePacketSerializer {

	let handlers: [jlsftp.DataLayer.PacketType: PacketSerializationHandler]
	let unhandledTypeHandler: PacketSerializationHandler

	public init(
		handlers: [jlsftp.DataLayer.PacketType: PacketSerializationHandler],
		unhandledTypeHandler: PacketSerializationHandler
	) {
		self.handlers = handlers
		self.unhandledTypeHandler = unhandledTypeHandler
	}

	public static func createSerializer(fromSftpVersion sftpVersion: jlsftp.DataLayer.SftpVersion) -> BasePacketSerializer {
		let notSupportedHandler = NotSupportedPacketSerializationHandler()

		switch sftpVersion {
		case .v3:
			return jlsftp.DataLayer.Version_3.PacketSerializerV3()
		case .v4:
			return BasePacketSerializer(handlers: [
				.initialize: jlsftp.DataLayer.Version_3.InitializePacketSerializationHandler(),
				.version: jlsftp.DataLayer.Version_3.VersionPacketSerializationHandler(),
			], unhandledTypeHandler: notSupportedHandler)
		case .v5:
			return BasePacketSerializer(handlers: [
				.initialize: jlsftp.DataLayer.Version_3.InitializePacketSerializationHandler(),
				.version: jlsftp.DataLayer.Version_3.VersionPacketSerializationHandler(),
			], unhandledTypeHandler: notSupportedHandler)
		case .v6:
			return BasePacketSerializer(handlers: [
				.initialize: jlsftp.DataLayer.Version_3.InitializePacketSerializationHandler(),
				.version: jlsftp.DataLayer.Version_3.VersionPacketSerializationHandler(),
			], unhandledTypeHandler: notSupportedHandler)
		}
	}
}

extension BasePacketSerializer: PacketSerializer {

	public func deserialize(packetType: jlsftp.DataLayer.PacketType, buffer: inout ByteBuffer) -> Result<Packet, PacketSerializationHandlerError> {

		guard let handler = handlers[packetType] else {
			return unhandledTypeHandler.deserialize(from: &buffer)
		}

		return handler.deserialize(from: &buffer)
	}

	public func serialize(packet: Packet, to buffer: inout ByteBuffer) -> Bool {

		guard let packetType = packet.packetType else {
			return false
		}

		guard let handler = handlers[packetType] else {
			return false
		}

		return handler.serialize(packet: packet, to: &buffer)
	}
}
