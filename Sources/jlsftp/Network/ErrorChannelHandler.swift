import Foundation
import NIO
import Logging

internal class ErrorChannelHandler: ChannelInboundHandler {
	typealias InboundIn = Any

	let logger: Logger

	init(logger: Logger) {
		self.logger = logger
	}

	func errorCaught(context: ChannelHandlerContext, error: Error) {
		self.logger.error("Error in pipeline: \(error)")
		_ = context.close().always {
			self.logger.info("Disconnected from client \(String(describing: context.channel.remoteAddress)): \($0)")
		}
	}
}
