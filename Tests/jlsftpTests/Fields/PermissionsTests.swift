import XCTest
@testable import jlsftp

final class PermissionsTests: XCTestCase {

	// MARK: Test `init(mode:)`

	func testInitMode() {
		let data: [(mode_t, Permissions)] = [
			(0, Permissions(user: [], group: [], other: [], mode: [], fileType: nil)),
			(S_IRUSR, Permissions(user: [.read], group: [], other: [], mode: [], fileType: nil)),
			(S_IWUSR, Permissions(user: [.write], group: [], other: [], mode: [], fileType: nil)),
			(S_IXUSR, Permissions(user: [.execute], group: [], other: [], mode: [], fileType: nil)),
			(S_IRGRP, Permissions(user: [], group: [.read], other: [], mode: [], fileType: nil)),
			(S_IWGRP, Permissions(user: [], group: [.write], other: [], mode: [], fileType: nil)),
			(S_IXGRP, Permissions(user: [], group: [.execute], other: [], mode: [], fileType: nil)),
			(S_IROTH, Permissions(user: [], group: [], other: [.read], mode: [], fileType: nil)),
			(S_IWOTH, Permissions(user: [], group: [], other: [.write], mode: [], fileType: nil)),
			(S_IXOTH, Permissions(user: [], group: [], other: [.execute], mode: [], fileType: nil)),
			(S_ISUID, Permissions(user: [], group: [], other: [], mode: [.setUserId], fileType: nil)),
			(S_ISGID, Permissions(user: [], group: [], other: [], mode: [.setGroupId], fileType: nil)),
			(S_ISVTX, Permissions(user: [], group: [], other: [], mode: [.stickyBit], fileType: nil)),
			(S_IRUSR | S_IWUSR | S_IXUSR |
				S_IRGRP | S_IWGRP | S_IXGRP |
				S_IROTH | S_IWOTH | S_IXOTH |
				S_ISUID | S_ISGID | S_ISVTX,
				Permissions(user: [.read, .write, .execute],
							group: [.read, .write, .execute],
							other: [.read, .write, .execute],
							mode: [.setUserId, .setGroupId, .stickyBit], fileType: nil)),
			(S_IFSOCK, Permissions(user: [], group: [], other: [], mode: [], fileType: .socket)),
			(S_IFLNK, Permissions(user: [], group: [], other: [], mode: [], fileType: .symbolicLink)),
			(S_IFREG, Permissions(user: [], group: [], other: [], mode: [], fileType: .regularFile)),
			(S_IFBLK, Permissions(user: [], group: [], other: [], mode: [], fileType: .blockDevice)),
			(S_IFDIR, Permissions(user: [], group: [], other: [], mode: [], fileType: .directory)),
			(S_IFCHR, Permissions(user: [], group: [], other: [], mode: [], fileType: .characterDevice)),
			(S_IFIFO, Permissions(user: [], group: [], other: [], mode: [], fileType: .fifo)),
			(S_IRUSR | S_IWUSR | S_IXUSR |
				S_IRGRP | S_IWGRP | S_IXGRP |
				S_IROTH | S_IWOTH | S_IXOTH |
				S_ISUID | S_ISGID | S_ISVTX |
				S_IFREG,
				Permissions(user: [.read, .write, .execute],
							group: [.read, .write, .execute],
							other: [.read, .write, .execute],
							mode: [.setUserId, .setGroupId, .stickyBit], fileType: .regularFile)),
		]

		for datum in data {
			XCTAssertEqual(Permissions(mode: datum.0), datum.1)
		}
	}

	static var allTests = [
		("testInitMode", testInitMode),
	]
}
