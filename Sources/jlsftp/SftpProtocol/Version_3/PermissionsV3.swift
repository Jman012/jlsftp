import Foundation

extension jlsftp.SftpProtocol.Version_3 {

	public struct PermissionV3: OptionSet {
		public let rawValue: UInt8

		public init(rawValue: UInt8) {
			self.rawValue = rawValue
		}

		static let execute = PermissionV3(rawValue: 1 << 0) // 0b001, 0o1
		static let write = PermissionV3(rawValue: 1 << 1) // 0b010, 0o2
		static let read = PermissionV3(rawValue: 1 << 2) // 0b100, 0o4

		var permission: Set<Permission> {
			var perms = Set<Permission>()
			if self.contains(.execute) { perms.insert(.execute) }
			if self.contains(.write) { perms.insert(.write) }
			if self.contains(.read) { perms.insert(.read) }
			return perms
		}

		var permissionMode: Set<PermissionMode> {
			var perms = Set<PermissionMode>()
			if self.contains(.execute) { perms.insert(.stickyBit) }
			if self.contains(.write) { perms.insert(.setGroupId) }
			if self.contains(.read) { perms.insert(.setUserId) }
			return perms
		}
	}

	public enum PermissionFileTypeV3: UInt8 {
		case socket = 0o14
		case symbolicLink = 0o12
		case regularFile = 0o10
		case blockDevice = 0o06
		case directory = 0o04
		case characterDevice = 0o02
		case fifo = 0o01

		var permissionFileType: PermissionFileType {
			switch self {
			case .socket:
				return .socket
			case .symbolicLink:
				return .symbolicLink
			case .regularFile:
				return .regularFile
			case .blockDevice:
				return .blockDevice
			case .directory:
				return .directory
			case .characterDevice:
				return .characterDevice
			case .fifo:
				return .fifo
			}
		}
	}

	public struct PermissionsV3: Equatable {
		let user: PermissionV3
		let group: PermissionV3
		let other: PermissionV3
		/// Re-use PermissionV3 for S_ISUID, S_ISGID, and S_ISVTX.
		let mode: PermissionV3
		let fileType: PermissionFileTypeV3?

		var binaryRepresentation: UInt16 {
			return (UInt16(user.rawValue) << 6)
				| (UInt16(group.rawValue) << 3)
				| (UInt16(other.rawValue) << 0)
				| (UInt16(mode.rawValue) << 9)
				| (UInt16(fileType?.rawValue ?? 0) << 12)
		}

		var permission: Permissions {
			return Permissions(user: user.permission,
							   group: group.permission,
							   other: other.permission,
							   mode: mode.permissionMode,
							   fileType: fileType?.permissionFileType)
		}

		public init(user: PermissionV3, group: PermissionV3, other: PermissionV3, mode: PermissionV3, fileType: PermissionFileTypeV3?) {
			self.user = user
			self.group = group
			self.other = other
			self.mode = mode
			self.fileType = fileType
		}

		public init(from permissions: Permissions) {
			var userPerm = PermissionV3()
			if permissions.user.contains(.read) {
				userPerm.insert(.read)
			}
			if permissions.user.contains(.write) {
				userPerm.insert(.write)
			}
			if permissions.user.contains(.execute) {
				userPerm.insert(.execute)
			}

			var groupPerm = PermissionV3()
			if permissions.group.contains(.read) {
				groupPerm.insert(.read)
			}
			if permissions.group.contains(.write) {
				groupPerm.insert(.write)
			}
			if permissions.group.contains(.execute) {
				groupPerm.insert(.execute)
			}

			var otherPerm = PermissionV3()
			if permissions.other.contains(.read) {
				otherPerm.insert(.read)
			}
			if permissions.other.contains(.write) {
				otherPerm.insert(.write)
			}
			if permissions.other.contains(.execute) {
				otherPerm.insert(.execute)
			}

			var modePerm = PermissionV3()
			if permissions.mode.contains(.setUserId) {
				modePerm.insert(.read)
			}
			if permissions.mode.contains(.setGroupId) {
				modePerm.insert(.write)
			}
			if permissions.mode.contains(.stickyBit) {
				modePerm.insert(.execute)
			}

			var fileType: PermissionFileTypeV3?
			switch permissions.fileType {
			case .socket:
				fileType = .socket
			case .symbolicLink:
				fileType = .symbolicLink
			case .regularFile:
				fileType = .regularFile
			case .blockDevice:
				fileType = .blockDevice
			case .directory:
				fileType = .directory
			case .characterDevice:
				fileType = .characterDevice
			case .fifo:
				fileType = .fifo
			default:
				fileType = nil
			}

			self.user = userPerm
			self.group = groupPerm
			self.other = otherPerm
			self.mode = modePerm
			self.fileType = fileType

		}

		public init(fromBinary binary: UInt16) {
			user = PermissionV3(rawValue: UInt8((binary & 0o0700) >> 6))
			group = PermissionV3(rawValue: UInt8((binary & 0o0070) >> 3))
			other = PermissionV3(rawValue: UInt8((binary & 0o0007) >> 0))
			mode = PermissionV3(rawValue: UInt8((binary & 0o7000) >> 9))
			fileType = PermissionFileTypeV3(rawValue: UInt8((binary & 0o170000) >> 12))
		}
	}
}
