import Foundation
import NIO
@testable import jlsftp

class CustomSftpServer: SftpServer {
	var registerReplyHandlerHandler: (() -> Void)?
	var handleMessageHandler: ((SftpMessage) -> EventLoopFuture<Void>)?

	var registeredReplyHandler: ReplyHandler?

	var replyHandler: ReplyHandler?

	init() {
		self.registerReplyHandlerHandler = nil
		self.handleMessageHandler = nil
	}

	init(registerReplyHandlerHandler: @escaping () -> Void) {
		self.registerReplyHandlerHandler = registerReplyHandlerHandler
		self.handleMessageHandler = nil
	}

	init(handleMessageHandler: @escaping (SftpMessage) -> EventLoopFuture<Void>) {
		self.registerReplyHandlerHandler = nil
		self.handleMessageHandler = handleMessageHandler
	}

	init(registerReplyHandlerHandler: @escaping () -> Void, handleMessageHandler: @escaping (SftpMessage) -> EventLoopFuture<Void>) {
		self.registerReplyHandlerHandler = registerReplyHandlerHandler
		self.handleMessageHandler = handleMessageHandler
	}

	func register(replyHandler: @escaping ReplyHandler) {
		registeredReplyHandler = replyHandler
		registerReplyHandlerHandler?()
		self.replyHandler = replyHandler
	}

	func handle(message: SftpMessage, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
		return handleMessageHandler?(message) ?? eventLoop.makeSucceededFuture(())
	}
}
