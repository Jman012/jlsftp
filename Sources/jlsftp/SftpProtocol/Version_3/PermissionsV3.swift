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

	public struct PermissionsV3: Equatable {
		let user: PermissionV3
		let group: PermissionV3
		let other: PermissionV3
		/// Re-use PermissionV3 for S_ISUID, S_ISGID, and S_ISVTX.
		let mode: PermissionV3

		var binaryRepresentation: UInt16 {
			return (UInt16(user.rawValue) << 6)
				| (UInt16(group.rawValue) << 3)
				| (UInt16(other.rawValue) << 0)
				| (UInt16(mode.rawValue) << 9)
		}

		var permission: Permissions {
			return Permissions(user: user.permission,
							   group: group.permission,
							   other: other.permission,
							   mode: mode.permissionMode)
		}

		public init(user: PermissionV3, group: PermissionV3, other: PermissionV3, mode: PermissionV3) {
			self.user = user
			self.group = group
			self.other = other
			self.mode = mode
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

			self.user = userPerm
			self.group = groupPerm
			self.other = otherPerm
			self.mode = modePerm
		}

		public init(fromBinary binary: UInt16) {
			user = PermissionV3(rawValue: UInt8((binary & 0o0700) >> 6))
			group = PermissionV3(rawValue: UInt8((binary & 0o0070) >> 3))
			other = PermissionV3(rawValue: UInt8((binary & 0o0007) >> 0))
			mode = PermissionV3(rawValue: UInt8((binary & 0o7000) >> 9))
		}
	}
}
