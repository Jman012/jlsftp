import Foundation
import Combine
import NIO

public class SftpChannelHandler: ChannelDuplexHandler {
	public typealias InboundIn = MessagePart
	public typealias InboundOut = Never
	public typealias OutboundIn = Never
	public typealias OutboundOut = MessagePart

	private enum State {
		case awaitingHeader
		case processingHeader(SftpMessage)
	}
//	public enum HandlerError {
//		case
//	}

	private let server: SftpServer

	private var state: State
	private var shouldRead: Bool = false


	public init(server: SftpServer) {
		self.server = server
		self.state = .awaitingHeader
	}

	public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
		let messagePart = self.unwrapInboundIn(data)

//		switch messagePart {
//		case let .header(packet):
//			switch state {
//			case .awaitingHeader:
//			case .processingHeader(_):
//
//			}
//		case let .body(buffer):
//			switch state {
//			case .awaitingHeader:
//			case .processingHeader(_):
//
//			}
//		case .end:
//			switch state {
//			case .awaitingHeader:
//			case .processingHeader(_):
//
//			}
//		}
	}

	public func read(context: ChannelHandlerContext) {
		if shouldRead {
			context.read()
		}
	}
}
