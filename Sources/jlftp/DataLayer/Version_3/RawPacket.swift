import Foundation

extension jlftp.DataLayer.Version_3 {
	
	public struct RawPacket {
		public let length: UInt32
		public let type: UInt8
		public let dataPayload: Data
	}
	
}

extension jlftp.DataLayer.Version_3.RawPacket: Equatable {
	
}
