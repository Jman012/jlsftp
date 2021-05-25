import Foundation
import Logging
import NIO

public class SftpServerInitialization {

	enum State {
		case awaitingInitialization
		case initialized(version: jlsftp.SftpProtocol.SftpVersion, handler: SftpServer)
	}

	var state: State = .awaitingInitialization
	var replyHandler: ReplyHandler?

	let logger: Logger
	/// Guaranteed in the init to start at 3 and be contiguous
	let versionedServers: [jlsftp.SftpProtocol.SftpVersion: SftpServer]

	public init?(logger: Logger, versionedServers: [jlsftp.SftpProtocol.SftpVersion: SftpServer]) {
		if versionedServers.isEmpty {
			logger.critical("Could not initialize \(Self.Type.self): versionedServers is empty")
			return nil
		}
		if versionedServers.keys.min()! != .v3 {
			logger.critical("Could not initialize \(Self.Type.self): versionedServers does not have a minimum version of 3")
			return nil
		}
		if !versionedServers.keys.map({ $0.rawValue }).elementsAreContiguous {
			logger.critical("Could not initialize \(Self.Type.self): versionedServers is not a contiguous sequence; a gap in versions exists (\(versionedServers.keys.map({ $0.rawValue }).sorted())")
			return nil
		}

		self.logger = logger
		self.versionedServers = versionedServers
	}

	func minimumSupportedVersion() -> jlsftp.SftpProtocol.SftpVersion {
		return versionedServers.keys.sorted().min()!
	}

	func maximumSupportedVersion() -> jlsftp.SftpProtocol.SftpVersion {
		return versionedServers.keys.sorted().max()!
	}
}

extension SftpServerInitialization: SftpServer {

	public func register(replyHandler: @escaping ReplyHandler) {
		self.replyHandler = replyHandler
		self.versionedServers.values.forEach {
			$0.register(replyHandler: replyHandler)
		}
	}

	public func handle(message: SftpMessage, on _: EventLoop) {
		logger.trace("\(Self.Type.self) handling packet: \(message.packet)")

		switch message.packet {
		case let .initializeV3(initializePacketV3):
			switch state {
			case .awaitingInitialization:
				// Client has sent their Version for standard initialization.
				// Reply with the lowest of Client's and our version.
				let lowestVersion = min(initializePacketV3.version, maximumSupportedVersion())
				self.state = .initialized(version: lowestVersion, handler: self.versionedServers[lowestVersion]!)
				logger.info("Initiated SFTP session at version \(lowestVersion.rawValue) (client=\(initializePacketV3.version.rawValue), server=\(maximumSupportedVersion().rawValue))")
				self.replyHandler?(.version(VersionPacket(version: lowestVersion, extensionData: [])))

			case .initialized(version: _):
				// Client sent initialized packet when we're already initialized.
				logger.warning("Client sent initialization request after initialization was already complete. Requested version = \(initializePacketV3.version.rawValue)")
				// Do nothing, since we shouldn't reply with a version packet.
			}
		default:

			break
		}
	}
}
