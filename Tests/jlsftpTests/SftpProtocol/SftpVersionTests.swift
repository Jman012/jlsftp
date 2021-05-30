import NIO
import XCTest
@testable import jlsftp

final class SftpVersionTests: XCTestCase {

	func testLessThan() {
		XCTAssert(jlsftp.SftpProtocol.SftpVersion.v3 < .v4)
		XCTAssert(jlsftp.SftpProtocol.SftpVersion.v3 < .v5)
		XCTAssert(jlsftp.SftpProtocol.SftpVersion.v3 < .v6)
		XCTAssert(jlsftp.SftpProtocol.SftpVersion.v4 < .v5)
		XCTAssert(jlsftp.SftpProtocol.SftpVersion.v4 < .v6)
		XCTAssert(jlsftp.SftpProtocol.SftpVersion.v5 < .v6)
	}

	func testGreaterThan() {
		XCTAssert(jlsftp.SftpProtocol.SftpVersion.v6 > .v3)
		XCTAssert(jlsftp.SftpProtocol.SftpVersion.v6 > .v4)
		XCTAssert(jlsftp.SftpProtocol.SftpVersion.v6 > .v5)
	}

	static var allTests = [
		("testLessThan", testLessThan),
		("testGreaterThan", testGreaterThan),
	]
}
