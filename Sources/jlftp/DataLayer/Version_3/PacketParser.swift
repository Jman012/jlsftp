import Foundation

public protocol SftpVersion3PacketParserHandler {
	func parse(fromPayload data: Data) -> Result<Packet, jlftp.DataLayer.Version_3.PacketParser.ParseError>
}

extension jlftp.DataLayer.Version_3 {
	
	public class PacketParser {
		
		public enum ParseError: Error, Equatable {
			case invalidType
			case payloadTooShort
			case invalidDataPayload(reason: String)
		}
		
		let initializePacketParser: SftpVersion3PacketParserHandler
		let versionPacketParser: SftpVersion3PacketParserHandler
		
		public init(
			initializePacketParser: SftpVersion3PacketParserHandler,
			versionPacketParser: SftpVersion3PacketParserHandler
		) {
			self.initializePacketParser = initializePacketParser
			self.versionPacketParser = versionPacketParser
		}
		
		public func parseRawPacket(from rawPacket: jlftp.DataLayer.Version_3.RawPacket) -> Result<Packet, ParseError> {
			
			let packetTypeOpt = jlftp.DataLayer.Version_3.PacketType(rawValue: rawPacket.type)
			
			guard let packetType = packetTypeOpt else {
				return .failure(.invalidType)
			}
			
			switch packetType {
			case .initialize:
				return initializePacketParser.parse(fromPayload: rawPacket.dataPayload)
				
			case .version:
				return versionPacketParser.parse(fromPayload: rawPacket.dataPayload)
				
			default:
				return .failure(.invalidType)
			}
			
		}
		
	}
	
}
