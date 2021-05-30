import XCTest
import Combine
import NIO
@testable import jlsftp

final class mode_tExtensionsTests: XCTestCase {

	func testValid() {
		let data = [
			(
				Permissions(user: [], group: [], other: []),
				0
			),
			(
				Permissions(user: [.read], group: [.write], other: [.execute]),
				S_IRUSR | S_IWGRP | S_IXOTH
			),
			(
				Permissions(user: [.read, .write], group: [.write, .execute], other: [.execute, .read]),
				S_IRUSR | S_IWUSR | S_IWGRP | S_IXGRP | S_IROTH | S_IXOTH
			),
			(
				Permissions(
					user: [.read, .write, .execute],
					group: [.read, .write, .execute],
					other: [.read, .write, .execute]
				),
				S_IRUSR | S_IWUSR | S_IXUSR | S_IRGRP | S_IWGRP | S_IXGRP | S_IROTH | S_IWOTH | S_IXOTH
			),
			(
				Permissions(
					user: [.read],
					group: [],
					other: []
				),
				S_IRUSR
			),
			(
				Permissions(
					user: [.write],
					group: [],
					other: []
				),
				S_IWUSR
			),
			(
				Permissions(
					user: [.execute],
					group: [],
					other: []
				),
				S_IXUSR
			),
			(
				Permissions(
					user: [],
					group: [.read],
					other: []
				),
				S_IRGRP
			),
			(
				Permissions(
					user: [],
					group: [.write],
					other: []
				),
				S_IWGRP
			),
			(
				Permissions(
					user: [],
					group: [.execute],
					other: []
				),
				S_IXGRP
			),
			(
				Permissions(
					user: [],
					group: [],
					other: [.read]
				),
				S_IROTH
			),
			(
				Permissions(
					user: [],
					group: [],
					other: [.write]
				),
				S_IWOTH
			),
			(
				Permissions(
					user: [],
					group: [],
					other: [.execute]
				),
				S_IXOTH
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
