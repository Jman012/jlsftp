import Foundation
import NIO
import jlsftp

class ClientChannelHandler: ChannelInboundHandler {
	typealias InboundIn = MessagePart
	typealias OutboundOut = MessagePart

	public func channelActive(context: ChannelHandlerContext) {
		print("channelActive. sending init")
		let request = InitializePacketV3(version: .v3, extensionData: [])
		_ = context.write(self.wrapOutboundOut(.header(.initializeV3(request))))
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

let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
let bootstrap = ClientBootstrap(group: group)
	.channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
	.channelInitializer { channel in
		channel.pipeline.addHandlers([
			ByteToMessageHandler(SftpPacketDecoder(packetSerializer: BasePacketSerializer.createSerializer(fromSftpVersion: .v3))),
			// Server outbould
			MessageToByteHandler(SftpPacketEncoder(serializer: BasePacketSerializer.createSerializer(fromSftpVersion: .v3))),
			// End
			ClientChannelHandler(),
		])
	}

defer {
	try! group.syncShutdownGracefully()
}

try bootstrap.connect(host: "127.0.0.1", port: 12345)
	.wait()
	.closeFuture
	.wait()
