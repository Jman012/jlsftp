import XCTest
import Combine
import NIO
@testable import jlsftp

final class mode_tExtensionsTests: XCTestCase {

	func testValid() {
		let data = [
			(
				Permissions(user: [], group: [], other: [], mode: []),
				0
			),
			(
				Permissions(user: [.read], group: [.write], other: [.execute], mode: []),
				S_IRUSR | S_IWGRP | S_IXOTH
			),
			(
				Permissions(user: [.read, .write], group: [.write, .execute], other: [.execute, .read], mode: []),
				S_IRUSR | S_IWUSR | S_IWGRP | S_IXGRP | S_IROTH | S_IXOTH
			),
			(
				Permissions(
					user: [.read, .write, .execute],
					group: [.read, .write, .execute],
					other: [.read, .write, .execute],
					mode: []
				),
				S_IRUSR | S_IWUSR | S_IXUSR | S_IRGRP | S_IWGRP | S_IXGRP | S_IROTH | S_IWOTH | S_IXOTH
			),
			(
				Permissions(
					user: [.read],
					group: [],
					other: [],
					mode: []
				),
				S_IRUSR
			),
			(
				Permissions(
					user: [.write],
					group: [],
					other: [],
					mode: []
				),
				S_IWUSR
			),
			(
				Permissions(
					user: [.execute],
					group: [],
					other: [],
					mode: []
				),
				S_IXUSR
			),
			(
				Permissions(
					user: [],
					group: [.read],
					other: [],
					mode: []
				),
				S_IRGRP
			),
			(
				Permissions(
					user: [],
					group: [.write],
					other: [],
					mode: []
				),
				S_IWGRP
			),
			(
				Permissions(
					user: [],
					group: [.execute],
					other: [],
					mode: []
				),
				S_IXGRP
			),
			(
				Permissions(
					user: [],
					group: [],
					other: [.read],
					mode: []
				),
				S_IROTH
			),
			(
				Permissions(
					user: [],
					group: [],
					other: [.write],
					mode: []
				),
				S_IWOTH
			),
			(
				Permissions(
					user: [],
					group: [],
					other: [.execute],
					mode: []
				),
				S_IXOTH
			),
			(
				Permissions(user: [], group: [], other: [], mode: [.setUserId]),
				S_ISUID
			),
			(
				Permissions(user: [], group: [], other: [], mode: [.setGroupId]),
				S_ISGID
			),
			(
				Permissions(user: [], group: [], other: [], mode: [.stickyBit]),
				S_ISVTX
			),
			(
				Permissions(user: [], group: [], other: [], mode: [.setUserId, .setGroupId, .stickyBit]),
				S_ISUID | S_ISGID | S_ISVTX
			),
		]

		for datum in data {
			XCTAssertEqual(mode_t(fromPermissions: datum.0), datum.1)
		}
	}

	static var allTests = [
		("testValid", testValid),
	]
}
