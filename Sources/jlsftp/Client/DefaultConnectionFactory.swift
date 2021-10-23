import Foundation
import NIO

public class DefaultConnectionFactory: SftpClientConnectionFactory {
	public init() {

	}
	
	public func create(version: jlsftp.SftpProtocol.SftpVersion, channel: Channel) -> SftpClientConnection {
		return BaseSftpClientConnection(version: version, channel: channel)
	}
}
