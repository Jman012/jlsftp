//import Foundation
//import NIO
//
//internal class SftpClientChannelHandler: ChannelDuplexHandler {
//	typealias InboundIn = SftpMessage
//	typealias InboundOut = Never
//	typealias OutboundIn = ClientRequest
//	typealias OutboundOut = SftpMessage
//
//	enum ClientHandlerError: Error {
//		case noRequestInQueue
//	}
//
//	private var context: ChannelHandlerContext?
//	private var requestQueue: CircularBuffer<ClientRequest> = .init()
//
//	public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
//		guard let clientRequest = requestQueue.popFirst() else {
//			context.fireErrorCaught(ClientHandlerError.noRequestInQueue)
//			return
//		}
//		let message = self.unwrapInboundIn(data)
//		clientRequest.responsePromise.succeed(message)
//	}
//
//	func errorCaught(context: ChannelHandlerContext, error: Error) {
//		if let clientRequest = requestQueue.popFirst() {
//			clientRequest.responsePromise.fail(error)
//		} else {
//			context.fireErrorCaught(error)
//		}
//	}
//
//	public func write(context: ChannelHandlerContext, data: NIOAny, promise _: EventLoopPromise<Void>?) {
//		let clientRequest = self.unwrapOutboundIn(data)
//		self.requestQueue.append(clientRequest)
//		let outboundOut = self.wrapOutboundOut(clientRequest.message)
//		context.writeAndFlush(outboundOut, promise: nil)
//	}
//}
