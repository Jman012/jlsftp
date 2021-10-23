import Foundation
import NIO
import Logging

public class SftpClientInitialization {

	let logger: Logger
	/// Guaranteed in the init to start at 3 and be contiguous
	let versions: [jlsftp.SftpProtocol.SftpVersion]
	private let connectionFactory: SftpClientConnectionFactory

	public init?(logger: Logger, versions: [jlsftp.SftpProtocol.SftpVersion], connectionFactory: SftpClientConnectionFactory = DefaultConnectionFactory()) {
		if versions.isEmpty {
			logger.critical("Could not initialize \(Self.Type.self): versions is empty")
			return nil
		}
		if versions.min()! != jlsftp.SftpProtocol.SftpVersion.min {
			logger.critical("Could not initialize \(Self.Type.self): versions does not have a minimum version of 3")
			return nil
		}
		if !versions.map({ $0.rawValue }).elementsAreContiguous {
			logger.critical("Could not initialize \(Self.Type.self): versions is not a contiguous sequence; a gap in versions exists (\(versions.map({ $0.rawValue }).sorted())")
			return nil
		}

		self.logger = logger
		self.versions = versions
		self.connectionFactory = connectionFactory
	}

	func minimumSupportedVersion() -> jlsftp.SftpProtocol.SftpVersion {
		return versions.min()!
	}

	func maximumSupportedVersion() -> jlsftp.SftpProtocol.SftpVersion {
		return versions.max()!
	}

	public func initialize(channel: Channel) -> EventLoopFuture<SftpClientConnection> {
		let initializePacket: Packet = .initializeV3(.init(version: maximumSupportedVersion(), extensionData: []))
		let message = SftpMessage(packet: initializePacket, dataLength: 0, shouldReadHandler: { _ in })
		let clientRequest = ClientRequest(message: message, eventLoop: channel.eventLoop)
		channel.writeAndFlush(clientRequest, promise: nil)

		return clientRequest.responseFuture.map { response in
			switch response.packet {
			case let .version(packet):
				return self.connectionFactory.create(version: packet.version, channel: channel)
			default:
				// TODO:
				return self.connectionFactory.create(version: .v3, channel: channel)
			}
		}
	}
}
