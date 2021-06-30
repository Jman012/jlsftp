import Foundation
import NIO

class ReadEventHitHandler: ChannelOutboundHandler {
	public typealias OutboundIn = NIOAny

	private(set) var readHitCounter = 0

	public init() {}

	public func read(context: ChannelHandlerContext) {
		self.readHitCounter += 1
		context.read()
	}
}
