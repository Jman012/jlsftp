import Foundation

public enum Permission {
	case read
	case write
	case execute
}

public struct Permissions {
	let user: Set<Permission>
	let group: Set<Permission>
	let other: Set<Permission>

	public init(user: Set<Permission>, group: Set<Permission>, other: Set<Permission>) {
		self.user = user
		self.group = group
		self.other = other
	}
}
