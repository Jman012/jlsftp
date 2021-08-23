import Foundation
import NIO

internal class SftpClientChannelHandler: ChannelDuplexHandler {
	typealias InboundIn = SftpMessage
	typealias InboundOut = Never
	typealias OutboundIn = ClientRequest
	typealias OutboundOut = SftpMessage

	private var context: ChannelHandlerContext?
	private var requestQueue: [ClientRequest] = []

	public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
		let message = self.unwrapInboundIn(data)
		let clientRequest = requestQueue.removeFirst()
		clientRequest.promise.succeed(message)
	}

	func errorCaught(context: ChannelHandlerContext, error: Error) {
		if requestQueue.isEmpty {
			context.fireErrorCaught(error)
		} else {
			requestQueue.removeFirst().promise.fail(error)
		}
	}

	public func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
		let clientRequest = self.unwrapOutboundIn(data)
		self.requestQueue.append(clientRequest)
		let outboundOut = self.wrapOutboundOut(clientRequest.message)
		context.writeAndFlush(outboundOut, promise: nil)
	}
}
