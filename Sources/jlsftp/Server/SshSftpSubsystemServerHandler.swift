import Foundation
import NIO
import NIOSSH

internal class SshSftpSubsystemServerHandler: ChannelDuplexHandler {
	typealias InboundIn = SSHChannelData
	typealias InboundOut = ByteBuffer
	typealias OutboundIn = ByteBuffer
	typealias OutboundOut = SSHChannelData

	enum HandlerError: Error, Equatable {
		case unexpectedChannelData
		case unexpectedDataBeforeInitialized
	}

	var isSftpSubsystemInitialized = false

	func userInboundEventTriggered(context: ChannelHandlerContext, event: Any) {
		switch event {
		case let subsystemRequest as SSHChannelRequestEvent.SubsystemRequest:
			if subsystemRequest.subsystem == "sftp" {
				isSftpSubsystemInitialized = true
				context.triggerUserOutboundEvent(ChannelSuccessEvent(), promise: nil)
			}
		default:
			break
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
