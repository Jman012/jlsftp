import Foundation
import NIO

struct ClientRequest {
	let message: SftpMessage
	let promise: EventLoopPromise<SftpMessage>

	init(message: SftpMessage, eventLoop: EventLoop) {
		self.message = message
		self.promise = eventLoop.makePromise()
	}
}
