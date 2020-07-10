import Foundation

/**
  Initializes an sftp session with the sever.

 - Since: sftp v3
 */
public class InitializePacket: Packet {

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
