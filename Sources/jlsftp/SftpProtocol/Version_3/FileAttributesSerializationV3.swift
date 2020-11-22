import Foundation
import NIO

extension jlsftp.SftpProtocol.Version_3 {

	/// - Remark: See [https://tools.ietf.org/html/draft-ietf-secsh-filexfer-02#section-5]()
	public struct FileAttributesFlags: OptionSet {
		public let rawValue: UInt32

		public init(rawValue: UInt32) {
			self.rawValue = rawValue
		}

		/// `SSH_FILEXFER_ATTR_SIZE`
		public static let size = FileAttributesFlags(rawValue: 0x0000_0001)
		/// `SSH_FILEXFER_ATTR_UIDGID`
		public static let userAndGroupIds = FileAttributesFlags(rawValue: 0x0000_0002)
		/// `SSH_FILEXFER_ATTR_PERMISSIONS`
		public static let permissions = FileAttributesFlags(rawValue: 0x0000_0004)
		/// `SSH_FILEXFER_ATTR_PERMISSIONS`
		public static let accessAndModificationTimes = FileAttributesFlags(rawValue: 0x0000_0008)
		/// `SSH_FILEXFER_ATTR_EXTENDED`
		public static let extendedAttributes = FileAttributesFlags(rawValue: 0x8000_0000)
	}

	public class FileAttributesSerializationV3 {

		func deserialize(from buffer: inout ByteBuffer) -> Result<FileAttributes, PacketDeserializationHandlerError> {
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
						return .failure(extensionNameResult.error!.customMapError(wrapper: "Failed to deserialize extension name at index \(index)"))
					}

					let extensionDataResult = buffer.readSftpString()
					guard case let .success(extensionData) = extensionDataResult else {
						return .failure(extensionDataResult.error!.customMapError(wrapper: "Failed to deserialize extension data at index \(index)"))
					}

					extensionDataResults.append(ExtensionData(name: extensionName, data: extensionData))
				}
			}

			let fileAttributes = FileAttributes(sizeBytes: size, userId: userId, groupId: groupId, permissions: permissions?.permission, accessDate: accessDate, modifyDate: modifyDate, extensionData: extensionDataResults)
			return .success(fileAttributes)
		}

		func serialize(fileAttrs: FileAttributes, to buffer: inout ByteBuffer) {
			var flags = FileAttributesFlags()

			if fileAttrs.sizeBytes != nil {
				flags.formUnion(.size)
			}
			if fileAttrs.userId != nil || fileAttrs.groupId != nil {
				flags.formUnion(.userAndGroupIds)
			}
			if fileAttrs.permissions != nil {
				flags.formUnion(.permissions)
			}
			if fileAttrs.accessDate != nil || fileAttrs.modifyDate != nil {
				flags.formUnion(.accessAndModificationTimes)
			}
			if !fileAttrs.extensionData.isEmpty {
				flags.formUnion(.extendedAttributes)
			}

			buffer.writeInteger(flags.rawValue, endianness: .big, as: UInt32.self)

			if let sizeBytes = fileAttrs.sizeBytes {
				buffer.writeInteger(sizeBytes, endianness: .big, as: UInt64.self)
			}
			if fileAttrs.userId != nil || fileAttrs.groupId != nil {
				buffer.writeInteger(fileAttrs.userId ?? 0, endianness: .big, as: UInt32.self)
				buffer.writeInteger(fileAttrs.groupId ?? 0, endianness: .big, as: UInt32.self)
			}
			if let permissions = fileAttrs.permissions {
				let permsV3 = PermissionsV3(from: permissions)
				buffer.writeInteger(UInt32(permsV3.binaryRepresentation), endianness: .big, as: UInt32.self)
			}
			if fileAttrs.accessDate != nil || fileAttrs.modifyDate != nil {
				buffer.writeInteger(UInt32(fileAttrs.accessDate?.timeIntervalSince1970 ?? 0), endianness: .big, as: UInt32.self)
				buffer.writeInteger(UInt32(fileAttrs.modifyDate?.timeIntervalSince1970 ?? 0), endianness: .big, as: UInt32.self)
			}
			if !fileAttrs.extensionData.isEmpty {
				for extensionDatum in fileAttrs.extensionData {
					buffer.writeSftpString(extensionDatum.name)
					buffer.writeSftpString(extensionDatum.data)
				}
			}
		}
	}
}
