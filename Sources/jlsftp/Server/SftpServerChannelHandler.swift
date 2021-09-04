import Foundation
import NIO
import Logging

public class SftpServerChannelHandler: ChannelDuplexHandler {
	public typealias InboundIn = SftpMessage
	public typealias InboundOut = Never
	public typealias OutboundIn = SftpMessage
	public typealias OutboundOut = SftpMessage

	public enum ChannelError: Error {
		case unexpectedInboundMessage
	}

	private enum State {
		case awaitingMessage
		case processingMessage(current: SftpMessage, queue: CircularBuffer<SftpMessage>, needsContextRead: Bool)
	}

	public let server: SftpServer
	private let logger: Logger

	private var state: State = .awaitingMessage

	public init(server: SftpServer, logger: Logger) {
		self.server = server
		self.logger = logger
	}

	public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
		let message = self.unwrapInboundIn(data)

		switch state {
		case .awaitingMessage:
			logger.trace("Send incoming sftp message to server to process")
			state = .processingMessage(current: message, queue: .init(initialCapacity: 16), needsContextRead: false)
			let serverHandlerFuture = server.handle(message: message, on: context.eventLoop)
			serverHandlerFuture.whenComplete { _ in
				self.messageCompleted(context: context)
			}
		case .processingMessage(current: let currentMessage, queue: var messageQueue, needsContextRead: let needsContextRead):
			logger.trace("Queuing incoming sftp message while server is processing previous message")
			messageQueue.append(message)
			state = .processingMessage(current: currentMessage, queue: messageQueue, needsContextRead: needsContextRead)
		}
	}

	public func read(context: ChannelHandlerContext) {
		switch state {
		case .awaitingMessage:
			logger.trace("Server is awaiting message. Allow read.")
			context.read()
		case let .processingMessage(current: currentMessage, queue: messageQueue, needsContextRead: _):
			if currentMessage.packet.packetType?.hasBody ?? false == false {
				logger.trace("Server is processing message. Disable read.")
				state = .processingMessage(current: currentMessage, queue: messageQueue, needsContextRead: true)
			} else {
				logger.trace("Server is processing message but is expecting incoming body. Allow read.")
				context.read()
			}
		}
	}

	private func messageCompleted(context: ChannelHandlerContext) {
		switch state {
		case .awaitingMessage:
			preconditionFailure()
		case .processingMessage(current: _, queue: var messageQueue, needsContextRead: let needsContextRead):
			if messageQueue.isEmpty {
				logger.trace("Server finished processing message. Waiting for new messages.")
				state = .awaitingMessage
				if needsContextRead {
					logger.trace("Re-enable reading")
					context.read()
				}
			} else {
				logger.trace("Server finished processing message. Process queued message.")
				let newMessage = messageQueue.removeFirst()
				state = .processingMessage(current: newMessage, queue: messageQueue, needsContextRead: needsContextRead)

				let serverHandlerFuture = server.handle(message: newMessage, on: context.eventLoop)
				serverHandlerFuture.whenComplete { _ in
					self.messageCompleted(context: context)
				}
			}
		}
	}
}
