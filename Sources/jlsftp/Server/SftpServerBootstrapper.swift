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
	public let serverUserAuthDelegate: NIOSSHServerUserAuthenticationDelegate
	public let eventLoopGroup: EventLoopGroup
	public let logger: Logger

	public init(host: String,
				port: Int = 22,
				serverUserAuthDelegate: NIOSSHServerUserAuthenticationDelegate,
				eventLoopGroup: EventLoopGroup,
				logger: Logger) {
		self.host = host
		self.port = port
		self.serverUserAuthDelegate = serverUserAuthDelegate
		self.eventLoopGroup = eventLoopGroup
		self.logger = logger
	}

	public func bootstrap() -> EventLoopFuture<Channel> {
		// Configure the bootstrapper for the base ssh connection
		let bootstrap = ServerBootstrap(group: eventLoopGroup)
			// Specify backlog and enable SO_REUSEADDR for the server itself
			.serverChannelOption(ChannelOptions.backlog, value: 256)
			.serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
			.childChannelInitializer { channel in
				// Use the injected delegates for authorization
				let serverConfig = SSHServerConfiguration(
					hostKeys: [],
					userAuthDelegate: self.serverUserAuthDelegate)
				// Add the ssh bootstrapping handler
				let sshHandler = NIOSSHHandler(role: .server(serverConfig),
											   allocator: channel.allocator,
											   inboundChildChannelInitializer: nil)
				return channel.pipeline.addHandler(sshHandler)
			}
			// Enable SO_REUSEADDR for the accepted Channels
			.childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
			.childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
			.childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())

		// Connect and, upon successful connection and ssh session, setup child
		// channel and handlers
		return bootstrap
			.bind(host: host, port: port)
			.flatMap { channel in
				return channel.pipeline.handler(type: NIOSSHHandler.self).flatMap { sshHandler in
					let promise = channel.eventLoop.makePromise(of: Channel.self)
					sshHandler.createChannel(promise, channelType: .session) { childChannel, channelType in
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

						// Successfully created ssh session. Setup child
						// channel handlers
						return childChannel.pipeline.addHandlers([
							// To handle SSHChannelData <->ByteBuffer and
							// and init the sftp subsystem for ssh.
							SshSftpSubsystemServerHandler(),
							// To handle incoming reply decoding
							ByteToMessageHandler(SftpPacketDecoder(packetSerializer: jlsftp.SftpProtocol.Version_3.PacketSerializerV3())),
							// To handle outgoing request encoding
							MessageToByteHandler(SftpPacketEncoder(serializer: jlsftp.SftpProtocol.Version_3.PacketSerializerV3(), allocator: childChannel.allocator)),
							// To handle MessagePart <-> SftpMessage conversion
							SftpChannelHandler(),
							// To handle the incoming SftpMessages
							SftpServerChannelHandler(server: server),
						])
					}

					return promise.futureResult
				}
			}
	}
}
