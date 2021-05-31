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

	public init(server: SftpServer) {
		self.server = server
		self.state = .awaitingHeader
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
}
