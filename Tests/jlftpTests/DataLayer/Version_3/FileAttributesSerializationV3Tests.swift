import XCTest
@testable import jlftp

final class FileAttributesSerializationV3Tests: XCTestCase {

	func testFlags() {
		// Values take from https://tools.ietf.org/html/draft-ietf-secsh-filexfer-02#section-5
		XCTAssertEqual(
			jlftp.DataLayer.Version_3.FileAttributesFlags(rawValue: 0x0000_0001),
			jlftp.DataLayer.Version_3.FileAttributesFlags.size)
		XCTAssertEqual(
			jlftp.DataLayer.Version_3.FileAttributesFlags(rawValue: 0x0000_0002),
			jlftp.DataLayer.Version_3.FileAttributesFlags.userAndGroupIds)
		XCTAssertEqual(
			jlftp.DataLayer.Version_3.FileAttributesFlags(rawValue: 0x0000_0004),
			jlftp.DataLayer.Version_3.FileAttributesFlags.permissions)
		XCTAssertEqual(
			jlftp.DataLayer.Version_3.FileAttributesFlags(rawValue: 0x0000_0008),
			jlftp.DataLayer.Version_3.FileAttributesFlags.accessAndModificationTimes)
		XCTAssertEqual(
			jlftp.DataLayer.Version_3.FileAttributesFlags(rawValue: 0x8000_0000),
			jlftp.DataLayer.Version_3.FileAttributesFlags.extendedAttributes)
	}

	static var allTests = [
		("testFlags", testFlags),
	]
}
