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

public enum PermissionFileType {
	case socket
	case symbolicLink
	case regularFile
	case blockDevice
	case directory
	case characterDevice
	case fifo
}

public struct Permissions {
	public let user: Set<Permission>
	public let group: Set<Permission>
	public let other: Set<Permission>
	public let mode: Set<PermissionMode>
	public let fileType: PermissionFileType?

	public init(user: Set<Permission>, group: Set<Permission>, other: Set<Permission>, mode: Set<PermissionMode>, fileType: PermissionFileType?) {
		self.user = user
		self.group = group
		self.other = other
		self.mode = mode
		self.fileType = fileType
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

		var fileType: PermissionFileType?
		switch mode & S_IFMT {
		case S_IFSOCK:
			fileType = .socket
		case S_IFLNK:
			fileType = .symbolicLink
		case S_IFREG:
			fileType = .regularFile
		case S_IFBLK:
			fileType = .blockDevice
		case S_IFDIR:
			fileType = .directory
		case S_IFCHR:
			fileType = .characterDevice
		case S_IFIFO:
			fileType = .fifo
		default:
			fileType = nil
		}

		self.user = user
		self.group = group
		self.other = other
		self.mode = modeSet
		self.fileType = fileType
	}
}

extension Permissions: Equatable {}
