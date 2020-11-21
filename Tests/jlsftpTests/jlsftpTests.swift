import XCTest
@testable import jlsftp

final class jlsftpTests: XCTestCase {

	static let stringOverUInt32Length: String = {
		// Tests must be run on a 64-bit system
		assert(Int.max > UInt32.max)
		// Repeating: "\0"
		let data = Data(count: Int(exactly: UInt32.max)! + 1)
		return String(bytes: data, encoding: .ascii)!
	}()

	func testExample() {
		// This is an example of a functional test case.
		// Use XCTAssert and related functions to verify your tests produce the correct
		// results.
	}

	static var allTests = [
		("testExample", testExample),
	]
}
