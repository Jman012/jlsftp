import Foundation

extension jlftp.Packets {
	
	public class VersionPacket: Packet {
		
		public let version: jlftp.DataLayer.SftpVersion
		public let extensionData: [jlftp.DataLayer.ExtensionData]
		
		public init(version: jlftp.DataLayer.SftpVersion, extensionData: [jlftp.DataLayer.ExtensionData]) {
			self.version = version
			self.extensionData = extensionData
		}
		
	}
	
	
}
