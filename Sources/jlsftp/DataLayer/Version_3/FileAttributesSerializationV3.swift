import Foundation
import NIO

extension jlsftp.DataLayer.Version_3 {

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

		func deserialize(from buffer: inout ByteBuffer) -> Result<FileAttributes, PacketSerializationHandlerError> {
			guard let flagsInt = buffer.readInteger(endianness: .big, as: UInt32.self) else {
				return .failure(.needMoreData)
			}
			let flags = FileAttributesFlags(rawValue: flagsInt)

			var size: UInt64?
			if flags.contains(.size) {
				size = buffer.readInteger(endianness: .big, as: UInt64.self)
				guard size != nil else {
					return .failure(.needMoreData)
				}
			}

			var userId, groupId: UInt32?
			if flags.contains(.userAndGroupIds) {
				userId = buffer.readInteger(endianness: .big, as: UInt32.self)
				guard userId != nil else {
					return .failure(.needMoreData)
				}
				groupId = buffer.readInteger(endianness: .big, as: UInt32.self)
				guard groupId != nil else {
					return .failure(.needMoreData)
				}
			}

			var permissions: PermissionsV3?
			if flags.contains(.permissions) {
				guard let permissionsInt = buffer.readInteger(endianness: .big, as: UInt32.self) else {
					return .failure(.needMoreData)
				}
				permissions = PermissionsV3(fromBinary: UInt16(truncatingIfNeeded: permissionsInt))
			}

			var accessDate, modifyDate: Date?
			if flags.contains(.accessAndModificationTimes) {
				guard let accessTime = buffer.readInteger(endianness: .big, as: UInt32.self),
					let modifyTime = buffer.readInteger(endianness: .big, as: UInt32.self) else {
					return .failure(.needMoreData)
				}
				accessDate = Date(timeIntervalSince1970: TimeInterval(accessTime))
				modifyDate = Date(timeIntervalSince1970: TimeInterval(modifyTime))
			}

			var extensionDataResults: [ExtensionData] = []
			if flags.contains(.extendedAttributes) {
				guard let extensionCount = buffer.readInteger(endianness: .big, as: UInt32.self) else {
					return .failure(.needMoreData)
				}

				for index in 0..<extensionCount {
					let extensionNameResult = buffer.readSftpString()
					guard case let .success(extensionName) = extensionNameResult else {
						return .failure(.invalidData(reason: "Failed to deserialize extension name at index \(index): \(extensionNameResult.error!)"))
					}

					let extensionDataResult = buffer.readSftpString()
					guard case let .success(extensionData) = extensionDataResult else {
						return .failure(.invalidData(reason: "Failed to deserialize extension data at index \(index): \(extensionDataResult.error!)"))
					}

					extensionDataResults.append(ExtensionData(name: extensionName, data: extensionData))
				}
			}

			let fileAttributes = FileAttributes(sizeBytes: size, userId: userId, groupId: groupId, permissions: permissions?.permission, accessDate: accessDate, modifyDate: modifyDate, extensionData: extensionDataResults)
			return .success(fileAttributes)
		}
	}
}
