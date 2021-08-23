import Foundation
import NIO
import NIOSSH

public class SftpClient {

	public enum ClientError: Error {
		case invalidChannelType
	}

	public var host: String
	public var port: Int
	public var userAuthDelegate: NIOSSHClientUserAuthenticationDelegate
	public var serverAuthDelegate: NIOSSHClientServerAuthenticationDelegate
	public let eventLoopGroup: EventLoopGroup

	public init(host: String,
				port: Int = 22,
				userAuthDelegate: NIOSSHClientUserAuthenticationDelegate,
				serverAuthDelegate: NIOSSHClientServerAuthenticationDelegate,
				eventLoopGroup: EventLoopGroup) {
		self.host = host
		self.port = port
		self.userAuthDelegate = userAuthDelegate
		self.serverAuthDelegate = serverAuthDelegate
		self.eventLoopGroup = eventLoopGroup
	}

	public func connect() -> EventLoopFuture<SftpClientConnection> {
		let bootstrap = ClientBootstrap(group: eventLoopGroup)
			.channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
			.channelOption(ChannelOptions.allowRemoteHalfClosure, value: true)
			.channelInitializer { channel in
				let clientConfig = SSHClientConfiguration(userAuthDelegate: self.userAuthDelegate,
														  serverAuthDelegate: self.serverAuthDelegate)
				return channel.pipeline.addHandlers([
					NIOSSHHandler(role: .client(clientConfig),
								  allocator: channel.allocator,
								  inboundChildChannelInitializer: nil),
				])
			}

		return bootstrap
			.connect(host: host, port: port)
			.flatMap { channel in
				return channel.pipeline.handler(type: NIOSSHHandler.self).flatMap { sshHandler in
					let promise = channel.eventLoop.makePromise(of: Channel.self)
					sshHandler.createChannel(promise, channelType: .session) { childChannel, channelType in
						guard channelType == .session else {
							return channel.eventLoop.makeFailedFuture(ClientError.invalidChannelType)
						}

						return childChannel.pipeline.addHandlers([
							ByteToMessageHandler(SftpPacketDecoder(packetSerializer: jlsftp.SftpProtocol.Version_3.PacketSerializerV3())),
							MessageToByteHandler(SftpPacketEncoder(serializer: jlsftp.SftpProtocol.Version_3.PacketSerializerV3(), allocator: childChannel.allocator)),
							SftpChannelHandler(),
							SftpClientChannelHandler(),
						])
					}
					return promise.futureResult.map { channel in
						return BaseSftpClientConnection(version: .v3, channel: channel)
					}
				}
			}
	}
}
