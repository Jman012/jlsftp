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
	}

	public struct PermissionsV3: Equatable {
		let user: PermissionV3
		let group: PermissionV3
		let other: PermissionV3

		var binaryRepresentation: UInt16 {
			return (UInt16(user.rawValue) << 6)
				| (UInt16(group.rawValue) << 3)
				| (UInt16(other.rawValue) << 0)
		}

		var permission: Permissions {
			return Permissions(user: user.permission, group: group.permission, other: other.permission)
		}

		public init(user: PermissionV3, group: PermissionV3, other: PermissionV3) {
			self.user = user
			self.group = group
			self.other = other
		}

		public init(from permissions: Permissions) {
			var userPerm = PermissionV3()
			if permissions.user.contains(.read) {
				userPerm.formUnion(.read)
			}
			if permissions.user.contains(.write) {
				userPerm.formUnion(.write)
			}
			if permissions.user.contains(.execute) {
				userPerm.formUnion(.execute)
			}

			var groupPerm = PermissionV3()
			if permissions.group.contains(.read) {
				groupPerm.formUnion(.read)
			}
			if permissions.group.contains(.write) {
				groupPerm.formUnion(.write)
			}
			if permissions.group.contains(.execute) {
				groupPerm.formUnion(.execute)
			}

			var otherPerm = PermissionV3()
			if permissions.other.contains(.read) {
				otherPerm.formUnion(.read)
			}
			if permissions.other.contains(.write) {
				otherPerm.formUnion(.write)
			}
			if permissions.other.contains(.execute) {
				otherPerm.formUnion(.execute)
			}

			self.user = userPerm
			self.group = groupPerm
			self.other = otherPerm
		}

		public init(fromBinary binary: UInt16) {
			user = PermissionV3(rawValue: UInt8((binary & 0o700) >> 6))
			group = PermissionV3(rawValue: UInt8((binary & 0o070) >> 3))
			other = PermissionV3(rawValue: UInt8((binary & 0o007) >> 0))
		}
	}
}
