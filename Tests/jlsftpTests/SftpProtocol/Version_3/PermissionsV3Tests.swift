import XCTest
@testable import jlsftp

final class PermissionsV3Tests: XCTestCase {

	let testCases: [(
		binary: UInt16,
		expUser: jlsftp.SftpProtocol.Version_3.PermissionV3,
		expGroup: jlsftp.SftpProtocol.Version_3.PermissionV3,
		expOther: jlsftp.SftpProtocol.Version_3.PermissionV3,
		expMode: jlsftp.SftpProtocol.Version_3.PermissionV3,
		expPerms: Permissions
	)] = [
		(0o0000, [], [], [], [],
		 Permissions(user: [], group: [], other: [], mode: [])),
		// Test Other
		(0o0001, [], [], [.execute], [],
		 Permissions(user: [], group: [], other: [.execute], mode: [])),
		(0o0002, [], [], [.write], [],
		 Permissions(user: [], group: [], other: [.write], mode: [])),
		(0o0003, [], [], [.write, .execute], [],
		 Permissions(user: [], group: [], other: [.write, .execute], mode: [])),
		(0o0004, [], [], [.read], [],
		 Permissions(user: [], group: [], other: [.read], mode: [])),
		(0o0005, [], [], [.read, .execute], [],
		 Permissions(user: [], group: [], other: [.read, .execute], mode: [])),
		(0o0006, [], [], [.read, .write], [],
		 Permissions(user: [], group: [], other: [.read, .write], mode: [])),
		(0o0007, [], [], [.read, .write, .execute], [],
		 Permissions(user: [], group: [], other: [.read, .write, .execute], mode: [])),
		// Test Group
		(0o0010, [], [.execute], [], [],
		 Permissions(user: [], group: [.execute], other: [], mode: [])),
		(0o0020, [], [.write], [], [],
		 Permissions(user: [], group: [.write], other: [], mode: [])),
		(0o0030, [], [.write, .execute], [], [],
		 Permissions(user: [], group: [.write, .execute], other: [], mode: [])),
		(0o0040, [], [.read], [], [],
		 Permissions(user: [], group: [.read], other: [], mode: [])),
		(0o0050, [], [.read, .execute], [], [],
		 Permissions(user: [], group: [.read, .execute], other: [], mode: [])),
		(0o0060, [], [.read, .write], [], [],
		 Permissions(user: [], group: [.read, .write], other: [], mode: [])),
		(0o0070, [], [.read, .write, .execute], [], [],
		 Permissions(user: [], group: [.read, .write, .execute], other: [], mode: [])),
		// Test User
		(0o0100, [.execute], [], [], [],
		 Permissions(user: [.execute], group: [], other: [], mode: [])),
		(0o0200, [.write], [], [], [],
		 Permissions(user: [.write], group: [], other: [], mode: [])),
		(0o0300, [.write, .execute], [], [], [],
		 Permissions(user: [.write, .execute], group: [], other: [], mode: [])),
		(0o0400, [.read], [], [], [],
		 Permissions(user: [.read], group: [], other: [], mode: [])),
		(0o0500, [.read, .execute], [], [], [],
		 Permissions(user: [.read, .execute], group: [], other: [], mode: [])),
		(0o0600, [.read, .write], [], [], [],
		 Permissions(user: [.read, .write], group: [], other: [], mode: [])),
		(0o0700, [.read, .write, .execute], [], [], [],
		 Permissions(user: [.read, .write, .execute], group: [], other: [], mode: [])),
		// Test Mode
		(0o1000, [], [], [], [.execute],
		 Permissions(user: [], group: [], other: [], mode: [.stickyBit])),
		(0o2000, [], [], [], [.write],
		 Permissions(user: [], group: [], other: [], mode: [.setGroupId])),
		(0o3000, [], [], [], [.write, .execute],
		 Permissions(user: [], group: [], other: [], mode: [.setGroupId, .stickyBit])),
		(0o4000, [], [], [], [.read],
		 Permissions(user: [], group: [], other: [], mode: [.setUserId])),
		(0o5000, [], [], [], [.read, .execute],
		 Permissions(user: [], group: [], other: [], mode: [.setUserId, .stickyBit])),
		(0o6000, [], [], [], [.read, .write],
		 Permissions(user: [], group: [], other: [], mode: [.setUserId, .setGroupId])),
		(0o7000, [], [], [], [.read, .write, .execute],
		 Permissions(user: [], group: [], other: [], mode: [.setUserId, .setGroupId, .stickyBit])),
		// Test mixed
		(0o0754, [.read, .write, .execute], [.read, .execute], [.read], [],
		 Permissions(user: [.read, .write, .execute], group: [.read, .execute], other: [.read], mode: [])),
	]

	func testInitFromBinary() {
		for (binary, expUser, expGroup, expOther, expMode, _) in testCases {
			let perm = jlsftp.SftpProtocol.Version_3.PermissionsV3(fromBinary: binary)

			XCTAssertEqual(expUser, perm.user)
			XCTAssertEqual(expGroup, perm.group)
			XCTAssertEqual(expOther, perm.other)
			XCTAssertEqual(expMode, perm.mode)
		}
	}

	func testBinaryRepresentation() {
		for (expBinary, user, group, other, mode, _) in testCases {
			let perm = jlsftp.SftpProtocol.Version_3.PermissionsV3(user: user, group: group, other: other, mode: mode)

			XCTAssertEqual(expBinary, perm.binaryRepresentation)
		}
	}

	func testToStandard() {
		for (_, user, group, other, mode, expPerm) in testCases {
			let permV3 = jlsftp.SftpProtocol.Version_3.PermissionsV3(user: user, group: group, other: other, mode: mode)

			XCTAssertEqual(expPerm, permV3.permission)
		}
	}

	func testInitFromPermissions() {
		for (_, user, group, other, mode, perm) in testCases {
			let expPermV3 = jlsftp.SftpProtocol.Version_3.PermissionsV3(user: user, group: group, other: other, mode: mode)

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
