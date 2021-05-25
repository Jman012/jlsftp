import XCTest
@testable import jlsftp

final class SequenceExtensionsTests: XCTestCase {

	// MARK: Test `elementsAreContiguous`

	func testElementsAreContiguousValid() {
		let data: [([Int], Bool)] = [
			// Empty
			([], true),
			// Single element
			([1], true),
			// Multiple elements in order
			([1, 2], true),
			([1, 2, 3, 4, 5, 6, 7, 8, 9], true),
			// Multiple elements out of order
			([4, 3, 1, 8, 7, 5, 9, 2, 6], true),
		]

		for datum in data {
			XCTAssertEqual(datum.1, datum.0.elementsAreContiguous, "\(datum.0)")
		}
	}

	func testElementsAreContiguousInvalid() {
		let data: [([Int], Bool)] = [
			// Multiple elements in order
			([1, 3], false),
			([1, 2, 3, 4, 5, 7, 8, 9], false),
			// Multiple elements out of order
			([3, 1, 8, 7, 5, 9, 2, 6], false),
			// Repeated elements
			([1, 1], false),
		]

		for datum in data {
			XCTAssertEqual(datum.1, datum.0.elementsAreContiguous, "\(datum.0)")
		}
	}

	static var allTests = [
		("testElementsAreContiguousValid", testElementsAreContiguousValid),
		("testElementsAreContiguousInvalid", testElementsAreContiguousInvalid),
	]
}
