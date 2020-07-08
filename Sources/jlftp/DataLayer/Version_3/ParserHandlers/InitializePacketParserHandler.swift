import Foundation

extension jlftp.DataLayer.Version_3 {

	public class InitializePacketParserHandler: SftpVersion3PacketParserHandler {

		let sshProtocolSerialization: SSHProtocolSerialization

		init(sshProtocolSerialization: SSHProtocolSerialization) {
			self.sshProtocolSerialization = sshProtocolSerialization
		}

		public func parse(fromPayload data: Data) -> Result<Packet, jlftp.DataLayer.Version_3.PacketParser.ParseError> {
			// Version
			let (optVersion, remainingDataAfterVersion) = sshProtocolSerialization.deserializeUInt32(from: data)
			guard let versionByte = optVersion else {
				return .failure(.payloadTooShort)
			}

			let optSftpVersion = jlftp.DataLayer.SftpVersion(rawValue: versionByte)
			guard let sftpVersion = optSftpVersion else {
				return .failure(.invalidDataPayload(reason: "Version field \(versionByte) is not supported."))
			}

			// Rest of the data: extension data of the form of pairs of strings
			var remainingData = remainingDataAfterVersion
			var extensionDataResults: [ExtensionData] = []
			while !remainingData.isEmpty {
				let (optExtensionName, remainingDataAfterExtensionName) = sshProtocolSerialization.deserializeString(from: remainingData)
				guard let extensionName = optExtensionName else {
					break
				}

				let (optExtensionData, remainingDataAfterExtensionData) = sshProtocolSerialization.deserializeString(from: remainingDataAfterExtensionName)
				guard let extensionData = optExtensionData else {
					break
				}

				extensionDataResults.append(ExtensionData(name: extensionName, data: extensionData))
				remainingData = remainingDataAfterExtensionData
			}

			return .success(InitializePacket(version: sftpVersion, extensionData: extensionDataResults))
		}
	}
}
