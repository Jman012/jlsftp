import Foundation
import NIO
import NIOSSH
import jlsftp

class SSHToSFTPHander: ChannelDuplexHandler {
	typealias InboundIn = SSHChannelData
	typealias InboundOut = ByteBuffer
	typealias OutboundIn = ByteBuffer
	typealias OutboundOut = SSHChannelData

	func channelActive(context: ChannelHandlerContext) {
		context.triggerUserOutboundEvent(SSHChannelRequestEvent.SubsystemRequest(subsystem: "sftp", wantReply: true))
			.whenSuccess {
				// Init (v3)
				context.write(self.wrapOutboundOut(SSHChannelData(type: .channel, data: .byteBuffer(ByteBuffer(bytes: [
					0x00, 0x00, 0x00, 0x05,
					0x01,
					0x00, 0x00, 0x00, 0x03,
				])))))
				context.flush()
				// Open dir to get back a handle
				context.write(self.wrapOutboundOut(SSHChannelData(type: .channel, data: .byteBuffer(ByteBuffer(bytes: [
					// Length: 10
					0x00, 0x00, 0x00, 0x0A,
					// Type: 11
					0x0B,
					// id
					0x00, 0x00, 0x00, 0x10,
					// path length
					0x00, 0x00, 0x00, 0x01,
					// path "."
					0x2E,
//					0x2f, 0x55, 0x73, 0x65, 0x72, 0x73, 0x2f, 0x6a, 0x61, 0x6d, 0x65, 0x73,
				])))))
				context.flush()
			}
	}

	func userInboundEventTriggered(context _: ChannelHandlerContext, event: Any) {
		print("userInboundEventTriggered event: \(event)")
	}

	func channelRead(context _: ChannelHandlerContext, data: NIOAny) {
		let channelData = self.unwrapInboundIn(data)
		print("channelRead channelData: \(channelData)")
		guard case let .byteBuffer(buffer) = channelData.data else {
			preconditionFailure()
		}

		let bytes = buffer.getBytes(at: buffer.readerIndex, length: buffer.readableBytes)
		print(bytes!.reduce("") { $0 + String(format: "%02x ", $1) })
	}
}

class ClientChannelHandler: ChannelInboundHandler {
	typealias InboundIn = MessagePart
	typealias OutboundOut = MessagePart

	public func channelActive(context: ChannelHandlerContext) {
		print("channelActive. sending init")
		let request = InitializePacketV3(version: .v3, extensionData: [])
		_ = context.write(self.wrapOutboundOut(.header(.initializeV3(request), 0)))
		context.flush()
	}

	public func channelRead(context _: ChannelHandlerContext, data: NIOAny) {
		// As we are not really interested getting notified on success or failure we just pass nil as promise to
		// reduce allocations.
		let messagePart = self.unwrapInboundIn(data)
		print("channelRead: \(messagePart)")
	}

	// Flush it out. This can make use of gathering writes if multiple buffers are pending
	public func channelReadComplete(context: ChannelHandlerContext) {
		context.flush()
	}

	public func errorCaught(context: ChannelHandlerContext, error: Error) {
		print("error: ", error)

		// As we are not really interested getting notified on success or failure we just pass nil as promise to
		// reduce allocations.
		context.close(promise: nil)
	}
}

enum SSHClientError: Swift.Error {
	case passwordAuthenticationNotSupported
	case commandExecFailed
	case invalidChannelType
	case invalidData
}

final class InteractivePasswordPromptDelegate: NIOSSHClientUserAuthenticationDelegate {
	private let queue: DispatchQueue

	private var username: String?

	private var password: String?

	init(username: String?, password: String?) {
		self.queue = DispatchQueue(label: "io.swiftnio.ssh.InteractivePasswordPromptDelegate")
		self.username = username
		self.password = password
	}

	func nextAuthenticationType(availableMethods: NIOSSHAvailableUserAuthenticationMethods, nextChallengePromise: EventLoopPromise<NIOSSHUserAuthenticationOffer?>) {
		guard availableMethods.contains(.password) else {
			print("Error: password auth not supported")
			nextChallengePromise.fail(SSHClientError.passwordAuthenticationNotSupported)
			return
		}

		self.queue.async {
			if self.username == nil {
				print("Username: ", terminator: "")
				self.username = readLine() ?? ""
			}

			if self.password == nil {
				#if os(Windows)
				print("Password: ", terminator: "")
				self.password = readLine() ?? ""
				#else
				self.password = String(cString: getpass("Password: "))
				#endif
			}

			nextChallengePromise.succeed(NIOSSHUserAuthenticationOffer(username: self.username!, serviceName: "", offer: .password(.init(password: self.password!))))
		}
	}
}

final class AcceptAllHostKeysDelegate: NIOSSHClientServerAuthenticationDelegate {
	func validateHostKey(hostKey _: NIOSSHPublicKey, validationCompletePromise: EventLoopPromise<Void>) {
		// Do not replicate this in your own code: validate host keys! This is a
		// choice made for expedience, not for any other reason.
		validationCompletePromise.succeed(())
	}
}

let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
let bootstrap = ClientBootstrap(group: group)
	.channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
	.channelOption(ChannelOptions.allowRemoteHalfClosure, value: true)
	.channelInitializer { channel in
		channel.pipeline.addHandlers([
			// SSH
			NIOSSHHandler(role: .client(SSHClientConfiguration(userAuthDelegate: InteractivePasswordPromptDelegate(username: nil, password: nil),
															   serverAuthDelegate: AcceptAllHostKeysDelegate())),
			allocator: channel.allocator,
			inboundChildChannelInitializer: nil),
//			ByteToMessageHandler(SftpPacketDecoder(packetSerializer: BasePacketSerializer.createSerializer(fromSftpVersion: .v3))),
			// Server outbould
//			MessageToByteHandler(SftpPacketEncoder(serializer: BasePacketSerializer.createSerializer(fromSftpVersion: .v3),
//												   allocator: channel.allocator)),
			// End
//			ClientChannelHandler(),
		])
	}

defer {
	try! group.syncShutdownGracefully()
}

let channel = try bootstrap.connect(host: "127.0.0.1", port: 22).wait()

let exitStatusPromise = channel.eventLoop.makePromise(of: Int.self)
let childChannel: Channel = try! channel.pipeline.handler(type: NIOSSHHandler.self).flatMap { sshHandler in
	let promise = channel.eventLoop.makePromise(of: Channel.self)
	sshHandler.createChannel(promise) { childChannel, channelType in
		guard channelType == .session else {
			return channel.eventLoop.makeFailedFuture(SSHClientError.invalidChannelType)
		}
		return childChannel.pipeline.addHandlers([SSHToSFTPHander()])
	}
	return promise.futureResult
}.wait()

// Wait for the connection to close
try childChannel.closeFuture.wait()
let exitStatus = try! exitStatusPromise.futureResult.wait()
try! channel.close().wait()
