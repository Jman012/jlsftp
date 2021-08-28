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

	private enum State {
		case awaitingMessage
		case processingMessage(current: SftpMessage, queue: CircularBuffer<SftpMessage>, shouldRead: Bool)
	}

	public let server: SftpServer

	private var state: State = .awaitingMessage

	public init(server: SftpServer) {
		self.server = server
	}

	public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
		let message = self.unwrapInboundIn(data)

		switch state {
		case .awaitingMessage:
			state = .processingMessage(current: message, queue: .init(initialCapacity: 16), shouldRead: false)
			let serverHandlerFuture = server.handle(message: message, on: context.eventLoop)
			serverHandlerFuture.whenComplete { _ in
				self.messageCompleted(context: context)
			}
		case .processingMessage(current: let currentMessage, queue: var messageQueue, shouldRead: let shouldRead):
			messageQueue.append(message)
			state = .processingMessage(current: currentMessage, queue: messageQueue, shouldRead: shouldRead)
		}
	}

	public func read(context: ChannelHandlerContext) {
		switch state {
		case .awaitingMessage:
			context.read()
		case let .processingMessage(current: currentMessage, queue: messageQueue, shouldRead: _):
			state = .processingMessage(current: currentMessage, queue: messageQueue, shouldRead: true)
		}
	}

	private func messageCompleted(context: ChannelHandlerContext) {
		switch state {
		case .awaitingMessage:
			preconditionFailure()
		case .processingMessage(current: _, queue: var messageQueue, shouldRead: let shouldRead):
			if messageQueue.isEmpty {
				state = .awaitingMessage
				if shouldRead {
					context.read()
				}
			} else {
				let newMessage = messageQueue.removeFirst()
				state = .processingMessage(current: newMessage, queue: messageQueue, shouldRead: shouldRead)

				let serverHandlerFuture = server.handle(message: newMessage, on: context.eventLoop)
				serverHandlerFuture.whenComplete { _ in
					self.messageCompleted(context: context)
				}
			}
		}
	}
}
