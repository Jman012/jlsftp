import XCTest
@testable import jlsftp

final class FileAttributesTests: XCTestCase {

	// MARK: Test `init(sizeBytes:,userId:,groupId:,permissions:,accessDate:,modifyDate:,linkCount:,extensionData:)`

	func testInitLong() {
		let fileAttributes = FileAttributes(sizeBytes: 1,
											userId: 2,
											groupId: 3,
											permissions: Permissions(user: [.read], group: [], other: [], mode: [], fileType: .regularFile),
											accessDate: Date(timeIntervalSince1970: 1),
											modifyDate: Date(timeIntervalSince1970: 2),
											linkCount: 4,
											extensionData: [])

		XCTAssertEqual(fileAttributes.sizeBytes, 1)
		XCTAssertEqual(fileAttributes.userId, 2)
		XCTAssertEqual(fileAttributes.groupId, 3)
		XCTAssertEqual(fileAttributes.permissions, Permissions(user: [.read], group: [], other: [], mode: [], fileType: .regularFile))
		XCTAssertEqual(fileAttributes.accessDate, Date(timeIntervalSince1970: 1))
		XCTAssertEqual(fileAttributes.modifyDate, Date(timeIntervalSince1970: 2))
		XCTAssertEqual(fileAttributes.linkCount, 4)
		XCTAssertEqual(fileAttributes.extensionData, [])
	}

	// MARK: Test `init(stat:extensionData:)`

	func testInitStat() {
		let fileAttributes = FileAttributes(stat: .init(st_dev: 0,
														st_mode: S_IFREG | S_IRUSR,
														st_nlink: 4,
														st_ino: 0,
														st_uid: 2,
														st_gid: 3,
														st_rdev: 0,
														st_atimespec: timespec(tv_sec: 1, tv_nsec: 0),
														st_mtimespec: timespec(tv_sec: 2, tv_nsec: 0),
														st_ctimespec: timespec(tv_sec: 0, tv_nsec: 0),
														st_birthtimespec: timespec(tv_sec: 0, tv_nsec: 0),
														st_size: 1,
														st_blocks: 0,
														st_blksize: 0,
														st_flags: 0,
														st_gen: 0,
														st_lspare: 0,
														st_qspare: (0, 0)),
											extensionData: [])

		XCTAssertEqual(fileAttributes.sizeBytes, 1)
		XCTAssertEqual(fileAttributes.userId, 2)
		XCTAssertEqual(fileAttributes.groupId, 3)
		XCTAssertEqual(fileAttributes.permissions, Permissions(user: [.read], group: [], other: [], mode: [], fileType: .regularFile))
		XCTAssertEqual(fileAttributes.accessDate, Date(timeIntervalSince1970: 1))
		XCTAssertEqual(fileAttributes.modifyDate, Date(timeIntervalSince1970: 2))
		XCTAssertEqual(fileAttributes.linkCount, 4)
		XCTAssertEqual(fileAttributes.extensionData, [])
	}

	// MARK: Test `longName(shortName:)`

	func testLongName() {
		let formatter = DateFormatter(format: "yyyy-MM-dd'T'HH:mm:ss")
		let accessDate = formatter.date(from: "2021-08-07T12:14:15")
		let modifyDate = formatter.date(from: "2021-08-07T13:14:15")
		let fileAttributes = FileAttributes(sizeBytes: 1,
											userId: 0,
											groupId: 0,
											permissions: .init(user: [.read, .write, .execute], group: [.read, .write, .execute], other: [.read, .write, .execute], mode: [], fileType: .regularFile),
											accessDate: accessDate,
											modifyDate: modifyDate,
											linkCount: 3,
											extensionData: [])

		let longName = fileAttributes.longName(shortName: "test.txt")

		XCTAssertEqual("-rwxrwxrwx   3 root     wheel           1 Aug 07 13:14 test.txt", longName)
	}

	static var allTests = [
		("testLongName", testLongName),
	]
}
