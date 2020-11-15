import Foundation

/**
  Initializes an sftp session with the sever. This does not contain extension
  data, compared to sftp v3.

 - Since: sftp v4
 - Note: Expected Response Packet:
 * Success => [VersionPacket](x-source-tag://VersionPacket)
 * Failure => [StatusReplyPacket](x-source-tag://StatusReplyPacket)
 */
public class InitializePacketV4 {

	/**
	 The highest sftp version number of the client.

	 - Since: sftp v3
	 */
	public let version: jlsftp.DataLayer.SftpVersion

	public init(version: jlsftp.DataLayer.SftpVersion) {
		self.version = version
	}
}
