import XCTest
@testable import jlftp

final class DataExtensionsTests: XCTestCase {

	// MARK: `to(, from:)` Tests

	func testToUInt32Network() {
		let testValues: [([UInt8], UInt32?)] = [
			// Valid
			([0x00, 0x00, 0x00, 0x00], 0),
			([0x00, 0x00, 0x00, 0x01], 1),
			([0x80, 0x00, 0x00, 0x00], 2_147_483_648),
			// Invalid: extra data
			([0x00, 0x00, 0x00, 0x00, 0xFF], nil),
			([0x00, 0x00, 0x00, 0x01, 0xFF], nil),
			// Invalid: too few bytes
			([0x00, 0x00, 0x00], nil),
			([0x00, 0x00], nil),
			([0x00], nil),
			([], nil),
		]

		for (input, expected) in testValues {
			let data = Data(input)

			let result = data.to(UInt32.self, from: .networkOrder)

			XCTAssertEqual(expected, result, "(input = \(input))")
		}
	}

	func testToUInt32Host() {
		let testValues: [([UInt8], UInt32?)] = [
			// Valid
			([0x00, 0x00, 0x00, 0x00], 0),
			([0x01, 0x00, 0x00, 0x00], 1),
			([0x00, 0x00, 0x00, 0x80], 2_147_483_648),
			([0x80, 0x00, 0x00, 0x00], 128),
			// Invalid: extra data
			([0x00, 0x00, 0x00, 0x00, 0xFF], nil),
			([0x01, 0x00, 0x00, 0x00, 0xFF], nil),
			// Invalid: too few bytes
			([0x00, 0x00, 0x00], nil),
			([0x00, 0x00], nil),
			([0x00], nil),
			([], nil),
		]

		for (input, expected) in testValues {
			let data = Data(input)

			let result = data.to(UInt32.self, from: .hostOrder)

			XCTAssertEqual(expected, result, "(input = \(input))")
		}
	}

	func testToUInt8Network() {
		let testValues: [([UInt8], UInt8?)] = [
			// Valid
			([0x00], 0),
			([0x01], 1),
			// Invalid: extra data
			([0x01, 0xFF], nil),
			([0x01, 0xFF, 0x01], nil),
			// Invalid: too few bytes
			([], nil),
		]

		for (input, expected) in testValues {
			let data = Data(input)

			let result = data.to(UInt8.self, from: .networkOrder)

			XCTAssertEqual(expected, result, "(input = \(input))")
		}
	}

	func testToUInt8Host() {
		let testValues: [([UInt8], UInt8?)] = [
			// Valid
			([0x00], 0),
			([0x01], 1),
			// Invalid: extra data
			([0x01, 0xFF], nil),
			([0x01, 0xFF, 0x01], nil),
			// Invalid: too few bytes
			([], nil),
		]

		for (input, expected) in testValues {
			let data = Data(input)

			let result = data.to(UInt8.self, from: .hostOrder)

			XCTAssertEqual(expected, result, "(input = \(input))")
		}
	}

	// MARK: `.split(maxLength:)` Tests

	func testSplitMaxLength() {
		let testCases: [(input: Data, maxLength: Int, expectedPrefix: Data, expectedSuffix: Data)] = [
			(Data(), 0, Data(), Data()),
			(Data(), 1, Data(), Data()),
			(Data(), 5, Data(), Data()),

			(Data([1]), 0, Data(), Data([1])),
			(Data([1]), 1, Data([1]), Data()),
			(Data([1]), 5, Data([1]), Data()),

			(Data([1, 2]), 0, Data(), Data([1, 2])),
			(Data([1, 2]), 1, Data([1]), Data([2])),
			(Data([1, 2]), 2, Data([1, 2]), Data()),
			(Data([1, 2]), 5, Data([1, 2]), Data()),

			(Data([1, 2, 3]), 0, Data(), Data([1, 2, 3])),
			(Data([1, 2, 3]), 1, Data([1]), Data([2, 3])),
			(Data([1, 2, 3]), 2, Data([1, 2]), Data([3])),
			(Data([1, 2, 3]), 3, Data([1, 2, 3]), Data()),
			(Data([1, 2, 3]), 4, Data([1, 2, 3]), Data()),
			(Data([1, 2, 3]), 5, Data([1, 2, 3]), Data()),
		]

		for (input, maxLength, expectedPrefix, expectedSuffix) in testCases {
			let (prefix, suffix) = input.split(maxLength: maxLength)

			XCTAssertEqual(expectedPrefix, prefix, "input=\(input), maxLength=\(maxLength), expected=\(expectedPrefix), actual=\(prefix)")
			XCTAssertEqual(expectedSuffix, suffix, "input=\(input), maxLength=\(maxLength), expected=\(expectedSuffix), actual=\(suffix)")
		}
	}

	static var allTests = [
		("testToUInt32Network", testToUInt32Network),
		("testToUInt32Host", testToUInt32Host),
		("testToUInt8Network", testToUInt8Network),
		("testToUInt8Host", testToUInt8Host),
		("testSplitMaxLength", testSplitMaxLength),
	]
}
