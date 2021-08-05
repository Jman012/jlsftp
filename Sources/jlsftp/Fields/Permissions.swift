import Foundation

public enum Permission {
	case read
	case write
	case execute
}

public enum PermissionMode {
	case setUserId
	case setGroupId
	case stickyBit
}

public struct Permissions {
	public let user: Set<Permission>
	public let group: Set<Permission>
	public let other: Set<Permission>
	public let mode: Set<PermissionMode>

	public init(user: Set<Permission>, group: Set<Permission>, other: Set<Permission>, mode: Set<PermissionMode>) {
		self.user = user
		self.group = group
		self.other = other
		self.mode = mode
	}

	public init(mode: mode_t) {
		var user: Set<Permission> = []
		if mode & S_IRUSR == S_IRUSR {
			user.insert(.read)
		}
		if mode & S_IWUSR == S_IWUSR {
			user.insert(.write)
		}
		if mode & S_IXUSR == S_IXUSR {
			user.insert(.execute)
		}

		var group: Set<Permission> = []
		if mode & S_IRGRP == S_IRGRP {
			group.insert(.read)
		}
		if mode & S_IWGRP == S_IWGRP {
			group.insert(.write)
		}
		if mode & S_IXGRP == S_IXGRP {
			group.insert(.execute)
		}

		var other: Set<Permission> = []
		if mode & S_IROTH == S_IROTH {
			other.insert(.read)
		}
		if mode & S_IWOTH == S_IWOTH {
			other.insert(.write)
		}
		if mode & S_IXOTH == S_IXOTH {
			other.insert(.execute)
		}

		var modeSet: Set<PermissionMode> = []
		if mode & S_ISUID == S_ISUID {
			modeSet.insert(.setUserId)
		}
		if mode & S_ISGID == S_ISGID {
			modeSet.insert(.setGroupId)
		}
		if mode & S_ISVTX == S_ISVTX {
			modeSet.insert(.stickyBit)
		}

		self.user = user
		self.group = group
		self.other = other
		self.mode = modeSet
	}
}

extension Permissions: Equatable {}
