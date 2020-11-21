import XCTest
@testable import jlsftp

final class PermissionsV3Tests: XCTestCase {

	let testCases: [(
		binary: UInt16,
		expUser: jlsftp.DataLayer.Version_3.PermissionV3,
		expGroup: jlsftp.DataLayer.Version_3.PermissionV3,
		expOther: jlsftp.DataLayer.Version_3.PermissionV3,
		expPerms: Permissions
	)] = [
		(0o000, [], [], [],
		 Permissions(user: [], group: [], other: [])),
		// Test Other
		(0o001, [], [], [.execute],
		 Permissions(user: [], group: [], other: [.execute])),
		(0o002, [], [], [.write],
		 Permissions(user: [], group: [], other: [.write])),
		(0o003, [], [], [.write, .execute],
		 Permissions(user: [], group: [], other: [.write, .execute])),
		(0o004, [], [], [.read],
		 Permissions(user: [], group: [], other: [.read])),
		(0o005, [], [], [.read, .execute],
		 Permissions(user: [], group: [], other: [.read, .execute])),
		(0o006, [], [], [.read, .write],
		 Permissions(user: [], group: [], other: [.read, .write])),
		(0o007, [], [], [.read, .write, .execute],
		 Permissions(user: [], group: [], other: [.read, .write, .execute])),
		// Test Group
		(0o010, [], [.execute], [],
		 Permissions(user: [], group: [.execute], other: [])),
		(0o020, [], [.write], [],
		 Permissions(user: [], group: [.write], other: [])),
		(0o030, [], [.write, .execute], [],
		 Permissions(user: [], group: [.write, .execute], other: [])),
		(0o040, [], [.read], [],
		 Permissions(user: [], group: [.read], other: [])),
		(0o050, [], [.read, .execute], [],
		 Permissions(user: [], group: [.read, .execute], other: [])),
		(0o060, [], [.read, .write], [],
		 Permissions(user: [], group: [.read, .write], other: [])),
		(0o070, [], [.read, .write, .execute], [],
		 Permissions(user: [], group: [.read, .write, .execute], other: [])),
		// Test User
		(0o100, [.execute], [], [],
		 Permissions(user: [.execute], group: [], other: [])),
		(0o200, [.write], [], [],
		 Permissions(user: [.write], group: [], other: [])),
		(0o300, [.write, .execute], [], [],
		 Permissions(user: [.write, .execute], group: [], other: [])),
		(0o400, [.read], [], [],
		 Permissions(user: [.read], group: [], other: [])),
		(0o500, [.read, .execute], [], [],
		 Permissions(user: [.read, .execute], group: [], other: [])),
		(0o600, [.read, .write], [], [],
		 Permissions(user: [.read, .write], group: [], other: [])),
		(0o700, [.read, .write, .execute], [], [],
		 Permissions(user: [.read, .write, .execute], group: [], other: [])),
		// Test mixed
		(0o754, [.read, .write, .execute], [.read, .execute], [.read],
		 Permissions(user: [.read, .write, .execute], group: [.read, .execute], other: [.read])),
	]

	func testInitFromBinary() {
		for (binary, expUser, expGroup, expOther, _) in testCases {
			let perm = jlsftp.DataLayer.Version_3.PermissionsV3(fromBinary: binary)

			XCTAssertEqual(expUser, perm.user)
			XCTAssertEqual(expGroup, perm.group)
			XCTAssertEqual(expOther, perm.other)
		}
	}

	func testBinaryRepresentation() {
		for (expBinary, user, group, other, _) in testCases {
			let perm = jlsftp.DataLayer.Version_3.PermissionsV3(user: user, group: group, other: other)

			XCTAssertEqual(expBinary, perm.binaryRepresentation)
		}
	}

	func testToStandard() {
		for (_, user, group, other, expPerm) in testCases {
			let permV3 = jlsftp.DataLayer.Version_3.PermissionsV3(user: user, group: group, other: other)

			XCTAssertEqual(expPerm, permV3.permission)
		}
	}

	func testInitFromPermissions() {
		for (_, user, group, other, perm) in testCases {
			let expPermV3 = jlsftp.DataLayer.Version_3.PermissionsV3(user: user, group: group, other: other)

			XCTAssertEqual(expPermV3, jlsftp.DataLayer.Version_3.PermissionsV3(from: perm))
		}
	}

	static var allTests = [
		("testInitFromBinary", testInitFromBinary),
		("testBinaryRepresentation", testBinaryRepresentation),
		("testToStandard", testToStandard),
		("testInitFromPermissions", testInitFromPermissions),
	]
}
