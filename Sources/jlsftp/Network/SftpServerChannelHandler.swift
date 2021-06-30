import Foundation
import Combine
import NIO

/**
 An NIO channel handler responsible for bridging the incoming data from the NIO
 pipeline into an `SftpMessage` object and serving that to the injected
 `SftpServer` handler.
 This also ports the Combine backpressure to the NIO backpressure mechanisms.
 */
public class SftpServerChannelHandler: ChannelDuplexHandler {
	public typealias InboundIn = MessagePart
	public typealias InboundOut = Never
	public typealias OutboundIn = Never
	public typealias OutboundOut = MessagePart

	public enum State {
		case awaitingHeader
		case processingMessage(SftpMessage)
		case awaitingFinishedReply(SftpMessage)
	}

	public enum HandlerError: Error {
		case unexpected(MessagePart, State)

		public var description: String {
			switch self {
			case let .unexpected(.header(packet, _), .processingMessage(sftpMessage)):
				return "An unexpected sftp packet header \(String(describing: packet.packetType)) was encountered when body data was expected (while processing \(String(describing: sftpMessage.packet.packetType)))"
			case let .unexpected(.header(packet, _), .awaitingFinishedReply(_)):
				return "An unexpected sftp packet header \(String(describing: packet.packetType)) was encountered when no reads should have occurred."
			case .unexpected(.body(_), .awaitingHeader):
				return "An unexpected sftp data chunk was encountered when an sftp packet header was expected."
			case .unexpected(.body(_), .awaitingFinishedReply(_)):
				return "An unexpected sftp data chunk was encountered when no reads should have occurred."
			case .unexpected(.end, .awaitingHeader):
				return "An unexpected sftp data end marker was encountered when an sftp packet header was expected."
			case .unexpected(.end, .awaitingFinishedReply(_)):
				return "An unexpected sftp data end marker was encountered when no reads should have occurred."
			case .unexpected(.header(_, _), .awaitingHeader),
				 .unexpected(.body(_), .processingMessage(_)),
				 .unexpected(.end, .processingMessage(_)):
				return "An unexpected error occurred, but the state does not make sense."
			}
		}
	}

	private let server: SftpServer

	private var state: State
	private var shouldRead: Bool = false
	internal var context: ChannelHandlerContext?
	private var replyCancellable: AnyCancellable?

	public init(server: SftpServer) {
		self.server = server
		self.state = .awaitingHeader

		self.server.register(replyHandler: { message in
			return self.reply(withMessage: message)
		})
	}

	public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
		let messagePart = self.unwrapInboundIn(data)

		// TODO: handle error if previous message is still awaiting bytes?

		// There are two data streams we need to worry about: a potential incoming
		// data stream (perhaps a file being sent to the server) and a potential
		// outgoing data stream (perhaps a file being set to the client).
		// Requests should be serialized in some way: if the client sends two
		// requests to the server in a row immediately, this handler will get the
		// first one's header, make an SftpMessage from it and send that to the
		// SftpServer, and then if we're not careful it will immediately take the
		// second request and do the same. In this case, it's possible that the
		// server is processing two requests at the same time, and writing raw
		// bytes to the client at the same time. This is bad.

		// What we do to prevent this is use the state and the inbound message parts
		// carefully:
		// - When we receive the first message header
		//   - Move the state to .processingHeader
		//   - Send the SftpMessage to the server, and get back a future
		//     - This future will complete when the server has completed writing
		//       reply data on the outbound back to the client.
		// - When we optionally receive body/end data from inbound, don't change
		//   the state just yet.
		// - While the state is still .processingHeader, we can't reject reads
		//   because if the request was uploading data, then we need to let the
		//   body reads come in. If not, then we'll get deadlock.
		//   - So, we have the .awaitingFinishedReply state. The .processingHeader
		//     will continue allowing reads for .body/.end. But, when we get .end,
		//     we change the state to .awaitingFinishedReply.
		//   - If the state is .awaitingFinishedReply, reject inbound reads.
		//   - Once the future of the server completes (the server has finished
		//     writing whatever data it needs to), then change the state back to
		//     .awaitingHeader for the next message to be processed completely.

		switch messagePart {
		case let .header(packet, bodyLength):
			switch state {
			case .awaitingHeader:
				self.shouldRead = false
				let sftpMessage = SftpMessage(
					packet: packet,
					dataLength: bodyLength,
					shouldReadHandler: { shouldRead in
						// Connect the Combine publisher to the NIO pipeline to
						// use TCP congestion mechanisms to handle large streams
						// of data, instead of using memory.
						self.shouldRead = shouldRead
				})

				if packet.packetType?.hasBody ?? false {
					state = .processingMessage(sftpMessage)
				} else {
					state = .awaitingFinishedReply(sftpMessage)
				}

				let serverHandledFuture = server.handle(message: sftpMessage, on: context.eventLoop)
				serverHandledFuture.whenComplete { _ in
					self.state = .awaitingHeader
				}
			case .processingMessage:
				context.fireErrorCaught(HandlerError.unexpected(messagePart, self.state))
			case .awaitingFinishedReply:
				context.fireErrorCaught(HandlerError.unexpected(messagePart, self.state))
			}
		case let .body(buffer):
			switch state {
			case .awaitingHeader:
				context.fireErrorCaught(HandlerError.unexpected(messagePart, self.state))
			case let .processingMessage(sftpMessage):
				let sendDataResult = sftpMessage.sendData(buffer)
				switch sendDataResult {
				case .success:
					break
				case let .failure(error):
					context.fireErrorCaught(error)
				}
			case .awaitingFinishedReply:
				context.fireErrorCaught(HandlerError.unexpected(messagePart, self.state))
			}
		case .end:
			switch state {
			case .awaitingHeader:
				context.fireErrorCaught(HandlerError.unexpected(messagePart, self.state))
			case let .processingMessage(sftpMessage):
				sftpMessage.completeData()
				state = .awaitingFinishedReply(sftpMessage)
			case .awaitingFinishedReply:
				context.fireErrorCaught(HandlerError.unexpected(messagePart, self.state))
			}
		}
	}

	public func read(context: ChannelHandlerContext) {
		switch state {
		case .awaitingHeader:
			// Always read when expecting the next packet header
			context.read()
		case .processingMessage:
			// Only read body data when the Combine bridged backpressure allows us.
			if shouldRead {
				context.read()
			}
		case .awaitingFinishedReply:
			// Never allow reads while the previous message is still being processed.
			return
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

	/**
	  From the `SftpServer`, sends an outbound reply to the client via the socket
	  with the contents of the `SftpMessage` and any body data written to the
	  message's Combine subject.

	  - Returns: A future that completes when the header and body data, if any,
	    are completely written to the outbound.
	 */
	private func reply(withMessage message: SftpMessage) -> EventLoopFuture<Void> {
		guard let context = context else {
			precondition(false)
		}

		// First, write the header to the wire.
		let data = self.wrapOutboundOut(.header(message.packet, message.totalBodyBytes))
		let headerFuture = context.write(data)

		// Next, set up the Combine sink for data to write to the wire, if any.
		let endPromise = context.eventLoop.makePromise(of: Void.self)
		if message.totalBodyBytes > 0 {
			var bodyFutures: [EventLoopFuture<Void>] = []

			let cancellable = message.data.futureSink(
				maxConcurrent: 10,
				receiveCompletion: { _ in
					// When the sink completed, send a .end, add a new future for
					// this operation, and succeed the aforementioned promise so
					// that the fold can complete when endFuture finishes.
					let endFuture = context.write(self.wrapOutboundOut(.end))
					_ = endFuture.fold(bodyFutures, with: { _, _ in self.context!.eventLoop.makeSucceededFuture(()) }).always { _ in
						endPromise.succeed(())
					}
				},
				receiveValue: { buffer in
					// When data arrives from the message, send it over the wire
					// and track the future.
					let future = context.write(self.wrapOutboundOut(.body(buffer)))
					bodyFutures.append(future)
					return future
			})
			// Store the cancellable so it doesn't self-cancel when this returns
			self.replyCancellable = cancellable
		} else {
			endPromise.succeed(())
		}

		// Send a folded future for when all writes to the context finish.
		return headerFuture.and(endPromise.futureResult).map({ _ in () })
	}
}
