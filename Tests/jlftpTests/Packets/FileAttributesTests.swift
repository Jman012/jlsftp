import XCTest
@testable import jlftp

final class FileAttributesTests: XCTestCase {

	let testCases: [(binary: UInt16, expUser: Permission, expGroup: Permission, expOther: Permission)] = [
		// Test Other
		(0o000, [], [], []),
		(0o001, [], [], [.execute]),
		(0o002, [], [], [.write]),
		(0o003, [], [], [.write, .execute]),
		(0o004, [], [], [.read]),
		(0o005, [], [], [.read, .execute]),
		(0o006, [], [], [.read, .write]),
		(0o007, [], [], [.read, .write, .execute]),
		// Test Group
		(0o000, [], [], []),
		(0o010, [], [.execute], []),
		(0o020, [], [.write], []),
		(0o030, [], [.write, .execute], []),
		(0o040, [], [.read], []),
		(0o050, [], [.read, .execute], []),
		(0o060, [], [.read, .write], []),
		(0o070, [], [.read, .write, .execute], []),
		// Test User
		(0o000, [], [], []),
		(0o100, [.execute], [], []),
		(0o200, [.write], [], []),
		(0o300, [.write, .execute], [], []),
		(0o400, [.read], [], []),
		(0o500, [.read, .execute], [], []),
		(0o600, [.read, .write], [], []),
		(0o700, [.read, .write, .execute], [], []),
		// Test mixed
		(0o754, [.read, .write, .execute], [.read, .execute], [.read]),
	]

	func testInitFromBinary() {
		for (binary, expUser, expGroup, expOther) in testCases {
			let perm = Permissions(fromBinary: binary)

			XCTAssertEqual(expUser, perm.user)
			XCTAssertEqual(expGroup, perm.group)
			XCTAssertEqual(expOther, perm.other)
		}
	}

	func testBinaryRepresentation() {
		for (expBinary, user, group, other) in testCases {
			let perm = Permissions(user: user, group: group, other: other)

			XCTAssertEqual(expBinary, perm.binaryRepresentation)
		}
	}

	static var allTests = [
		("testInitFromBinary", testInitFromBinary),
		("testBinaryRepresentation", testBinaryRepresentation),
	]
}
