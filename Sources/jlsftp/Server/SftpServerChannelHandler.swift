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
public class SftpServerChannelHandler: ChannelDuplexHandler {
	public typealias InboundIn = MessagePart
	public typealias InboundOut = Never
	public typealias OutboundIn = SftpMessage
	public typealias OutboundOut = MessagePart

	internal enum State {
		case awaitingHeader
		case processingMessage(current: SftpMessage, queue: CircularBuffer<SftpMessage>, needsContextRead: Bool, canWriteBody: Bool)
	}

	internal enum HandlerError: Error {
		case unexpectedState(MessagePart, State)
		case unexpectedWrite

		public var description: String {
			switch self {
			case .unexpectedState(.body, .awaitingHeader):
				return "An unexpected sftp data chunk was encountered when an sftp packet header was expected."
			case .unexpectedState(.end, .awaitingHeader):
				return "An unexpected sftp data end marker was encountered when an sftp packet header was expected."
			case .unexpectedState(.header, .processingMessage),
				 .unexpectedState(.header, .awaitingHeader),
				 .unexpectedState(.body, .processingMessage),
				 .unexpectedState(.end, .processingMessage):
				return "An unexpected error occurred, but the state does not make sense."
			case .unexpectedWrite:
				return "The server responded to an unknown request"
			}
		}
	}

	public let server: SftpServer
	private let logger: Logger
	public var outstandingFutureLimit: UInt = 10

	private(set) var state: State = .awaitingHeader

	public init(server: SftpServer, logger: Logger) {
		self.server = server
		self.logger = logger
	}

	public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
		let messagePart = self.unwrapInboundIn(data)

		switch state {
		case .awaitingHeader:
			switch messagePart {
			case let .header(packet, bodyLength):
				// Received a header while awaiting a header.
				// Create the message, pass it on to the server to handle, and
				// change the state to track it with an empty queue.
				logger.debug("Handling incoming message: \(packet) with data length \(bodyLength)")
				let newMessage = createMessage(context: context, packet: packet, bodyLength: bodyLength)
				state = .processingMessage(current: newMessage, queue: .init(initialCapacity: 4), needsContextRead: false, canWriteBody: false)
				let serverHandlerFuture = server.handle(message: newMessage, on: context.eventLoop)
				serverHandlerFuture.whenComplete { _ in
					self.messageCompleted(context: context)
				}
			case .body(_):
				// Should not receive a body before a header
				context.fireErrorCaught(HandlerError.unexpectedState(messagePart, .awaitingHeader))
			case .end:
				// Should not receive an end before a header
				context.fireErrorCaught(HandlerError.unexpectedState(messagePart, .awaitingHeader))
			}
		case .processingMessage(current: let currentMessage, queue: var messageQueue, needsContextRead: let needsContextRead, canWriteBody: let canWriteBody):
			switch messagePart {
			case let .header(packet, bodyLength):
				// Received a header while another message is still being processed.
				// Create a new message but only add it to the queue in the state.
				logger.debug("Queueing incoming message: \(packet) with data length \(bodyLength)")
				let newMessage = createMessage(context: context, packet: packet, bodyLength: bodyLength)
				messageQueue.append(newMessage)
				state = .processingMessage(current: currentMessage, queue: messageQueue, needsContextRead: needsContextRead, canWriteBody: canWriteBody)
			case let .body(buffer):
				// Received body data while processing a message. The body data
				// might be for a future message, not the one being processed.
				// So, add the data to the most-recently queued message, else
				// the current message.
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
				// Received an end. Same as above, complete the stream for the
				// most recent message received.
				logger.debug("End of body stream encountered, completing current message stream")
				let message = messageQueue.last ?? currentMessage
				message.completeData()
				// No changes to state. The server is still processing the current message.
				// Once the server finishes its task with the message of the completion,
				// it will complete its promise, which calls messageCompleted(context:)
				// which will properly advance the state either to the queue or awaitingHeader.
			}
		}
	}

	public func read(context: ChannelHandlerContext) {
		switch state {
		case .awaitingHeader:
			// Always read when expecting the next packet header
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
				// The stream backpressure is allowing more data, and nothing is
				// in the queue. Allow reads.
				context.read()
			} else {
				// Either the stream backpressure has kicked in, or we already
				// have data for the next message (in the queue), so disallow
				// more reads.
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
			// The server can only respond to a request. If there is no request,
			// then nothing should be sent.
			context.fireErrorCaught(HandlerError.unexpectedWrite)
			promise?.fail(HandlerError.unexpectedWrite)
			return
		}

		let message = self.unwrapOutboundIn(data)
		logger.debug("Sending outgoing message: \(message.packet) with data length \(message.totalBodyBytes)")

		// First, write the header to the wire.
		let data = self.wrapOutboundOut(.header(message.packet, message.totalBodyBytes))
		let headerFuture = context.write(data)

		// Next, set up the stream for data to write to the wire, if any.

		// Normally, an NIO channelWrite's promise would complete once the data
		// has been immediately pushed to the socket. However, we only want this
		// promise to succeed once all of the data has also been pushed out.
		// This endPromise will keep track of this (see the end of the function).
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
		} else {
			endPromise.succeed(())
		}

		// Send a folded future for when all writes to the context finish.
		// The headerFuture is from writing the header. The endPromise is from
		// writing all of the body data and the final end part.
		headerFuture
			.and(endPromise.futureResult)
			.map({ _ in () })
			.cascade(to: promise)
	}
}

extension SftpServerChannelHandler {

	// MARK: Private methods

	private func createMessage(context: ChannelHandlerContext, packet: Packet, bodyLength: UInt32) -> SftpMessage {
		let sftpMessage = SftpMessage(
			packet: packet,
			dataLength: bodyLength,
			shouldReadHandler: { hasDemand in
				// Connect the stream to the NIO pipeline to use TCP congestion
				// mechanisms to handle large streams of data, instead of using memory.
				switch self.state {
				case .processingMessage(current: let currentMessage, queue: let messageQueue, needsContextRead: var needsContextRead, canWriteBody: _):
					// Set our state's canWriteBody to true if the message has demand.
					self.state = .processingMessage(current: currentMessage, queue: messageQueue, needsContextRead: needsContextRead, canWriteBody: hasDemand)
					if hasDemand && messageQueue.isEmpty && needsContextRead {
						self.logger.trace("After enabling canWriteBody, performing context read due to queued read and no queued messages")
						needsContextRead = false
						self.state = .processingMessage(current: currentMessage, queue: messageQueue, needsContextRead: needsContextRead, canWriteBody: hasDemand)
						context.read()
					}
				default:
					// We should not be receiving this when not processing a message.
					preconditionFailure()
				}
			},
			logger: logger,
			outstandingFutureLimit: outstandingFutureLimit)

		return sftpMessage
	}

	private func messageCompleted(context: ChannelHandlerContext) {
		switch state {
		case .awaitingHeader:
			// A message should not be completed in this state.
			preconditionFailure()
		case .processingMessage(current: _, queue: var messageQueue, needsContextRead: let needsContextRead, canWriteBody: _):
			if messageQueue.isEmpty {
				logger.trace("Server finished processing message. Waiting for new messages.")
				state = .awaitingHeader
				if needsContextRead {
					context.read()
				}
			} else {
				logger.trace("Server finished processing message. Process next queued message.")
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
