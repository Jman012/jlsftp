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
	var bootstrappedServer: SftpServer?

	public init?(logger: Logger, versionedServers: [jlsftp.SftpProtocol.SftpVersion: SftpServer]) {
		if versionedServers.isEmpty {
			logger.critical("Could not initialize \(Self.Type.self): versionedServers is empty")
			return nil
		}
		if versionedServers.keys.min()! != jlsftp.SftpProtocol.SftpVersion.min {
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
		return versionedServers.keys.min()!
	}

	func maximumSupportedVersion() -> jlsftp.SftpProtocol.SftpVersion {
		return versionedServers.keys.max()!
	}
}

extension SftpServerInitialization: SftpServer {

	public func register(replyHandler: @escaping ReplyHandler) {
		self.replyHandler = replyHandler
		self.versionedServers.values.forEach {
			$0.register(replyHandler: replyHandler)
		}
	}

	public func handle(message: SftpMessage, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
		guard let replyHandler = replyHandler else {
			preconditionFailure("In order to handle incoming sftp messages, a reply handler must be setup first, or else the server can not reply to the client.")
		}

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
				self.bootstrappedServer = versionedServers[lowestVersion]
				let versionReplyPacket: Packet = .version(VersionPacket(version: lowestVersion, extensionData: []))
				return replyHandler(SftpMessage(packet: versionReplyPacket, dataLength: 0, shouldReadHandler: { _ in }))

			case .initialized(version: _):
				// Client sent initialized packet when we're already initialized.
				logger.warning("Client sent initialization request after initialization was already complete. Requested version = \(initializePacketV3.version.rawValue)")
				// Do nothing, since we shouldn't reply with a version packet.
				return eventLoop.makeSucceededFuture(())
			}
		default:
			guard let server = self.bootstrappedServer else {
				let errorReplyPacket: Packet = .statusReply(.init(id: 0 /* TODO? */, statusCode: .badMessage, errorMessage: "An sftp message was received before proper sftp initialization was handled.", languageTag: "en-US"))
				return replyHandler(SftpMessage(packet: errorReplyPacket, dataLength: 0, shouldReadHandler: { _ in }))
			}
			return server.handle(message: message, on: eventLoop)
		}
	}
}
