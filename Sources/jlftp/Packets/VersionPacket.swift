import Foundation

/**
  Server response to an initialization request.

 - Since: sftp v3
 */
public class VersionPacket: Packet {

	/**
	 The highest sftp version number of the client.

	 - Since: sftp v3
	 */
	public let version: jlftp.DataLayer.SftpVersion
	/**
	 Initialization extension data.

	 - Since: sftp v3
	 */
	public let extensionData: [ExtensionData]

	public init(version: jlftp.DataLayer.SftpVersion, extensionData: [ExtensionData]) {
		self.version = version
		self.extensionData = extensionData
	}
}
