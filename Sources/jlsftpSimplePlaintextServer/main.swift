import Foundation
import NIO
import jlsftp

class ServerChannelHandler: ChannelDuplexHandler {
	typealias InboundIn = MessagePart
	typealias OutboundOut = MessagePart
	typealias InboundOut = Never
	typealias OutboundIn = Never

	public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
		// As we are not really interested getting notified on success or failure we just pass nil as promise to
		// reduce allocations.
		let messagePart = self.unwrapInboundIn(data)
		print("channelRead: \(messagePart)")

		let reply = StatusReplyPacket(id: 3, statusCode: .ok, errorMessage: "", languageTag: "en-US")

		_ = context.write(self.wrapOutboundOut(.header(.statusReply(reply), 0)))
		context.flush()
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

let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
let bootstrap = ServerBootstrap(group: group)
	// Specify backlog and enable SO_REUSEADDR for the server itself
	.serverChannelOption(ChannelOptions.backlog, value: 256)
	.serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)

	// Set the handlers that are appled to the accepted Channels
	.childChannelInitializer { channel in
		// Ensure we don't read faster than we can write by adding the BackPressureHandler into the pipeline.
		channel.pipeline.addHandlers([
			// Server inbound
			BackPressureHandler(),
			ByteToMessageHandler(SftpPacketDecoder(packetSerializer: BasePacketSerializer.createSerializer(fromSftpVersion: .v3))),
			// Server outbould
			MessageToByteHandler(SftpPacketEncoder(serializer: BasePacketSerializer.createSerializer(fromSftpVersion: .v3),
												   allocator: channel.allocator)),
			// End
			ServerChannelHandler(),
		])
	}

	// Enable SO_REUSEADDR for the accepted Channels
	.childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
	.childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
	.childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())

defer {
	try! group.syncShutdownGracefully()
}

try bootstrap.bind(host: "127.0.0.1", port: 12345)
	.wait()
	.closeFuture
	.wait()
