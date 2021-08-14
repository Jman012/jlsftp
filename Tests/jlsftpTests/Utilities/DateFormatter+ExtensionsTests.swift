import XCTest
@testable import jlsftp

final class DateFormatterExtensionsTests: XCTestCase {

	// MARK: Test `init(format:)`

	func testInitFormat() {
		let dateFormatter = DateFormatter(format: "yyyy")
		XCTAssertEqual(dateFormatter.dateFormat, "yyyy")
	}

	static var allTests = [
		("testInitFormat", testInitFormat),
	]
}
