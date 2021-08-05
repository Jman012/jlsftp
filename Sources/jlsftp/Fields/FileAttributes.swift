import Foundation

public struct FileAttributes {

	private static let dateFormatter = DateFormatter(format: "MMM dd hh:mm")

	let sizeBytes: UInt64?
	let userId: UInt32?
	let groupId: UInt32?
	let permissions: Permissions?
	let accessDate: Date?
	let modifyDate: Date?
	let linkCount: UInt16?
	let extensionData: [ExtensionData]

	static let empty: FileAttributes = .init(
		sizeBytes: nil,
		userId: nil,
		groupId: nil,
		permissions: nil,
		accessDate: nil,
		modifyDate: nil,
		linkCount: nil,
		extensionData: [])

	public init(sizeBytes: UInt64?,
				userId: UInt32?,
				groupId: UInt32?,
				permissions: Permissions?,
				accessDate: Date?,
				modifyDate: Date?,
				linkCount: UInt16?,
				extensionData: [ExtensionData]
	) {
		self.sizeBytes = sizeBytes
		self.userId = userId
		self.groupId = groupId
		self.permissions = permissions
		self.accessDate = accessDate
		self.modifyDate = modifyDate
		self.linkCount = linkCount
		self.extensionData = extensionData
	}

	public init(stat statResult: stat, extensionData: [ExtensionData]) {
		self.sizeBytes = UInt64(statResult.st_size) // TODO:
		self.userId = statResult.st_uid
		self.groupId = statResult.st_gid
		self.permissions = Permissions(mode: statResult.st_mode)
		self.accessDate = statResult.st_atimespec.date
		self.modifyDate = statResult.st_mtimespec.date
		self.linkCount = statResult.st_nlink
		self.extensionData = extensionData
	}

	public func longName(shortName: String) -> String {
		/*
		The recommended format of this string is:
		```
		-rwxr-xr-x   1 mjos     staff      348911 Mar 25 14:29 t-filexfer
		1234567890 123 12345678 12345678 12345678 123456789012
		```
		*/

		var permissionCharacters: [Character] = .init(repeating: "-", count: 10)
		if let permissions = self.permissions {
			if permissions.user.contains(.read) {
				permissionCharacters[1] = "r"
			}
			if permissions.user.contains(.write) {
				permissionCharacters[2] = "w"
			}
			if permissions.user.contains(.execute) {
				permissionCharacters[3] = "x"
			}
			if permissions.group.contains(.read) {
				permissionCharacters[4] = "r"
			}
			if permissions.group.contains(.write) {
				permissionCharacters[5] = "w"
			}
			if permissions.group.contains(.execute) {
				permissionCharacters[6] = "x"
			}
			if permissions.other.contains(.read) {
				permissionCharacters[7] = "r"
			}
			if permissions.other.contains(.write) {
				permissionCharacters[8] = "w"
			}
			if permissions.other.contains(.execute) {
				permissionCharacters[9] = "x"
			}
		}

		var links = String(repeating: " ", count: 3)
		if let linkCount = self.linkCount {
			links = String(linkCount).padding(leftToLength: 3, withPad: " ")
		}

		var user = String(repeating: " ", count: 8)
		if let userId = self.userId {
			if let name = try? syscall({ getpwuid(userId) })?.pointee.pw_name {
				user = String(cString: name).padding(toLength: 8, withPad: " ", startingAt: 0)
			}
		}

		var group = String(repeating: " ", count: 8)
		if let groupId = self.groupId {
			if let name = try? syscall({ getgrgid(groupId) })?.pointee.gr_name {
				group = String(cString: name).padding(toLength: 8, withPad: " ", startingAt: 0)
			}
		}

		var size = String(repeating: " ", count: 8)
		if let sizeBytes = self.sizeBytes {
			size = String(sizeBytes).padding(leftToLength: 8, withPad: " ")
		}

		var modificationDate = String(repeating: " ", count: 12)
		if let modifyDate = self.modifyDate {
			modificationDate = FileAttributes.dateFormatter.string(from: modifyDate)
		}

		return String(permissionCharacters) + " " + links + " " + user + " " +
			group + " " + size + " " + modificationDate + " " + shortName
	}
}

extension FileAttributes: Equatable {}
