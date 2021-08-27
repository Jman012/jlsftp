import XCTest
import Combine
import NIO
@testable import jlsftp

final class mode_tExtensionsTests: XCTestCase {

	func testValid() {
		let data: [(Permissions, mode_t)] = [
			(
				Permissions(user: [], group: [], other: [], mode: [], fileType: nil),
				0
			),
			(
				Permissions(user: [.read], group: [.write], other: [.execute], mode: [], fileType: nil),
				S_IRUSR | S_IWGRP | S_IXOTH
			),
			(
				Permissions(user: [.read, .write], group: [.write, .execute], other: [.execute, .read], mode: [], fileType: nil),
				S_IRUSR | S_IWUSR | S_IWGRP | S_IXGRP | S_IROTH | S_IXOTH
			),
			(
				Permissions(
					user: [.read, .write, .execute],
					group: [.read, .write, .execute],
					other: [.read, .write, .execute],
					mode: [],
					fileType: nil
				),
				S_IRUSR | S_IWUSR | S_IXUSR | S_IRGRP | S_IWGRP | S_IXGRP | S_IROTH | S_IWOTH | S_IXOTH
			),
			(
				Permissions(
					user: [.read],
					group: [],
					other: [],
					mode: [],
					fileType: nil
				),
				S_IRUSR
			),
			(
				Permissions(
					user: [.write],
					group: [],
					other: [],
					mode: [],
					fileType: nil
				),
				S_IWUSR
			),
			(
				Permissions(
					user: [.execute],
					group: [],
					other: [],
					mode: [],
					fileType: nil
				),
				S_IXUSR
			),
			(
				Permissions(
					user: [],
					group: [.read],
					other: [],
					mode: [],
					fileType: nil
				),
				S_IRGRP
			),
			(
				Permissions(
					user: [],
					group: [.write],
					other: [],
					mode: [],
					fileType: nil
				),
				S_IWGRP
			),
			(
				Permissions(
					user: [],
					group: [.execute],
					other: [],
					mode: [],
					fileType: nil
				),
				S_IXGRP
			),
			(
				Permissions(
					user: [],
					group: [],
					other: [.read],
					mode: [],
					fileType: nil
				),
				S_IROTH
			),
			(
				Permissions(
					user: [],
					group: [],
					other: [.write],
					mode: [],
					fileType: nil
				),
				S_IWOTH
			),
			(
				Permissions(
					user: [],
					group: [],
					other: [.execute],
					mode: [],
					fileType: nil
				),
				S_IXOTH
			),
			(
				Permissions(user: [], group: [], other: [], mode: [.setUserId], fileType: nil),
				S_ISUID
			),
			(
				Permissions(user: [], group: [], other: [], mode: [.setGroupId], fileType: nil),
				S_ISGID
			),
			(
				Permissions(user: [], group: [], other: [], mode: [.stickyBit], fileType: nil),
				S_ISVTX
			),
			(
				Permissions(user: [], group: [], other: [], mode: [.setUserId, .setGroupId, .stickyBit], fileType: nil),
				S_ISUID | S_ISGID | S_ISVTX
			),
			(
				Permissions(user: [], group: [], other: [], mode: [], fileType: .socket),
				S_IFSOCK
			),
			(
				Permissions(user: [], group: [], other: [], mode: [], fileType: .symbolicLink),
				S_IFLNK
			),
			(
				Permissions(user: [], group: [], other: [], mode: [], fileType: .regularFile),
				S_IFREG
			),
			(
				Permissions(user: [], group: [], other: [], mode: [], fileType: .blockDevice),
				S_IFBLK
			),
			(
				Permissions(user: [], group: [], other: [], mode: [], fileType: .directory),
				S_IFDIR
			),
			(
				Permissions(user: [], group: [], other: [], mode: [], fileType: .characterDevice),
				S_IFCHR
			),
			(
				Permissions(user: [], group: [], other: [], mode: [], fileType: .fifo),
				S_IFIFO
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
