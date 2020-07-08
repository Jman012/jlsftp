import Foundation

public class InitializePacket: Packet {

	public let version: jlftp.DataLayer.SftpVersion
	public let extensionData: [ExtensionData]

	public init(version: jlftp.DataLayer.SftpVersion, extensionData: [ExtensionData]) {
		self.version = version
		self.extensionData = extensionData
	}
}
