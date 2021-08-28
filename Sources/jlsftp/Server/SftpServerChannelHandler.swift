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
	private var queuedMessages: [SftpMessage] = []

	public init(server: SftpServer) {
		self.server = server
	}

	public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
		let message = self.unwrapInboundIn(data)
		guard currentMessage == nil && queuedMessages.isEmpty else {
//			context.fireErrorCaught(ChannelError.unexpectedInboundMessage)
			queuedMessages.append(message)
			print("Currently processing a message. Adding incoming message to queue. Queue size: \(queuedMessages.count)")
			return
		}

		currentMessage = message
		let serverHandlerFuture = server.handle(message: message, on: context.eventLoop)
		serverHandlerFuture.whenComplete { _ in
			self.currentMessage = nil
			self.emptyQueue(context: context)
		}
	}

	private func emptyQueue(context: ChannelHandlerContext) {
		guard queuedMessages.first != nil else {
			return
		}
		let next = queuedMessages.removeFirst()
		print("Finished processing message. Taking next from queue. Queue size: \(queuedMessages.count)")
		currentMessage = next
		let serverHandlerFuture = server.handle(message: next, on: context.eventLoop)
		serverHandlerFuture.whenComplete { _ in
			self.currentMessage = nil
			self.emptyQueue(context: context)
		}
	}

	public func read(context: ChannelHandlerContext) {
		if currentMessage == nil {
			context.read()
		}
	}
}
