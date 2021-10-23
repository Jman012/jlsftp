import Foundation
import NIO

public protocol SftpClientConnectionFactory {
	func create(version: jlsftp.SftpProtocol.SftpVersion, channel: Channel) -> SftpClientConnection
}
