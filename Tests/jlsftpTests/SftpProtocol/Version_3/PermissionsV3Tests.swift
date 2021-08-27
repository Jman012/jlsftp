import XCTest
@testable import jlsftp

final class PermissionsV3Tests: XCTestCase {

	let testCases: [(
		binary: UInt16,
		expUser: jlsftp.SftpProtocol.Version_3.PermissionV3,
		expGroup: jlsftp.SftpProtocol.Version_3.PermissionV3,
		expOther: jlsftp.SftpProtocol.Version_3.PermissionV3,
		expMode: jlsftp.SftpProtocol.Version_3.PermissionV3,
		expFileType: jlsftp.SftpProtocol.Version_3.PermissionFileTypeV3?,
		expPerms: Permissions
	)] = [
		(0o000000, [], [], [], [], nil,
		 Permissions(user: [], group: [], other: [], mode: [], fileType: nil)),
		// Test Other
		(0o000001, [], [], [.execute], [], nil,
		 Permissions(user: [], group: [], other: [.execute], mode: [], fileType: nil)),
		(0o000002, [], [], [.write], [], nil,
		 Permissions(user: [], group: [], other: [.write], mode: [], fileType: nil)),
		(0o000003, [], [], [.write, .execute], [], nil,
		 Permissions(user: [], group: [], other: [.write, .execute], mode: [], fileType: nil)),
		(0o000004, [], [], [.read], [], nil,
		 Permissions(user: [], group: [], other: [.read], mode: [], fileType: nil)),
		(0o000005, [], [], [.read, .execute], [], nil,
		 Permissions(user: [], group: [], other: [.read, .execute], mode: [], fileType: nil)),
		(0o000006, [], [], [.read, .write], [], nil,
		 Permissions(user: [], group: [], other: [.read, .write], mode: [], fileType: nil)),
		(0o000007, [], [], [.read, .write, .execute], [], nil,
		 Permissions(user: [], group: [], other: [.read, .write, .execute], mode: [], fileType: nil)),
		// Test Group
		(0o000010, [], [.execute], [], [], nil,
		 Permissions(user: [], group: [.execute], other: [], mode: [], fileType: nil)),
		(0o000020, [], [.write], [], [], nil,
		 Permissions(user: [], group: [.write], other: [], mode: [], fileType: nil)),
		(0o000030, [], [.write, .execute], [], [], nil,
		 Permissions(user: [], group: [.write, .execute], other: [], mode: [], fileType: nil)),
		(0o000040, [], [.read], [], [], nil,
		 Permissions(user: [], group: [.read], other: [], mode: [], fileType: nil)),
		(0o000050, [], [.read, .execute], [], [], nil,
		 Permissions(user: [], group: [.read, .execute], other: [], mode: [], fileType: nil)),
		(0o000060, [], [.read, .write], [], [], nil,
		 Permissions(user: [], group: [.read, .write], other: [], mode: [], fileType: nil)),
		(0o000070, [], [.read, .write, .execute], [], [], nil,
		 Permissions(user: [], group: [.read, .write, .execute], other: [], mode: [], fileType: nil)),
		// Test User
		(0o000100, [.execute], [], [], [], nil,
		 Permissions(user: [.execute], group: [], other: [], mode: [], fileType: nil)),
		(0o000200, [.write], [], [], [], nil,
		 Permissions(user: [.write], group: [], other: [], mode: [], fileType: nil)),
		(0o000300, [.write, .execute], [], [], [], nil,
		 Permissions(user: [.write, .execute], group: [], other: [], mode: [], fileType: nil)),
		(0o000400, [.read], [], [], [], nil,
		 Permissions(user: [.read], group: [], other: [], mode: [], fileType: nil)),
		(0o000500, [.read, .execute], [], [], [], nil,
		 Permissions(user: [.read, .execute], group: [], other: [], mode: [], fileType: nil)),
		(0o000600, [.read, .write], [], [], [], nil,
		 Permissions(user: [.read, .write], group: [], other: [], mode: [], fileType: nil)),
		(0o000700, [.read, .write, .execute], [], [], [], nil,
		 Permissions(user: [.read, .write, .execute], group: [], other: [], mode: [], fileType: nil)),
		// Test Mode
		(0o140000, [], [], [], [], .socket,
		 Permissions(user: [], group: [], other: [], mode: [], fileType: .socket)),
		(0o120000, [], [], [], [], .symbolicLink,
		 Permissions(user: [], group: [], other: [], mode: [], fileType: .symbolicLink)),
		(0o100000, [], [], [], [], .regularFile,
		 Permissions(user: [], group: [], other: [], mode: [], fileType: .regularFile)),
		(0o060000, [], [], [], [], .blockDevice,
		 Permissions(user: [], group: [], other: [], mode: [], fileType: .blockDevice)),
		(0o040000, [], [], [], [], .directory,
		 Permissions(user: [], group: [], other: [], mode: [], fileType: .directory)),
		(0o020000, [], [], [], [], .characterDevice,
		 Permissions(user: [], group: [], other: [], mode: [], fileType: .characterDevice)),
		(0o010000, [], [], [], [], .fifo,
		 Permissions(user: [], group: [], other: [], mode: [], fileType: .fifo)),
		(0o000000, [], [], [], [], nil,
		 Permissions(user: [], group: [], other: [], mode: [], fileType: nil)),
		// Test mixed
		(0o100754, [.read, .write, .execute], [.read, .execute], [.read], [], .regularFile,
		 Permissions(user: [.read, .write, .execute], group: [.read, .execute], other: [.read], mode: [], fileType: .regularFile)),
	]

	func testInitFromBinary() {
		for (binary, expUser, expGroup, expOther, expMode, expFileType, _) in testCases {
			let perm = jlsftp.SftpProtocol.Version_3.PermissionsV3(fromBinary: binary)

			XCTAssertEqual(expUser, perm.user)
			XCTAssertEqual(expGroup, perm.group)
			XCTAssertEqual(expOther, perm.other)
			XCTAssertEqual(expMode, perm.mode)
			XCTAssertEqual(expFileType, perm.fileType)
		}
	}

	func testBinaryRepresentation() {
		for (expBinary, user, group, other, mode, fileType, _) in testCases {
			let perm = jlsftp.SftpProtocol.Version_3.PermissionsV3(user: user, group: group, other: other, mode: mode, fileType: fileType)

			XCTAssertEqual(expBinary, perm.binaryRepresentation)
		}
	}

	func testToStandard() {
		for (_, user, group, other, mode, fileType, expPerm) in testCases {
			let permV3 = jlsftp.SftpProtocol.Version_3.PermissionsV3(user: user, group: group, other: other, mode: mode, fileType: fileType)

			XCTAssertEqual(expPerm, permV3.permission)
		}
	}

	func testInitFromPermissions() {
		for (_, user, group, other, mode, fileType, perm) in testCases {
			let expPermV3 = jlsftp.SftpProtocol.Version_3.PermissionsV3(user: user, group: group, other: other, mode: mode, fileType: fileType)

			XCTAssertEqual(expPermV3, jlsftp.SftpProtocol.Version_3.PermissionsV3(from: perm))
		}
	}

	static var allTests = [
		("testInitFromBinary", testInitFromBinary),
		("testBinaryRepresentation", testBinaryRepresentation),
		("testToStandard", testToStandard),
		("testInitFromPermissions", testInitFromPermissions),
	]
}
