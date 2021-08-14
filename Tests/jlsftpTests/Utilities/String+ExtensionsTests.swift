import XCTest
@testable import jlsftp

final class StringExtensionsTests: XCTestCase {

	// MARK: Test `padding(leftToLength:,withPad:) `

	func testPaddingLeftToLengthWithPad() {
		let data: [(String, String, Int, Character)] = [
			("", "", 0, " "),
			(" ", "", 1, " "),
			(" ", " ", 0, " "),
			(" ", " ", 1, " "),
			("  ", " ", 2, " "),
			("a", "a", 1, " "),
			(" a", "a", 2, " "),
		]

		for datum in data {
			XCTAssertEqual(datum.0, datum.1.padding(leftToLength: datum.2, withPad: datum.3))
		}
	}

	static var allTests = [
		("testPaddingLeftToLengthWithPad", testPaddingLeftToLengthWithPad),
	]
}
