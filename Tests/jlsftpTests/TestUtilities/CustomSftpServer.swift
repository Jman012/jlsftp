import Foundation
import NIO
@testable import jlsftp

class CustomSftpServer: SftpServer {
	var registerReplyHandlerHandler: (() -> Void)?
	var handleMessageHandler: ((SftpMessage) -> ())?

	var replyHandler: ReplyHandler?

	init() {
		self.registerReplyHandlerHandler = nil
		self.handleMessageHandler = nil
	}

	init(registerReplyHandlerHandler: @escaping () -> Void) {
		self.registerReplyHandlerHandler = registerReplyHandlerHandler
		self.handleMessageHandler = nil
	}

	init(handleMessageHandler: @escaping (SftpMessage) -> Void) {
		self.registerReplyHandlerHandler = nil
		self.handleMessageHandler = handleMessageHandler
	}

	init(registerReplyHandlerHandler: @escaping () -> Void, handleMessageHandler: @escaping (SftpMessage) -> Void) {
		self.registerReplyHandlerHandler = registerReplyHandlerHandler
		self.handleMessageHandler = handleMessageHandler
	}

	func register(replyHandler: @escaping ReplyHandler) {
		registerReplyHandlerHandler?()
		self.replyHandler = replyHandler
	}

	func handle(message: SftpMessage, on _: EventLoop) {
		handleMessageHandler?(message)
	}
}
