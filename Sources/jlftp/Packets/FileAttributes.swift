//
//  File.swift
//  
//
//  Created by James Linnell on 7/5/20.
//

import Foundation

public struct Permission: OptionSet {
	public let rawValue: UInt8

	public init(rawValue: UInt8) {
		self.rawValue = rawValue
	}

	static let execute = Permission(rawValue: 1 << 0) // 0b001, 0o1
	static let write = Permission(rawValue: 1 << 1) // 0b010, 0o2
	static let read = Permission(rawValue: 1 << 2) // 0b100, 0o4
}

public struct Permissions {
	let user: Permission
	let group: Permission
	let other: Permission

	var binaryRepresentation: UInt16 {
		return (UInt16(user.rawValue) << 6)
			| (UInt16(group.rawValue) << 3)
			| (UInt16(other.rawValue) << 0)
	}

	public init(user: Permission, group: Permission, other: Permission) {
		self.user = user;
		self.group = group
		self.other = other
	}

	public init(fromBinary binary: UInt16) {
		user = Permission(rawValue: UInt8((binary & 0o700) >> 6))
		group = Permission(rawValue: UInt8((binary & 0o070) >> 3))
		other = Permission(rawValue: UInt8((binary & 0o007) >> 0))
	}
}

public struct FileAttributes {
	let sizeBytes: UInt64?
	let userId: UInt32?
	let groupId: UInt32?
	let permissions: Permissions?
	let accessDate: Date?
	let modifyDate: Date?
	let extensionData: [ExtensionData]
}
