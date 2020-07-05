import Foundation

public class VersionPacketParserHandler: SftpVersion3PacketParserHandler {

	let sshProtocolParser: SSHProtocolParser

	init(sshProtocolParser: SSHProtocolParser) {
		self.sshProtocolParser = sshProtocolParser
	}

	public func parse(fromPayload data: Data) -> Result<Packet, jlftp.DataLayer.Version_3.PacketParser.ParseError> {
		// Version
		let (optVersion, remainingDataAfterVersion) = sshProtocolParser.parseUInt32(from: data)
		guard let versionByte = optVersion else {
			return .failure(.payloadTooShort)
		}

		let optSftpVersion = jlftp.DataLayer.SftpVersion(rawValue: versionByte)
		guard let sftpVersion = optSftpVersion else {
			return .failure(.invalidDataPayload(reason: "Version field \(versionByte) is not supported."))
		}

		// Rest of the data: extension data of the form of pairs of strings
		var remainingData = remainingDataAfterVersion
		var extensionDataResults: [jlftp.DataLayer.ExtensionData] = []
		while !remainingData.isEmpty {
			let (optExtensionName, remainingDataAfterExtensionName) = sshProtocolParser.parseString(from: remainingData)
			guard let extensionName = optExtensionName else {
				break
			}

			let (optExtensionData, remainingDataAfterExtensionData) = sshProtocolParser.parseString(from: remainingDataAfterExtensionName)
			guard let extensionData = optExtensionData else {
				break
			}

			extensionDataResults.append(jlftp.DataLayer.ExtensionData(name: extensionName, data: extensionData))
			remainingData = remainingDataAfterExtensionData
		}

		return .success(jlftp.Packets.VersionPacket(version: sftpVersion, extensionData: extensionDataResults))
	}
}
