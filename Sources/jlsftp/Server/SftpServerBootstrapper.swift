import Foundation
import NIO
import NIOSSH
import Logging

public class SftpServerBootstrapper {

	public enum ServerError: Error {
		case invalidChannelType
		case invalidConfiguration
	}

	public let host: String
	public let port: Int
	public let privateKey: NIOSSHPrivateKey
	public let serverUserAuthDelegate: NIOSSHServerUserAuthenticationDelegate
	public let eventLoopGroup: EventLoopGroup
	public let logger: Logger

	public init(host: String,
				port: Int = 22,
				privateKey: NIOSSHPrivateKey,
				serverUserAuthDelegate: NIOSSHServerUserAuthenticationDelegate,
				eventLoopGroup: EventLoopGroup,
				logger: Logger) {
		self.host = host
		self.port = port
		self.privateKey = privateKey
		self.serverUserAuthDelegate = serverUserAuthDelegate
		self.eventLoopGroup = eventLoopGroup
		self.logger = logger
	}

	public func bootstrap() -> EventLoopFuture<Channel> {
		logger.info("Bootstrapping sftp server on \(host):\(port)...")

		let childChannelInitializer: (Channel, SSHChannelType) -> EventLoopFuture<Void> = { channel, channelType in
			self.logger.debug("The NIOSSHHandler child channel was created. Adding channel handlers.")
			guard channelType == .session else {
				return channel.eventLoop.makeFailedFuture(ServerError.invalidChannelType)
			}

			guard let server = SftpServerInitialization(
				logger: self.logger,
				versionedServers: [
					.v3: BaseSftpServer(forVersion: .v3, threadPool: NIOThreadPool(numberOfThreads: 1), logger: self.logger),
				]
			) else {
				return channel.eventLoop.makeFailedFuture(ServerError.invalidConfiguration)
			}

			server.register(replyHandler: { message in
				return channel.writeAndFlush(message)
			})

			// Successfully created ssh session. Setup child
			// channel handlers
			return channel.pipeline.addHandlers([
				// To handle SSHChannelData <->ByteBuffer and
				// and init the sftp subsystem for ssh.
				SshSftpSubsystemServerHandler(),
				// To handle incoming reply decoding
				ByteToMessageHandler(SftpPacketDecoder(packetSerializer: jlsftp.SftpProtocol.Version_3.PacketSerializerV3())),
				// To handle outgoing request encoding
				MessageToByteHandler(SftpPacketEncoder(serializer: jlsftp.SftpProtocol.Version_3.PacketSerializerV3(), allocator: channel.allocator)),
				// To handle MessagePart <-> SftpMessage conversion
				SftpChannelHandler(),
				// To handle the incoming SftpMessages
				SftpServerChannelHandler(server: server),
			])
		}

		// Configure the bootstrapper for the base ssh connection
		let bootstrap = ServerBootstrap(group: eventLoopGroup)
			// Specify backlog and enable SO_REUSEADDR for the server itself
			.serverChannelOption(ChannelOptions.backlog, value: 256)
			.serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
			.childChannelInitializer { channel in
				self.logger.info("Client \(String(describing: channel.remoteAddress)) connected")
				// Use the injected delegates for authorization
				let serverConfig = SSHServerConfiguration(
					hostKeys: [self.privateKey],
					userAuthDelegate: self.serverUserAuthDelegate)
				// Add the ssh bootstrapping handler
				let sshHandler = NIOSSHHandler(role: .server(serverConfig),
											   allocator: channel.allocator,
											   inboundChildChannelInitializer: childChannelInitializer)
				return channel.pipeline.addHandler(sshHandler)
			}
			// Enable SO_REUSEADDR for the accepted Channels
			.childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
			.childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
			.childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())

		return bootstrap.bind(host: host, port: port)
	}
}
