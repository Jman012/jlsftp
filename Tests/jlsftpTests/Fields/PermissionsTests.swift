import XCTest
@testable import jlsftp

final class PermissionsTests: XCTestCase {

	// MARK: Test `init(mode:)`

	func testInitMode() {
		let data: [(mode_t, Permissions)] = [
			(0, Permissions(user: [], group: [], other: [], mode: [])),
			(S_IRUSR, Permissions(user: [.read], group: [], other: [], mode: [])),
			(S_IWUSR, Permissions(user: [.write], group: [], other: [], mode: [])),
			(S_IXUSR, Permissions(user: [.execute], group: [], other: [], mode: [])),
			(S_IRGRP, Permissions(user: [], group: [.read], other: [], mode: [])),
			(S_IWGRP, Permissions(user: [], group: [.write], other: [], mode: [])),
			(S_IXGRP, Permissions(user: [], group: [.execute], other: [], mode: [])),
			(S_IROTH, Permissions(user: [], group: [], other: [.read], mode: [])),
			(S_IWOTH, Permissions(user: [], group: [], other: [.write], mode: [])),
			(S_IXOTH, Permissions(user: [], group: [], other: [.execute], mode: [])),
			(S_ISUID, Permissions(user: [], group: [], other: [], mode: [.setUserId])),
			(S_ISGID, Permissions(user: [], group: [], other: [], mode: [.setGroupId])),
			(S_ISVTX, Permissions(user: [], group: [], other: [], mode: [.stickyBit])),
			(S_IRUSR | S_IWUSR | S_IXUSR |
				S_IRGRP | S_IWGRP | S_IXGRP |
				S_IROTH | S_IWOTH | S_IXOTH |
				S_ISUID | S_ISGID | S_ISVTX,
				Permissions(user: [.read, .write, .execute],
							group: [.read, .write, .execute],
							other: [.read, .write, .execute],
							mode: [.setUserId, .setGroupId, .stickyBit])),
		]

		for datum in data {
			XCTAssertEqual(Permissions(mode: datum.0), datum.1)
		}
	}

	static var allTests = [
		("testInitMode", testInitMode),
	]
}
