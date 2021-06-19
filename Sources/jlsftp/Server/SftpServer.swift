import Foundation
import NIO

public typealias ReplyHandler = (SftpMessage) -> EventLoopFuture<Void>

public protocol SftpServer {
	func register(replyHandler: @escaping ReplyHandler)
	func handle(message: SftpMessage, on eventLoop: EventLoop)
}
