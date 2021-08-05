import Foundation

extension mode_t {

	/**
	 Creates a `mode_t` from the jlsftp Permissions struct, performing the
	 needed tranformations.
	 */
	init(fromPermissions permissions: Permissions) {
		let userMode = permissions.user.map { perm -> mode_t in
			switch perm {
			case .read: return S_IRUSR
			case .write: return S_IWUSR
			case .execute: return S_IXUSR
			}
		}

		let groupMode = permissions.group.map { perm -> mode_t in
			switch perm {
			case .read: return S_IRGRP
			case .write: return S_IWGRP
			case .execute: return S_IXGRP
			}
		}

		let otherMode = permissions.other.map { perm -> mode_t in
			switch perm {
			case .read: return S_IROTH
			case .write: return S_IWOTH
			case .execute: return S_IXOTH
			}
		}

		let modeMode = permissions.mode.map { perm -> mode_t in
			switch perm {
			case .setUserId: return S_ISUID
			case .setGroupId: return S_ISGID
			case .stickyBit: return S_ISVTX
			}
		}

		let mode = (userMode + groupMode + otherMode + modeMode).reduce(0, |)
		self.init(mode)
	}
}
