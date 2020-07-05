import XCTest
@testable import jlftp

final class DataExtensionsTests: XCTestCase {
	func testToUInt32() {
		let testValues: [([UInt8], UInt32?)] = [
			// Valid
			([0x00, 0x00, 0x00, 0x00], 0),
			([0x01, 0x00, 0x00, 0x00], 1),
			// Ignored extra data
			([0x00, 0x00, 0x00, 0x00, 0xFF], 0),
			([0x01, 0x00, 0x00, 0x00, 0xFF], 1),
			// Invalid: too few bytes
			([0x00, 0x00, 0x00], nil),
			([0x00, 0x00], nil),
			([0x00], nil),
			([], nil),
		]

		for (input, expected) in testValues {
			let data = Data(input)

			let result = data.to(type: UInt32.self)

			XCTAssertEqual(expected, result, "(input = \(input))")
		}
	}

	func testToUInt8() {
		let testValues: [([UInt8], UInt8?)] = [
			// Valid
			([0x00], 0),
			([0x01], 1),
			// Ignored extra data
			([0x01, 0xFF], 1),
			([0x01, 0xFF, 0x01], 1),
			// Invalid: too few bytes
			([], nil),
		]

		for (input, expected) in testValues {
			let data = Data(input)

			let result = data.to(type: UInt8.self)

			XCTAssertEqual(expected, result, "(input = \(input))")
		}
	}

	static var allTests = [
		("testToUInt32", testToUInt32),
		("testToUInt8", testToUInt8),
	]
}
