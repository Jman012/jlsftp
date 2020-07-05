import Foundation

public class VersionPacketParserHandler: SftpVersion3PacketParserHandler {
	
	public func parse(fromPayload data: Data) -> Result<Packet, jlftp.DataLayer.Version_3.PacketParser.ParseError> {
		guard data.count >= 4 else { return .failure(.payloadTooShort) }
		
		let versionByte = data[0..<4].to(type: UInt32.self) ?? 0
		let sftpVersionOpt = jlftp.DataLayer.SftpVersion(rawValue: versionByte)
		guard let sftpVersion = sftpVersionOpt else {
			return .failure(.invalidDataPayload(reason: "Version field \(versionByte) is not supported."))
		}
		
		// TODO: Parse extension data.
		
		return .success(jlftp.Packets.InitializePacket(version: sftpVersion, extensionData: []))
	}
	
}
