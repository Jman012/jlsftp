import XCTest
@testable import jlsftp

final class FileAttributesTests: XCTestCase {

	// MARK: Test `longName(shortName:)`

	func testLongName() {
		let formatter = DateFormatter(format: "yyyy-MM-dd'T'HH:mm:ss")
		let accessDate = formatter.date(from: "2021-08-07T12:14:15")
		let modifyDate = formatter.date(from: "2021-08-07T13:14:15")
		let fileAttributes = FileAttributes(sizeBytes: 1,
											userId: 0,
											groupId: 0,
											permissions: .init(user: [.read, .write, .execute], group: [.read, .write], other: [.read], mode: []),
											accessDate: accessDate,
											modifyDate: modifyDate,
											linkCount: 3,
											extensionData: [])

		let longName = fileAttributes.longName(shortName: "test.txt")

		XCTAssertEqual("-rwxrw-r--   3 root     wheel           1 Aug 07 13:14 test.txt", longName)
	}

	static var allTests = [
		("testLongName", testLongName),
	]
}
