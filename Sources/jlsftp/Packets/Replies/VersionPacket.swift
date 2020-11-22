import Foundation

/**
  Server response to an initialization request.

 - Tag: VersionPacket
 - Since: sftp v3
 */
public struct VersionPacket: Equatable {

	/**
	 The highest sftp version number of the client.

	 - Since: sftp v3
	 */
	public let version: jlsftp.SftpProtocol.SftpVersion
	/**
	 Initialization extension data.

	 - Since: sftp v3
	 */
	public let extensionData: [ExtensionData]

	public init(version: jlsftp.SftpProtocol.SftpVersion, extensionData: [ExtensionData]) {
		self.version = version
		self.extensionData = extensionData
	}
}
