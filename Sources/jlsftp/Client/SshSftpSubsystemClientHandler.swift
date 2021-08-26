import Foundation
import NIO
import NIOSSH

internal class SshSftpSubsystemClientHandler: ChannelDuplexHandler {
	typealias InboundIn = SSHChannelData
	typealias InboundOut = ByteBuffer
	typealias OutboundIn = ByteBuffer
	typealias OutboundOut = SSHChannelData

	enum HandlerError: Error, Equatable {
		case unexpectedChannelData
		case unexpectedDataBeforeInitialized
	}

	var isSftpSubsystemInitialized = false

	func channelActive(context: ChannelHandlerContext) {
		// When the channel becomes active, activate the "sftp" SSH subsystem
		let sftpRequest = SSHChannelRequestEvent.SubsystemRequest(subsystem: "sftp", wantReply: true)
		context.triggerUserOutboundEvent(sftpRequest, promise: nil)
	}

	func userInboundEventTriggered(context: ChannelHandlerContext, event: Any) {
		switch event {
		case _ as ChannelSuccessEvent:
			isSftpSubsystemInitialized = true
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
