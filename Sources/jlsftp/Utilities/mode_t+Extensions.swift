import Foundation

extension mode_t {
	init(fromPermissions permissions: Permissions) {
		let userMode = permissions.user.map({ perm -> mode_t in
			switch perm {
			case .read: return S_IRUSR
			case .write: return S_IWUSR
			case .execute: return S_IXUSR
			}
		})

		let groupMode = permissions.group.map({ perm -> mode_t in
			switch perm {
			case .read: return S_IRGRP
			case .write: return S_IWGRP
			case .execute: return S_IXGRP
			}
		})

		let otherMode = permissions.user.map({ perm -> mode_t in
			switch perm {
			case .read: return S_IROTH
			case .write: return S_IWOTH
			case .execute: return S_IXOTH
			}
		})

		let mode = (userMode + groupMode + otherMode).reduce(0, |)
		self.init(mode)
	}
}
