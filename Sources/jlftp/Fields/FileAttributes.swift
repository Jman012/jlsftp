import Foundation

public struct FileAttributes {
	let sizeBytes: UInt64?
	let userId: UInt32?
	let groupId: UInt32?
	let permissions: Permissions?
	let accessDate: Date?
	let modifyDate: Date?
	let extensionData: [ExtensionData]
}

extension FileAttributes: Equatable {}
