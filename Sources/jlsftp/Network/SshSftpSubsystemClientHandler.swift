import Foundation
import NIO
import NIOSSH

public class SshSftpSubsystemClientHandler: ChannelDuplexHandler {
	public typealias InboundIn = SSHChannelData
	public typealias InboundOut = ByteBuffer
	public typealias OutboundIn = ByteBuffer
	public typealias OutboundOut = SSHChannelData

	public enum HandlerError: Error, Equatable {
		case unexpectedChannelData
		case unexpectedDataBeforeInitialized
	}

	var isSftpSubsystemInitialized = false

	public func channelActive(context: ChannelHandlerContext) {
		// When the channel becomes active, activate the "sftp" SSH subsystem
		_ = context.triggerUserOutboundEvent(SSHChannelRequestEvent.SubsystemRequest(subsystem: "sftp", wantReply: true))
	}

	public func userInboundEventTriggered(context _: ChannelHandlerContext, event: Any) {
		switch event {
		case _ as ChannelSuccessEvent:
			self.isSftpSubsystemInitialized = true
		default:
			break
		}
	}

	public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
		guard self.isSftpSubsystemInitialized == true else {
			context.fireErrorCaught(HandlerError.unexpectedDataBeforeInitialized)
			return
		}

		let channelData = self.unwrapInboundIn(data)
		guard case let .byteBuffer(buffer) = channelData.data else {
			context.fireErrorCaught(HandlerError.unexpectedChannelData)
			return
		}

		// Pass along to next handler
		context.fireChannelRead(self.wrapInboundOut(buffer))
	}
}
