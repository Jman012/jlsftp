import Foundation

extension mode_t {

	/**
	 Creates a `mode_t` from the jlsftp Permissions struct, performing the
	 needed tranformations.
	 */
	init(fromPermissions permissions: Permissions) {
		let userMode: [mode_t] = permissions.user.map { perm -> mode_t in
			switch perm {
			case .read: return S_IRUSR
			case .write: return S_IWUSR
			case .execute: return S_IXUSR
			}
		}

		let groupMode: [mode_t] = permissions.group.map { perm -> mode_t in
			switch perm {
			case .read: return S_IRGRP
			case .write: return S_IWGRP
			case .execute: return S_IXGRP
			}
		}

		let otherMode: [mode_t] = permissions.other.map { perm -> mode_t in
			switch perm {
			case .read: return S_IROTH
			case .write: return S_IWOTH
			case .execute: return S_IXOTH
			}
		}

		let modeMode: [mode_t] = permissions.mode.map { perm -> mode_t in
			switch perm {
			case .setUserId: return S_ISUID
			case .setGroupId: return S_ISGID
			case .stickyBit: return S_ISVTX
			}
		}

		let fileType: mode_t
		switch permissions.fileType {
		case .socket:
			fileType = S_IFSOCK
		case .symbolicLink:
			fileType = S_IFLNK
		case .regularFile:
			fileType = S_IFREG
		case .blockDevice:
			fileType = S_IFBLK
		case .directory:
			fileType = S_IFDIR
		case .characterDevice:
			fileType = S_IFCHR
		case .fifo:
			fileType = S_IFIFO
		default:
			fileType = 0
		}

		let modeParts: [mode_t] = userMode + groupMode + otherMode + modeMode + [fileType]
		let mode: mode_t = modeParts.reduce(0, |)
		self.init(mode)
	}
}
