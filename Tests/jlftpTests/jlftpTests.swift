import XCTest
@testable import jlftp

final class jlftpTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(jlftp().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
