import Foundation
import NIO

internal class SftpClientChannelHandler: ChannelDuplexHandler {
	typealias InboundIn = SftpMessage
	typealias InboundOut = Never
	typealias OutboundIn = ClientRequest
	typealias OutboundOut = SftpMessage

	enum ClientHandlerError: Error {
		case noRequestInQueue
	}

	private var context: ChannelHandlerContext?
	private var requestQueue: [ClientRequest] = []

	public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
		guard let clientRequest = requestQueue.first else {
			context.fireErrorCaught(ClientHandlerError.noRequestInQueue)
			return
		}
		let message = self.unwrapInboundIn(data)
		clientRequest.promise.succeed(message)
		if clientRequest.shouldRemove(responseMessage: message) {
			_ = requestQueue.removeFirst()
		}
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
