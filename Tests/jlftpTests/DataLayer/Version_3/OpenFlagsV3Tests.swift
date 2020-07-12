import XCTest
@testable import jlftp

final class OpenFlagsV3Tests: XCTestCase {

	func testFlags() {
		// Values take from https://tools.ietf.org/html/draft-ietf-secsh-filexfer-02#section-5
		XCTAssertEqual(
			jlftp.DataLayer.Version_3.OpenFlagsV3(rawValue: 0x0000_0001),
			jlftp.DataLayer.Version_3.OpenFlagsV3.read)
		XCTAssertEqual(
			jlftp.DataLayer.Version_3.OpenFlagsV3(rawValue: 0x0000_0002),
			jlftp.DataLayer.Version_3.OpenFlagsV3.write)
		XCTAssertEqual(
			jlftp.DataLayer.Version_3.OpenFlagsV3(rawValue: 0x0000_0004),
			jlftp.DataLayer.Version_3.OpenFlagsV3.append)
		XCTAssertEqual(
			jlftp.DataLayer.Version_3.OpenFlagsV3(rawValue: 0x0000_0008),
			jlftp.DataLayer.Version_3.OpenFlagsV3.create)
		XCTAssertEqual(
			jlftp.DataLayer.Version_3.OpenFlagsV3(rawValue: 0x0000_0010),
			jlftp.DataLayer.Version_3.OpenFlagsV3.truncate)
		XCTAssertEqual(
			jlftp.DataLayer.Version_3.OpenFlagsV3(rawValue: 0x0000_0020),
			jlftp.DataLayer.Version_3.OpenFlagsV3.exclusive)
	}

	static var allTests = [
		("testFlags", testFlags),
	]
}
