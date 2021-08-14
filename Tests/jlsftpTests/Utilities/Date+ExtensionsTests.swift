import XCTest
@testable import jlsftp

final class DateExtensionsTests: XCTestCase {

	// MARK: Test `timespec`

	func testTimespecSec() {
		// One second
		let date = Date(timeIntervalSince1970: 1)
		let dateTimespec = date.timespec

		XCTAssertEqual(dateTimespec.tv_sec, 1)
		XCTAssertEqual(dateTimespec.tv_nsec, 0)
	}

	func testTimespecNsec() {
		// One second and one quarter of a billionth of a second (nanosecond)
		let date = Date(timeIntervalSince1970: 1.25)
		let dateTimespec = date.timespec

		XCTAssertEqual(dateTimespec.tv_sec, 1)
		XCTAssertEqual(dateTimespec.tv_nsec, 250_000_000)
	}

	static var allTests = [
		("testTimespecSec", testTimespecSec),
		("testTimespecNsec", testTimespecNsec),
	]
}
