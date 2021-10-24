import Foundation
import NIO

public protocol SftpClientConnection {
	func close() -> EventLoopFuture<Void>
//	func openFile(remotePath: String) -> EventLoopFuture<String>
	func status(remotePath: String) -> EventLoopFuture<String>
}
