import Foundation

public struct FileAttributes {
	let sizeBytes: UInt64?
	let userId: UInt32?
	let groupId: UInt32?
	let permissions: Permissions?
	let accessDate: Date?
	let modifyDate: Date?
	let extensionData: [ExtensionData]

	static let empty: FileAttributes = .init(
		sizeBytes: nil,
		userId: nil,
		groupId: nil,
		permissions: nil,
		accessDate: nil,
		modifyDate: nil,
		extensionData: [])
}

extension FileAttributes: Equatable {}
