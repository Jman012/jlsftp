import XCTest
@testable import jlsftp

final class OpenFlagsV3Tests: XCTestCase {

	func testFlags() {
		// Values take from https://tools.ietf.org/html/draft-ietf-secsh-filexfer-02#section-5
		XCTAssertEqual(
			jlsftp.DataLayer.Version_3.OpenFlagsV3(rawValue: 0x0000_0001),
			jlsftp.DataLayer.Version_3.OpenFlagsV3.read)
		XCTAssertEqual(
			jlsftp.DataLayer.Version_3.OpenFlagsV3(rawValue: 0x0000_0002),
			jlsftp.DataLayer.Version_3.OpenFlagsV3.write)
		XCTAssertEqual(
			jlsftp.DataLayer.Version_3.OpenFlagsV3(rawValue: 0x0000_0004),
			jlsftp.DataLayer.Version_3.OpenFlagsV3.append)
		XCTAssertEqual(
			jlsftp.DataLayer.Version_3.OpenFlagsV3(rawValue: 0x0000_0008),
			jlsftp.DataLayer.Version_3.OpenFlagsV3.create)
		XCTAssertEqual(
			jlsftp.DataLayer.Version_3.OpenFlagsV3(rawValue: 0x0000_0010),
			jlsftp.DataLayer.Version_3.OpenFlagsV3.truncate)
		XCTAssertEqual(
			jlsftp.DataLayer.Version_3.OpenFlagsV3(rawValue: 0x0000_0020),
			jlsftp.DataLayer.Version_3.OpenFlagsV3.exclusive)
	}

	static var allTests = [
		("testFlags", testFlags),
	]
}
