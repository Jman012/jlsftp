import Foundation
import NIO

public protocol SftpClientConnection {
	func handleReply(message: SftpMessage) -> EventLoopFuture<Void>
	func openFile(remotePath: String) -> EventLoopFuture<String>
}
