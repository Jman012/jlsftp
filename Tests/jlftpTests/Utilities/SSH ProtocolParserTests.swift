import XCTest
@testable import jlftp

final class SSHProtocolParserDraft9Tests: XCTestCase {

	func testParseByte() {
		let testCases: [(data: Data, expectedByte: UInt8?, expectedRemainingData: Data.SubSequence)] = [
			// Invalid
			(Data(), nil, Data()),
			// Base Valid
			(Data([0]), 0, Data()),
			(Data([1]), 1, Data()),
			(Data([255]), 255, Data()),
			// Valid with remaining data
			(Data([2, 3]), 2, Data([3])),
			(Data([4, 5, 6]), 4, Data([5, 6])),
		]

		let parser = SSHProtocolParserDraft9()
		for (data, expectedByte, expectedRemainingData) in testCases {
			let (actualByte, actualRemainingData) = parser.parseByte(from: data)

			XCTAssertEqual(expectedByte, actualByte)
			XCTAssertEqual(expectedRemainingData, actualRemainingData)
		}
	}

	func testParseUInt32() {
		let testCases: [(data: Data, expectedInt: UInt32?, expectedRemainingData: Data.SubSequence)] = [
			// Invalid
			(Data(), nil, Data()),
			(Data([1]), nil, Data([1])),
			(Data([1, 2]), nil, Data([1, 2])),
			(Data([1, 2, 3]), nil, Data([1, 2, 3])),
			// Base valid (Network Byte Order)
			(Data([0, 0, 0, 0]), 0, Data()),
			(Data([0, 0, 0, 1]), 1, Data()),
			(Data([0, 0, 1, 0]), 256, Data()),
			(Data([0, 1, 0, 0]), 65536, Data()),
			(Data([1, 0, 0, 0]), 16_777_216, Data()),
			(Data([0xFF, 0xFF, 0xFF, 0xFF]), 4_294_967_295, Data()),
			// Valid with remaining data (Network Byte Order)
			(Data([0, 0, 0, 0, 100]), 0, Data([100])),
			(Data([0, 0, 0, 1, 101]), 1, Data([101])),
			(Data([0, 0, 1, 0, 102]), 256, Data([102])),
			(Data([0, 1, 0, 0, 103]), 65536, Data([103])),
			(Data([1, 0, 0, 0, 104]), 16_777_216, Data([104])),
			(Data([0xFF, 0xFF, 0xFF, 0xFF, 0xFF]), 4_294_967_295, Data([255])),
		]

		let parser = SSHProtocolParserDraft9()
		for (data, expectedInt, expectedRemainingData) in testCases {
			let (actualInt, actualRemainingData) = parser.parseUInt32(from: data)

			XCTAssertEqual(expectedInt, actualInt)
			XCTAssertEqual(expectedRemainingData, actualRemainingData)
		}
	}

	func testParseUInt64() {
		let testCases: [(data: Data, expectedInt: UInt64?, expectedRemainingData: Data.SubSequence)] = [
			// Invalid
			(Data(), nil, Data()),
			(Data([1]), nil, Data([1])),
			(Data([1, 2]), nil, Data([1, 2])),
			(Data([1, 2, 3]), nil, Data([1, 2, 3])),
			(Data([1, 2, 3, 4]), nil, Data([1, 2, 3, 4])),
			(Data([1, 2, 3, 4, 5]), nil, Data([1, 2, 3, 4, 5])),
			(Data([1, 2, 3, 4, 5, 6]), nil, Data([1, 2, 3, 4, 5, 6])),
			(Data([1, 2, 3, 4, 5, 6, 7]), nil, Data([1, 2, 3, 4, 5, 6, 7])),
			// Base valid (Network Byte Order)
			(Data([0, 0, 0, 0, 0, 0, 0, 0]), 0, Data()),
			(Data([0, 0, 0, 0, 0, 0, 0, 1]), 1, Data()),
			(Data([0, 0, 0, 0, 0, 0, 1, 0]), 256, Data()),
			(Data([0, 0, 0, 0, 0, 1, 0, 0]), 65536, Data()),
			(Data([0, 0, 0, 0, 1, 0, 0, 0]), 16_777_216, Data()),
			(Data([0, 0, 0, 1, 0, 0, 0, 0]), 4_294_967_296, Data()),
			(Data([0, 0, 1, 0, 0, 0, 0, 0]), 1_099_511_627_776, Data()),
			(Data([0, 1, 0, 0, 0, 0, 0, 0]), 281_474_976_710_656, Data()),
			(Data([1, 0, 0, 0, 0, 0, 0, 0]), 72_057_594_037_927_936, Data()),
			(Data([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]), 18_446_744_073_709_551_615, Data()),
			// Valid with remaining data (Network Byte Order)
			(Data([0, 0, 0, 0, 0, 0, 0, 0, 100]), 0, Data([100])),
			(Data([0, 0, 0, 0, 0, 0, 0, 1, 101]), 1, Data([101])),
		]

		let parser = SSHProtocolParserDraft9()
		for (data, expectedInt, expectedRemainingData) in testCases {
			let (actualInt, actualRemainingData) = parser.parseUInt64(from: data)

			XCTAssertEqual(expectedInt, actualInt)
			XCTAssertEqual(expectedRemainingData, actualRemainingData)
		}
	}

	func testParseString() {
		let testCases: [(data: Data, expectedString: String?, expectedRemainingData: Data.SubSequence)] = [
			// Invalid
			(Data(), nil, Data()),
			(Data([1]), nil, Data([1])),
			(Data([1, 2]), nil, Data([1, 2])),
			(Data([1, 2, 3]), nil, Data([1, 2, 3])),
			// Base valid (Network Byte Order length)
			(Data([0, 0, 0, 0]), "", Data()),
			(Data([0, 0, 0, 0, 1]), "", Data([1])),
			// Invalid (mismatch length and data)
			(Data([0, 0, 0, 1]), nil, Data([0, 0, 0, 1])),
			(Data([0, 0, 0, 2, 65]), nil, Data([0, 0, 0, 2, 65])),
			// Valid simple string
			(Data([0, 0, 0, 1, 65]), "A", Data()),
			(Data([0, 0, 0, 1, 66]), "B", Data()),
			(Data([0, 0, 0, 2, 65, 66]), "AB", Data()),
			(Data([0, 0, 0, 2, 66, 65]), "BA", Data()),
			(Data([0, 0, 0, 1, 65, 66]), "A", Data([66])),
		]

		let parser = SSHProtocolParserDraft9()
		for (data, expectedString, expectedRemainingData) in testCases {
			let (actualString, actualRemainingData) = parser.parseString(from: data)

			XCTAssertEqual(expectedString, actualString)
			XCTAssertEqual(expectedRemainingData, actualRemainingData)
		}
	}

	func testParseStringUnicode() {

		let expectedString = "😊"
		let stringData = expectedString.data(using: .utf8)!
		let stringLength = stringData.count

		let data = Data([0x00, 0x00, 0x00, UInt8(stringLength)] + stringData + [0x01])

		let parser = SSHProtocolParserDraft9()
		let (actualString, actualRemainingData) = parser.parseString(from: data)

		XCTAssertEqual(expectedString, actualString)
		XCTAssertEqual(Data([0x01]), actualRemainingData)
	}

	static var allTests = [
		("testParseByte", testParseByte),
		("testParseUInt32", testParseUInt32),
		("testParseUInt64", testParseUInt64),
		("testParseString", testParseString),
		("testParseStringUnicode", testParseStringUnicode),
	]
}
