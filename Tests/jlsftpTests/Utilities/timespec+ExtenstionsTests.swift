import XCTest
@testable import jlsftp

final class TimeSpecExtensionsTests: XCTestCase {

	// MARK: Test `date`

	func testDateSimple() {
		let timeSpec = timespec(tv_sec: 1, tv_nsec: 0)
		let expectedDate = Date(timeIntervalSince1970: 1.0)

		XCTAssertEqual(timeSpec.date, expectedDate)
	}

	func testDateNsec() {
		let timeSpec = timespec(tv_sec: 1, tv_nsec: 250_000_000)
		let expectedDate = Date(timeIntervalSince1970: 1.25)

		XCTAssertEqual(timeSpec.date, expectedDate)
	}

	static var allTests = [
		("testDateSimple", testDateSimple),
		("testDateNsec", testDateNsec),
	]
}
