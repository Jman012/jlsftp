import Foundation
import NIO

public protocol SftpClientConnection {
	func openFile(remotePath: String) -> EventLoopFuture<String>
}
