import Foundation
import NIO
import NIOSSH
import Logging

public class SftpClientBootstrapper {

	public enum ClientError: Error {
		case invalidChannelType
	}

	public var userAuthDelegate: NIOSSHClientUserAuthenticationDelegate
	public var serverAuthDelegate: NIOSSHClientServerAuthenticationDelegate
	public let eventLoopGroup: EventLoopGroup
	public var logger: Logger

	public init(userAuthDelegate: NIOSSHClientUserAuthenticationDelegate,
				serverAuthDelegate: NIOSSHClientServerAuthenticationDelegate,
				eventLoopGroup: EventLoopGroup,
				logger: Logger) {
		self.userAuthDelegate = userAuthDelegate
		self.serverAuthDelegate = serverAuthDelegate
		self.eventLoopGroup = eventLoopGroup
		self.logger = logger
	}

	public func connect(host: String = "", port: Int = 22) -> EventLoopFuture<SftpClientConnection> {
		// Configure the bootstrapper for the base ssh connection
		let bootstrap = ClientBootstrap(group: eventLoopGroup)
			.channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
			.channelOption(ChannelOptions.allowRemoteHalfClosure, value: true)
			.channelInitializer { channel in
				// Use the injected delegates for authorization
				let clientConfig = SSHClientConfiguration(userAuthDelegate: self.userAuthDelegate,
														  serverAuthDelegate: self.serverAuthDelegate)
				// Add the ssh bootstrapping handler
				let sshHandler = NIOSSHHandler(role: .client(clientConfig),
											   allocator: channel.allocator,
											   inboundChildChannelInitializer: nil)
				return channel.pipeline.addHandler(sshHandler)
			}

		// Connect and, upon successful connection and ssh session, setup child
		// channel and handlers
		return bootstrap
			.connect(host: host, port: port)
			.flatMap { channel in
				return channel.pipeline.handler(type: NIOSSHHandler.self).flatMap { sshHandler in
					let promise = channel.eventLoop.makePromise(of: Channel.self)
					sshHandler.createChannel(promise, channelType: .session) { childChannel, channelType in
						guard channelType == .session else {
							return channel.eventLoop.makeFailedFuture(ClientError.invalidChannelType)
						}

						// Successfully created ssh session. Setup child
						// channel handlers
						return childChannel.pipeline.addHandlers([
							// To handle SSHChannelData <->ByteBuffer and
							// and init the sftp subsystem for ssh.
							SshSftpSubsystemClientHandler(),
							// To handle outgoing request encoding
							MessageToByteHandler(SftpPacketEncoder(serializer: jlsftp.SftpProtocol.Version_3.PacketSerializerV3(), allocator: childChannel.allocator)),
							// To handle incoming reply decoding
							ByteToMessageHandler(SftpPacketDecoder(packetSerializer: jlsftp.SftpProtocol.Version_3.PacketSerializerV3())),
							// To handle MessagePart <-> SftpMessage conversion
							// To bridge to the SftpClientConnection
//							SftpClientChannelHandler(),
							SftpClientChannelHandler2(logger: self.logger),
						])
					}

					// Once the child channel has been created, map it to a
					// SftpClientConnection and inject the channel into it.
					// This is what ultimately gets returned to the caller.
					return promise.futureResult.map { channel in
						// TODO: Change to init bootstrapper
						return BaseSftpClientConnection(version: .v3, channel: channel)
					}
				}
			}
	}
}
