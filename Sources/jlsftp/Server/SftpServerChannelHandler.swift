import Foundation
import NIO

public class SftpServerChannelHandler: ChannelDuplexHandler {
	public typealias InboundIn = SftpMessage
	public typealias InboundOut = Never
	public typealias OutboundIn = Never
	public typealias OutboundOut = SftpMessage

	public enum ChannelError: Error {
		case unexpectedInboundMessage
	}

	public let server: SftpServer

	private var currentMessage: SftpMessage?
	private var context: ChannelHandlerContext?

	public init(server: SftpServer) {
		self.server = server
		self.server.register(replyHandler: { message in
			return self.reply(withMessage: message)
		})
	}

	public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
		guard currentMessage == nil else {
			context.fireErrorCaught(ChannelError.unexpectedInboundMessage)
			return
		}

		let message = self.unwrapInboundIn(data)
		currentMessage = message
		let serverHandlerFuture = server.handle(message: message, on: context.eventLoop)
		serverHandlerFuture.whenComplete { _ in
			self.currentMessage = nil
		}
	}

	public func read(context: ChannelHandlerContext) {
		if currentMessage == nil {
			context.read()
		}
	}

	public func channelRegistered(context: ChannelHandlerContext) {
		self.context = context
		context.fireChannelRegistered()
	}

	public func channelUnregistered(context: ChannelHandlerContext) {
		self.context = nil
		context.fireChannelUnregistered()
	}

	private func reply(withMessage message: SftpMessage) -> EventLoopFuture<Void> {
		guard let context = context else {
			precondition(false)
		}

		let promise = context.eventLoop.makePromise(of: Void.self)
		context.write(self.wrapOutboundOut(message), promise: promise)
		return promise.futureResult
	}
}
