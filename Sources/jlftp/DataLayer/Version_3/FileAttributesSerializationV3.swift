import Foundation

extension jlftp.DataLayer.Version_3 {

	/// - Remark: See [https://tools.ietf.org/html/draft-ietf-secsh-filexfer-02#section-5]()
	public struct FileAttributesFlags: OptionSet {
		public let rawValue: UInt32

		public init(rawValue: UInt32) {
			self.rawValue = rawValue
		}

		public static let size = FileAttributesFlags(rawValue: 0x0000_0001)
		public static let userAndGroupIds = FileAttributesFlags(rawValue: 0x0000_0002)
		public static let permissions = FileAttributesFlags(rawValue: 0x0000_0004)
		public static let accessAndModificationTimes = FileAttributesFlags(rawValue: 0x0000_0008)
		public static let extendedAttributes = FileAttributesFlags(rawValue: 0x8000_0000)
	}

	public class FileAttributesSerializationV3 {

		public enum DeserializationError: Error {
			case couldNotDeserialize(String)
		}

		let sshProtocolSerialization: SSHProtocolSerialization

		init(sshProtocolSerialization: SSHProtocolSerialization) {
			self.sshProtocolSerialization = sshProtocolSerialization
		}

		func deserialize(from data: Data) -> Result<(fileAttributes: FileAttributes?, remainingData: Data), DeserializationError> {
			let (optFlags, remainingDataAfterFlags) = sshProtocolSerialization.deserializeUInt32(from: data)
			guard let flagsInt = optFlags else {
				return .failure(.couldNotDeserialize("Could not deserialize file attribute flags"))
			}
			let flags = FileAttributesFlags(rawValue: flagsInt)

			var remainingData: Data.SubSequence = remainingDataAfterFlags

			var size: UInt64?
			if flags.contains(.size) {
				(size, remainingData) = sshProtocolSerialization.deserializeUInt64(from: remainingData)
				if size == nil {
					return .failure(.couldNotDeserialize("Could not deserialize file attribute file size"))
				}
			}

			var userId, groupId: UInt32?
			if flags.contains(.userAndGroupIds) {
				(userId, remainingData) = sshProtocolSerialization.deserializeUInt32(from: remainingData)
				if userId == nil {
					return .failure(.couldNotDeserialize("Could not deserialize file attribute user id"))
				}
				(groupId, remainingData) = sshProtocolSerialization.deserializeUInt32(from: remainingData)
				if groupId == nil {
					return .failure(.couldNotDeserialize("Could not deserialize file attribute group id"))
				}
			}

			var permissions: PermissionsV3?
			if flags.contains(.permissions) {
				var optPermissionsInt: UInt32?
				(optPermissionsInt, remainingData) = sshProtocolSerialization.deserializeUInt32(from: remainingData)
				guard let permissionsInt = optPermissionsInt else {
					return .failure(.couldNotDeserialize("Could not deserialize file attribute permissions"))
				}
				permissions = PermissionsV3(fromBinary: UInt16(truncatingIfNeeded: permissionsInt))
			}

			var accessDate, modifyDate: Date?
			if flags.contains(.accessAndModificationTimes) {
				var optAccessTime, optModifyTime: UInt32?
				(optAccessTime, remainingData) = sshProtocolSerialization.deserializeUInt32(from: remainingData)
				guard let accessTime = optAccessTime else {
					return .failure(.couldNotDeserialize("Could not deserialize file attribute access time"))
				}
				(optModifyTime, remainingData) = sshProtocolSerialization.deserializeUInt32(from: remainingData)
				guard let modifyTime = optModifyTime else {
					return .failure(.couldNotDeserialize("Could not deserialize file attribute modify time"))
				}
				accessDate = Date(timeIntervalSince1970: TimeInterval(accessTime))
				modifyDate = Date(timeIntervalSince1970: TimeInterval(modifyTime))
			}

			var extensionData: [ExtensionData] = []
			if flags.contains(.extendedAttributes) {
				var optExtensionCount: UInt32?
				(optExtensionCount, remainingData) = sshProtocolSerialization.deserializeUInt32(from: remainingData)
				guard let extensionCount = optExtensionCount else {
					return .failure(.couldNotDeserialize("Could not deserialize file attribute extended attribute count"))
				}
				for index in 0..<extensionCount {
					var optStringName, optStringData: String?
					(optStringName, remainingData) = sshProtocolSerialization.deserializeString(from: remainingData)
					guard let stringName = optStringName else {
						return .failure(.couldNotDeserialize("Could not deserialize file attribute extended attribute name at index \(index)"))
					}
					(optStringData, remainingData) = sshProtocolSerialization.deserializeString(from: remainingData)
					guard let stringData = optStringData else {
						return .failure(.couldNotDeserialize("Could not deserialize file attribute extended attribute data at index \(index)"))
					}
					extensionData.append(ExtensionData(name: stringName, data: stringData))
				}
			}

			let fileAttributes = FileAttributes(sizeBytes: size, userId: userId, groupId: groupId, permissions: permissions?.permission, accessDate: accessDate, modifyDate: modifyDate, extensionData: extensionData)
			return .success((fileAttributes, remainingData))
		}
	}
}
