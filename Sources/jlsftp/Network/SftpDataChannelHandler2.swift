import Foundation
import Combine
import NIO
import Logging

/**
An NIO channel handler responsible for bridging the incoming data from the NIO
pipeline into an `SftpMessage` object and serving that to the injected
`SftpServer` handler.
This also ports the Combine backpressure to the NIO backpressure mechanisms.
*/
public class SftpDataChannelHandler2: ChannelDuplexHandler {
	public typealias InboundIn = MessagePart
	public typealias InboundOut = Never
	public typealias OutboundIn = SftpMessage
	public typealias OutboundOut = MessagePart

	private enum State {
		case awaitingHeader
		case processingMessage(current: SftpMessage, queue: CircularBuffer<SftpMessage>, needsContextRead: Bool, canWriteBody: Bool)
	}

//	public enum HandlerError: Error {
//		case unexpected(MessagePart, State)
//
//		public var description: String {
//			switch self {
//			case let .unexpected(.header(packet, _), .processingMessage(sftpMessage)):
//				return "An unexpected sftp packet header \(String(describing: packet.packetType)) was encountered when body data was expected (while processing \(String(describing: sftpMessage.packet.packetType)))"
//			case .unexpected(.body(_), .awaitingHeader):
//				return "An unexpected sftp data chunk was encountered when an sftp packet header was expected."
//			case .unexpected(.end, .awaitingHeader):
//				return "An unexpected sftp data end marker was encountered when an sftp packet header was expected."
//			case .unexpected(.header(_, _), .awaitingHeader),
//				 .unexpected(.body(_), .processingMessage(_)),
//				 .unexpected(.end, .processingMessage(_)):
//				return "An unexpected error occurred, but the state does not make sense."
//			}
//		}
//	}

	public let server: SftpServer
	private let logger: Logger

	private var state: State = .awaitingHeader
	private var replyCancellable: AnyCancellable?

	public init(server: SftpServer, logger: Logger) {
		self.server = server
		self.logger = logger
	}

	private func createMessage(context: ChannelHandlerContext, packet: Packet, bodyLength: UInt32) -> SftpMessage {
		let sftpMessage = SftpMessage(
			packet: packet,
			dataLength: bodyLength,
			shouldReadHandler: { hasDemand in
				// Connect the Combine publisher to the NIO pipeline to
				// use TCP congestion mechanisms to handle large streams
				// of data, instead of using memory.
				switch self.state {
				case .processingMessage(current: let currentMessage, queue: let messageQueue, needsContextRead: var needsContextRead, canWriteBody: let canWriteBody):
					self.logger.trace("Switching canWriteBody/hasDemand from \(canWriteBody) to \(hasDemand)")
					self.state = .processingMessage(current: currentMessage, queue: messageQueue, needsContextRead: needsContextRead, canWriteBody: hasDemand)
					if messageQueue.isEmpty && needsContextRead {
						self.logger.trace("After enabling canWriteBody, performing context read due to queued read and no queued messages")
						needsContextRead = false
						self.state = .processingMessage(current: currentMessage, queue: messageQueue, needsContextRead: needsContextRead, canWriteBody: hasDemand)
						context.read()
					}
				default:
					preconditionFailure() // Todo:
				}
			})

		return sftpMessage
	}

	public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
		let messagePart = self.unwrapInboundIn(data)

		switch state {
		case .awaitingHeader:
			switch messagePart {
			case let .header(packet, bodyLength):
				let newMessage = createMessage(context: context, packet: packet, bodyLength: bodyLength)
				logger.debug("Handling incoming message: \(newMessage.packet) with data length \(newMessage.totalBodyBytes)")
				state = .processingMessage(current: newMessage, queue: .init(initialCapacity: 4), needsContextRead: false, canWriteBody: false)
				let serverHandlerFuture = server.handle(message: newMessage, on: context.eventLoop)
				serverHandlerFuture.whenComplete { _ in
					self.messageCompleted(context: context)
				}
			case .body(_):
				preconditionFailure() // Todo:
			case .end:
				preconditionFailure() // Todo:
			}
		case .processingMessage(current: let currentMessage, queue: var messageQueue, needsContextRead: let needsContextRead, canWriteBody: let canWriteBody):
			switch messagePart {
			case let .header(packet, bodyLength):
				let newMessage = createMessage(context: context, packet: packet, bodyLength: bodyLength)
				logger.debug("Queueing incoming message: \(newMessage.packet) with data length \(newMessage.totalBodyBytes)")
				messageQueue.append(newMessage)
				state = .processingMessage(current: currentMessage, queue: messageQueue, needsContextRead: needsContextRead, canWriteBody: canWriteBody)
			case let .body(buffer):
				logger.debug("Sending incoming body data of \(buffer.readableBytes) bytes to latest message stream")
				let message = messageQueue.last ?? currentMessage
				let sendDataResult = message.sendData(buffer)
				switch sendDataResult {
				case .success:
					break
				case let .failure(error):
					context.fireErrorCaught(error)
				}
				// No changes to state
			case .end:
				logger.debug("End of body stream encountered, completing current message stream")
				let message = messageQueue.last ?? currentMessage
				message.completeData()
				// No changes to state. The server is still processing the current message.
				// Once the server finishes its task with the message of the completion,
				// it will complete its promise, which calls messageCompleted(context:)
				// which will properly advance the state either to the queue or awaitingHeader.
			}
		}

//		switch messagePart {
//		case let .header(packet, bodyLength):
//			switch state {
//			case .awaitingHeader:
//				self.shouldRead = false
//				let sftpMessage = SftpMessage(
//					packet: packet,
//					dataLength: bodyLength,
//					shouldReadHandler: { shouldRead in
//						// Connect the Combine publisher to the NIO pipeline to
//						// use TCP congestion mechanisms to handle large streams
//						// of data, instead of using memory.
//						self.shouldRead = shouldRead
//					})
//
//				logger.debug("Handling incoming message: \(sftpMessage.packet) with data length \(sftpMessage.totalBodyBytes)")
//
//				if packet.packetType?.hasBody ?? false {
//					state = .processingMessage(sftpMessage)
//				} else {
//					state = .awaitingHeader
//				}
//
//				context.fireChannelRead(self.wrapInboundOut(sftpMessage))
//			case .processingMessage:
//				context.fireErrorCaught(HandlerError.unexpected(messagePart, self.state))
//			}
//		case let .body(buffer):
//			switch state {
//			case .awaitingHeader:
//				context.fireErrorCaught(HandlerError.unexpected(messagePart, self.state))
//			case let .processingMessage(sftpMessage):
//				logger.trace("Received \(buffer.readableBytes) data bytes. Writing to message publisher.")
//				let sendDataResult = sftpMessage.sendData(buffer)
//				switch sendDataResult {
//				case .success:
//					break
//				case let .failure(error):
//					context.fireErrorCaught(error)
//				}
//			}
//		case .end:
//			switch state {
//			case .awaitingHeader:
//				context.fireErrorCaught(HandlerError.unexpected(messagePart, self.state))
//			case let .processingMessage(sftpMessage):
//				sftpMessage.completeData()
//				state = .awaitingHeader
//			}
//		}
	}

	public func read(context: ChannelHandlerContext) {
		switch state {
		case .awaitingHeader:
			// Always read when expecting the next packet header
			logger.trace("read(context:): Is awaiting header. Perform read.")
			context.read()
		case let .processingMessage(current: currentMessage, queue: messageQueue, needsContextRead: _, canWriteBody: canWriteBody):
			// If we're processing a currentMessage, by default we don't want to
			// read anything more. Once the server completes the message, the
			// state is changed back to awaitingHeader for the next, in which case
			// we can do a read above. However, if the currentMessage has a body
			// to pipe through to the server, the server will eventually signal
			// through canWriteBody to allow reading this in from the socket and
			// into the currentMessage. So, if canWriteBody is set, allow reads.
			// However, we might have finished reading in the body and begin reading
			// in the next message. So, if the messageQueue has items in it, do
			// not read in more data until the current message is completed.
			if canWriteBody && messageQueue.isEmpty {
				logger.trace("read(context:): canWriteBody and messageQueue is empty. Perform read.")
				context.read()
			} else {
				logger.trace("read(context:): canWriteBody=\(canWriteBody), messageQueue.count=\(messageQueue.count). Don't read.")
				state = .processingMessage(current: currentMessage, queue: messageQueue, needsContextRead: true, canWriteBody: canWriteBody)
			}
		}
	}

	/**
	From the `SftpServer`, sends an outbound reply to the client via the socket
	with the contents of the `SftpMessage` and any body data written to the
	message's Combine subject.

	- Returns: A future that completes when the header and body data, if any,
	are completely written to the outbound.
	*/
	public func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
		guard case .processingMessage = state else {
			preconditionFailure() // Todo:
		}

		let message = self.unwrapOutboundIn(data)
		logger.debug("Sending outgoing message: \(message.packet) with data length \(message.totalBodyBytes)")

		// First, write the header to the wire.
		let data = self.wrapOutboundOut(.header(message.packet, message.totalBodyBytes))
		let headerFuture = context.write(data)

		// Next, set up the Combine sink for data to write to the wire, if any.
		let endPromise = context.eventLoop.makePromise(of: Void.self)
		if message.totalBodyBytes > 0 {
			logger.trace("Outgoing message has \(message.totalBodyBytes) data bytes to send")
			var bodyFutures: [EventLoopFuture<Void>] = []

			message.stream.collect(onComplete: {
				self.logger.trace("Outgoing message has finished sending bytes. Writing end to out and resolving.")
				// When the sink completed, send a .end, add a new future for
				// this operation, and succeed the aforementioned promise so
				// that the fold can complete when endFuture finishes.
				let endFuture = context.writeAndFlush(self.wrapOutboundOut(.end)).always { _ in
					self.logger.trace("Outgoing data of message has completed")
				}
				endFuture
					.fold(bodyFutures, with: { _, _ in context.eventLoop.makeSucceededFuture(()) })
					.cascade(to: endPromise)
			}, handler: { buffer in
				self.logger.trace("Outgoing message received \(buffer.readableBytes) bytes. Writing data to out.")
				// When data arrives from the message, send it over the wire
				// and track the future.
				let future = context.writeAndFlush(self.wrapOutboundOut(.body(buffer))).always { _ in
					self.logger.trace("Outgoing data of \(buffer.readableBytes) bytes has completed")
				}
				bodyFutures.append(future)
				return future
			})
//			let cancellable = message.data.futureSink(
//				maxConcurrent: 10,
//				eventLoop: context.eventLoop,
//				receiveCompletion: { _ in
//					self.logger.trace("Outgoing message has finished sending bytes. Writing end to out and resolving.")
//					// When the sink completed, send a .end, add a new future for
//					// this operation, and succeed the aforementioned promise so
//					// that the fold can complete when endFuture finishes.
//					let endFuture = context.writeAndFlush(self.wrapOutboundOut(.end)).always { _ in
//						self.logger.trace("Outgoing data of message has completed")
//					}
//					endFuture
//						.fold(bodyFutures, with: { _, _ in context.eventLoop.makeSucceededFuture(()) })
//						.cascade(to: endPromise)
//				},
//				receiveValue: { buffer in
//					guard case .processingMessage = self.state else {
//						preconditionFailure() // Todo:
//					}
//
//					self.logger.trace("Outgoing message received \(buffer.readableBytes) bytes. Writing data to out.")
//					// When data arrives from the message, send it over the wire
//					// and track the future.
//					// Todo: remove the flush here?
//					let future = context.writeAndFlush(self.wrapOutboundOut(.body(buffer))).always { _ in
//						self.logger.trace("Outgoing data of \(buffer.readableBytes) bytes has completed")
//					}
//					bodyFutures.append(future)
//					return future
//				})
//			// Store the cancellable so it doesn't self-cancel when this returns
//			self.replyCancellable = cancellable
		} else {
			endPromise.succeed(())
		}

		// Send a folded future for when all writes to the context finish.
		headerFuture
			.and(endPromise.futureResult)
			.map({ _ in () })
			.cascade(to: promise)
	}

	private func messageCompleted(context: ChannelHandlerContext) {
		switch state {
		case .awaitingHeader:
			preconditionFailure()
		case .processingMessage(current: _, queue: var messageQueue, needsContextRead: let needsContextRead, canWriteBody: _):
			if messageQueue.isEmpty {
				logger.trace("Server finished processing message. Waiting for new messages.")
				state = .awaitingHeader
				if needsContextRead {
					logger.trace("Re-enable reading")
					context.read()
				}
			} else {
				logger.trace("Server finished processing message. Process queued message.")
				let newMessage = messageQueue.removeFirst()
				state = .processingMessage(current: newMessage, queue: messageQueue, needsContextRead: needsContextRead, canWriteBody: false)

				let serverHandlerFuture = server.handle(message: newMessage, on: context.eventLoop)
				serverHandlerFuture.whenComplete { _ in
					self.messageCompleted(context: context)
				}
			}
		}
	}
}
