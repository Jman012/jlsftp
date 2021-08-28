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
		context.close(promise: nil)
	}
}
