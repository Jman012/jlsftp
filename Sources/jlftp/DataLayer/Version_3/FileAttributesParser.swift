import Foundation

extension jlftp.DataLayer.Version_3 {

	public struct FileAttributesFlags: OptionSet {
		public let rawValue: UInt32

		public init(rawValue: UInt32) {
			self.rawValue = rawValue
		}

		public static let size = FileAttributesFlags(rawValue: 1 << 0)
		public static let userAndGroupIds = FileAttributesFlags(rawValue: 1 << 1)
		public static let permissions = FileAttributesFlags(rawValue: 1 << 2)
		public static let accessAndModificationTimes = FileAttributesFlags(rawValue: 1 << 3)
		public static let extendedAttributes = FileAttributesFlags(rawValue: 1 << 4)
	}

	public enum FileAttributesParserError: Error {
		case couldNotParse(String)
	}

	public class FileAttributesParser {

		let sshProtocolParser: SSHProtocolParser

		init (sshProtocolParser: SSHProtocolParser) {
			self.sshProtocolParser = sshProtocolParser
		}

		func parse(from data: Data) -> Result<(fileAttributes: FileAttributes?, remainingData: Data), FileAttributesParserError> {
			let (optFlags, remainingDataAfterFlags) = sshProtocolParser.parseUInt32(from: data)
			guard let flagsInt = optFlags else {
				return .failure(.couldNotParse("Could not parse file attribute flags"))
			}
			let flags = FileAttributesFlags(rawValue: flagsInt)

			var remainingData: Data.SubSequence = remainingDataAfterFlags

			var size: UInt64? = nil
			if flags.contains(.size) {
				(size, remainingData) = sshProtocolParser.parseUInt64(from: remainingData)
				if size == nil {
					return .failure(.couldNotParse("Could not parse file attribute file size"))
				}
			}

			var userId, groupId: UInt32?
			if flags.contains(.userAndGroupIds) {
				(userId, remainingData) = sshProtocolParser.parseUInt32(from: remainingData)
				if userId == nil {
					return .failure(.couldNotParse("Could not parse file attribute user id"))
				}
				(groupId, remainingData) = sshProtocolParser.parseUInt32(from: remainingData)
				if groupId == nil {
					return .failure(.couldNotParse("Could not parse file attribute group id"))
				}
			}

			var permissions: Permissions?
			if flags.contains(.permissions) {
				var optPermissionsInt: UInt32?
				(optPermissionsInt, remainingData) = sshProtocolParser.parseUInt32(from: remainingData)
				guard let permissionsInt = optPermissionsInt else {
					return .failure(.couldNotParse("Could not parse file attribute permissions"))
				}
				permissions = Permissions(fromBinary: UInt16(truncatingIfNeeded: permissionsInt))
			}

			var accessDate, modifyDate: Date?
			if flags.contains(.accessAndModificationTimes) {
				var optAccessTime, optModifyTime: UInt32?
				(optAccessTime, remainingData) = sshProtocolParser.parseUInt32(from: remainingData)
				guard let accessTime = optAccessTime else {
					return .failure(.couldNotParse("Could not parse file attribute access time"))
				}
				(optModifyTime, remainingData) = sshProtocolParser.parseUInt32(from: remainingData)
				guard let modifyTime = optModifyTime else {
					return .failure(.couldNotParse("Could not parse file attribute modify time"))
				}
				accessDate = Date(timeIntervalSince1970: TimeInterval(accessTime))
				modifyDate = Date(timeIntervalSince1970: TimeInterval(modifyTime))
			}

			var extensionData: [ExtensionData] = []
			if flags.contains(.extendedAttributes) {
				var optExtensionCount: UInt32?
				(optExtensionCount, remainingData) = sshProtocolParser.parseUInt32(from: remainingData)
				guard let extensionCount = optExtensionCount else {
					return .failure(.couldNotParse("Could not parse file attribute extended attribute count"))
				}
				for index in 0..<extensionCount {
					var optStringName, optStringData: String?
					(optStringName, remainingData) = sshProtocolParser.parseString(from: remainingData)
					guard let stringName = optStringName else {
						return .failure(.couldNotParse("Could not parse file attribute extended attribute name at index \(index)"))
					}
					(optStringData, remainingData) = sshProtocolParser.parseString(from: remainingData)
					guard let stringData = optStringData else {
						return .failure(.couldNotParse("Could not parse file attribute extended attribute data at index \(index)"))
					}
					extensionData.append(ExtensionData(name: stringName, data: stringData))
				}
			}

			let fileAttributes = FileAttributes(sizeBytes: size, userId: userId, groupId: groupId, permissions: permissions, accessDate: accessDate, modifyDate: modifyDate, extensionData: extensionData)
			return.success((fileAttributes, remainingData))
		}
	}
}
