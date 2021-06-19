import Foundation
import Combine
import NIO

/**
 An NIO channel handler responsible for bridging the incoming data from the NIO
 pipeline into an `SftpMessage` object and serving that to the injected
 `SftpServer` handler.
 This also ports the Combine backpressure to the NIO backpressure mechanisms.
 */
public class SftpChannelHandler: ChannelDuplexHandler {
	public typealias InboundIn = MessagePart
	public typealias InboundOut = Never
	public typealias OutboundIn = Never
	public typealias OutboundOut = MessagePart

	private enum State {
		case awaitingHeader
		case processingHeader(SftpMessage)
	}

	public enum HandlerError: Error {
		case unexpectedInput(String)
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

		switch messagePart {
		case let .header(packet, bodyLength):
			switch state {
			case .awaitingHeader:
				let sftpMessage = SftpMessage(packet: packet, dataLength: bodyLength, shouldReadHandler: { shouldRead in self.shouldRead = shouldRead })

				if packet.packetType?.hasBody ?? false {
					state = .processingHeader(sftpMessage)
				} else {
					state = .awaitingHeader
				}

				server.handle(message: sftpMessage, on: context.eventLoop)
				sftpMessage.completeData()
			case let .processingHeader(sftpMessage):
				context.fireErrorCaught(HandlerError.unexpectedInput("An unexpected sftp packet header \(String(describing: packet.packetType)) was encountered when body data was expected (while processing \(String(describing: sftpMessage.packet.packetType)))"))
			}
		case let .body(buffer):
			switch state {
			case .awaitingHeader:
				context.fireErrorCaught(HandlerError.unexpectedInput("An unexpected sftp data chunk was encountered when an sftp packet header was expected."))
			case let .processingHeader(sftpMessage):
				let sendDataResult = sftpMessage.sendData(buffer)
				switch sendDataResult {
				case .success:
					break
				case let .failure(error):
					context.fireErrorCaught(error)
				}
			}
		case .end:
			switch state {
			case .awaitingHeader:
				context.fireErrorCaught(HandlerError.unexpectedInput("An unexpected sftp data end marker was encountered when an sftp packet header was expected."))
			case let .processingHeader(sftpMessage):
				sftpMessage.completeData()
				state = .awaitingHeader
			}
		}
	}

	public func read(context: ChannelHandlerContext) {
		if shouldRead {
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

		// First, write the header to the wire.
		let data = self.wrapOutboundOut(.header(message.packet, message.totalBodyBytes))
		let headerFuture = context.write(data)

		// Next, set up the Combine sink for data to write to the wire, if any.
		let endPromise = context.eventLoop.makePromise(of: Void.self)
		if message.totalBodyBytes > 0 {
			var bodyFutures: [EventLoopFuture<Void>] = []

			let cancellable = message.data.futureSink(
				maxConcurrent: 10,
				receiveCompletion: { completion in
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
