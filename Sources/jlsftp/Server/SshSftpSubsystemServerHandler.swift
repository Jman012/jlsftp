import Foundation
import NIO
import NIOSSH
import Logging

internal class SshSftpSubsystemServerHandler: ChannelDuplexHandler {
	typealias InboundIn = SSHChannelData
	typealias InboundOut = ByteBuffer
	typealias OutboundIn = ByteBuffer
	typealias OutboundOut = SSHChannelData

	enum HandlerError: Error, Equatable {
		case unexpectedChannelData
		case unexpectedDataBeforeInitialized
	}

	let logger: Logger

	var isSftpSubsystemInitialized = false

	init(logger: Logger) {
		self.logger = logger
	}

	func userInboundEventTriggered(context: ChannelHandlerContext, event: Any) {
		switch event {
		case let subsystemRequest as SSHChannelRequestEvent.SubsystemRequest where subsystemRequest.subsystem == "sftp":
			isSftpSubsystemInitialized = true
			context.triggerUserOutboundEvent(ChannelSuccessEvent(), promise: nil)
		case ChannelEvent.inputClosed:
			self.logger.info("Client \(String(describing: context.channel.remoteAddress)) disconnected.")
			context.close(promise: nil)
		default:
			context.fireUserInboundEventTriggered(event)
		}
	}

	func channelRead(context: ChannelHandlerContext, data: NIOAny) {
		guard isSftpSubsystemInitialized else {
			context.fireErrorCaught(HandlerError.unexpectedDataBeforeInitialized)
			return
		}

		let channelData = self.unwrapInboundIn(data)
		guard case let .byteBuffer(buffer) = channelData.data else {
			context.fireErrorCaught(HandlerError.unexpectedChannelData)
			return
		}

		// Pass along to next handler
		switch channelData.type {
		case .channel:
			context.fireChannelRead(self.wrapInboundOut(buffer))
		case .stdErr:
			// TODO: Log?
			break
		default:
			break
		}
	}

	func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
		guard isSftpSubsystemInitialized else {
			context.fireErrorCaught(HandlerError.unexpectedDataBeforeInitialized)
			return
		}

		let buffer = self.unwrapOutboundIn(data)
		let channelData = SSHChannelData(type: .channel, data: .byteBuffer(buffer))
		context.write(self.wrapOutboundOut(channelData), promise: promise)
	}
}
