import Foundation
import NIO

public typealias ReplyHandler = (Packet) -> ()

public protocol SftpServer {
	func register(replyHandler: @escaping ReplyHandler)
	func handle(message: SftpMessage, on eventLoop: EventLoop)
}
