import Foundation

/**
  Initializes an sftp session with the sever.

 - Since: sftp v3
 - Note: Expected Response Packet:
   * Success => [VersionPacket](x-source-tag://VersionPacket)
   * Failure => [StatusReplyPacket](x-source-tag://StatusReplyPacket)
 */
public struct InitializePacketV3: Equatable {

	/**
	  The highest sftp version number of the client.

	  - Since: sftp v3
	 */
	public let version: jlsftp.DataLayer.SftpVersion
	/**
	  Initialization extension data.

	  - Since: sftp v3
	 */
	public let extensionData: [ExtensionData]

	public init(version: jlsftp.DataLayer.SftpVersion, extensionData: [ExtensionData]) {
		self.version = version
		self.extensionData = extensionData
	}
}
