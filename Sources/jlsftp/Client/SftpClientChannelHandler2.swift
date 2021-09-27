import Foundation
import Combine
import NIO
import Logging

class SftpClientChannelHandler2: ChannelDuplexHandler {
	typealias InboundIn = MessagePart
	typealias InboundOut = Never
	typealias OutboundIn = ClientRequest
	typealias OutboundOut = MessagePart

	internal enum State {
		case awaitingRequest(requestQueue: CircularBuffer<ClientRequest>, canWriteBody: Bool)
		case processingResponse(currentResponse: SftpMessage, currentRequest: ClientRequest, requestQueue: CircularBuffer<ClientRequest>, needsContextRead: Bool, canWriteBody: Bool)
	}

	internal enum HandlerError: Error {
		case unexpectedState(MessagePart, State)
		case unexpectedWrite

//		public var description: String {
//			switch self {
//			case .unexpectedState(.header, .awaitingRequest):
//				return "An unexpected sftp headerwas encountered when no request was being processed."
//			case .unexpectedState(.body, .awaitingRequest):
//				return "An unexpected sftp data chunk was encountered when no request was being processed."
//			case .unexpectedState(.end, .awaitingRequest):
//				return "An unexpected sftp data end marker was encountered when no request was being processed."
//			case .unexpectedState(.header, .processingRequest),
//				 .unexpectedState(.body, .processingRequest),
//				 .unexpectedState(.end, .processingRequest):
//				return "An unexpected error occurred, but the state does not make sense."
//			case .unexpectedWrite:
//				return "The server responded to an unknown request"
//			}
//		}
	}

	private let logger: Logger
	public var outstandingFutureLimit: UInt = 10

	private(set) var state: State = .awaitingRequest(requestQueue: .init(), canWriteBody: false)

	public init(logger: Logger) {
		self.logger = logger
	}

	public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
		let messagePart = self.unwrapInboundIn(data)

		switch state {
		case .awaitingRequest(requestQueue: var requestQueue, canWriteBody: let canWriteBody):
			switch messagePart {
			case let .header(packet, bodyLength):
				// Received a response header while processing a request.
				// Create the message and succeed the request promise.
				// Don't change the next current request until the body is
				// finished writing an we get a .end
				guard let nextRequest = requestQueue.popFirst() else {
					// Should not receive a header when there's no pending outbound request
					context.fireErrorCaught(HandlerError.unexpectedState(messagePart, state))
					break
				}
				logger.debug("Handling incoming response message: \(packet) with data length \(bodyLength)")
				let newMessage = createMessage(context: context, packet: packet, bodyLength: bodyLength)
				state = .processingResponse(currentResponse: newMessage, currentRequest: nextRequest, requestQueue: requestQueue, needsContextRead: true, canWriteBody: canWriteBody)
				nextRequest.respond(message: newMessage)
			case .body, .end:
				// Should not receive body data when not yet processing a response.
				context.fireErrorCaught(HandlerError.unexpectedState(messagePart, state))
			}
		case .processingResponse(currentResponse: let currentResponse, currentRequest: let currentRequest, requestQueue: var requestQueue, needsContextRead: let needsContextRead, canWriteBody: let canWriteBody):
			switch messagePart {
			case let .header(packet, bodyLength):
				// Should not receive a new response header when still processing a previous response
				context.fireErrorCaught(HandlerError.unexpectedState(messagePart, state))
			case let .body(buffer):
				// Received body data for the incoming response message. Write
				// it to the pending response.
				currentRequest.writeResponseData(buffer: buffer)
			case .end:
				// Received the end of the body data for the incoming response
				// message. Mark the response body as completed.
				currentRequest.endResponseData()

				state = .awaitingRequest(requestQueue: requestQueue, canWriteBody: canWriteBody)
			}
		}
	}

	public func read(context: ChannelHandlerContext) {
		switch state {
		case .awaitingRequest:
			// Always read when not yet processing a response message
			context.read()
		case let .processingResponse(currentResponse: currentResponse, currentRequest: currentRequest, requestQueue: requestQueue, needsContextRead: _, canWriteBody: canWriteBody):
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
			if canWriteBody {
				// The stream backpressure is allowing more data, and nothing is
				// in the queue. Allow reads.
				context.read()
			} else {
				// Either the stream backpressure has kicked in, or we already
				// have data for the next message (in the queue), so disallow
				// more reads.
				state = .processingResponse(currentResponse: currentResponse, currentRequest: currentRequest, requestQueue: requestQueue, needsContextRead: true, canWriteBody: canWriteBody)
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
		let clientRequest = self.unwrapOutboundIn(data)
		clientRequest.requestMessageSentPromise.futureResult.cascade(to: promise)

		switch state {
		case .awaitingRequest(requestQueue: var requestQueue, canWriteBody: let canWriteBody):
			requestQueue.append(clientRequest)
			state = .awaitingRequest(requestQueue: requestQueue, canWriteBody: canWriteBody)
		case .processingResponse(currentResponse: let currentResponse, currentRequest: let currentRequest, requestQueue: var requestQueue, needsContextRead: let needsContextRead, canWriteBody: let canWriteBody):
			requestQueue.append(clientRequest)
			state = .processingResponse(currentResponse: currentResponse, currentRequest: currentRequest, requestQueue: requestQueue, needsContextRead: needsContextRead, canWriteBody: canWriteBody)
		}

		let message = clientRequest.message
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

extension SftpClientChannelHandler2 {

	// MARK: Private methods

	private func createMessage(context: ChannelHandlerContext, packet: Packet, bodyLength: UInt32) -> SftpMessage {
		let sftpMessage = SftpMessage(
			packet: packet,
			dataLength: bodyLength,
			shouldReadHandler: { hasDemand in
				// Connect the stream to the NIO pipeline to use TCP congestion
				// mechanisms to handle large streams of data, instead of using memory.
				switch self.state {
				case .processingResponse(currentResponse: let currentResponse, currentRequest: let currentRequest, requestQueue: let requestQueue, needsContextRead: var needsContextRead, canWriteBody: _):
				// Set our state's canWriteBody to true if the message has demand.
					self.state = .processingResponse(currentResponse: currentResponse, currentRequest: currentRequest, requestQueue: requestQueue, needsContextRead: needsContextRead, canWriteBody: hasDemand)
					if hasDemand && needsContextRead {
						self.logger.trace("After enabling canWriteBody, performing context read due to queued read and no queued messages")
						needsContextRead = false
						self.state = .processingResponse(currentResponse: currentResponse, currentRequest: currentRequest, requestQueue: requestQueue, needsContextRead: needsContextRead, canWriteBody: hasDemand)
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

	private func processRequestQueue(context: ChannelHandlerContext) {

		var nextRequestFound: ClientRequest?
		switch state {
		case .awaitingRequest(requestQueue: let requestQueue, canWriteBody: _):
			if let request = requestQueue.first(where: { $0.requestSendState == .awaiting }) {
				nextRequestFound = request
			}
		case .processingResponse(currentResponse: _, currentRequest: _, requestQueue: let requestQueue, needsContextRead: _, canWriteBody: _):
			if let request = requestQueue.first(where: { $0.requestSendState == .awaiting }) {
				nextRequestFound = request
			}
		}

		guard let nextRequest = nextRequestFound else {
			// Nothing to do
			return
		}

		let message = nextRequest.message
		nextRequest.requestSendState = .sending
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
			.always({ _ in nextRequest.requestSendState = .sent })
			.cascade(to: nextRequest.requestMessageSentPromise)
	}

//	private func messageCompleted(context: ChannelHandlerContext) {
//		switch state {
//		case .awaitingHeader:
//			// A message should not be completed in this state.
//			preconditionFailure()
//		case .processingMessage(current: _, queue: var messageQueue, needsContextRead: let needsContextRead, canWriteBody: _):
//			if messageQueue.isEmpty {
//				logger.trace("Server finished processing message. Waiting for new messages.")
//				state = .awaitingHeader
//				if needsContextRead {
//					context.read()
//				}
//			} else {
//				logger.trace("Server finished processing message. Process next queued message.")
//				let newMessage = messageQueue.removeFirst()
//				state = .processingMessage(current: newMessage, queue: messageQueue, needsContextRead: needsContextRead, canWriteBody: false)
//
//				let serverHandlerFuture = server.handle(message: newMessage, on: context.eventLoop)
//				serverHandlerFuture.whenComplete { _ in
//					self.messageCompleted(context: context)
//				}
//			}
//		}
//	}
}
