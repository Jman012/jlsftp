import NIO
import XCTest
@testable import jlsftp

final class StatusCodeV3Tests: XCTestCase {

	func testToStandard() {
		XCTAssertEqual(jlsftp.DataLayer.Version_3.StatusCodeV3.ok.statusCode, StatusCode.ok)
		XCTAssertEqual(jlsftp.DataLayer.Version_3.StatusCodeV3.endOfFile.statusCode, StatusCode.endOfFile)
		XCTAssertEqual(jlsftp.DataLayer.Version_3.StatusCodeV3.noSuchFile.statusCode, StatusCode.noSuchFile)
		XCTAssertEqual(jlsftp.DataLayer.Version_3.StatusCodeV3.permissionDenied.statusCode, StatusCode.permissionDenied)
		XCTAssertEqual(jlsftp.DataLayer.Version_3.StatusCodeV3.failure.statusCode, StatusCode.failure)
		XCTAssertEqual(jlsftp.DataLayer.Version_3.StatusCodeV3.badMessage.statusCode, StatusCode.badMessage)
		XCTAssertEqual(jlsftp.DataLayer.Version_3.StatusCodeV3.noConnection.statusCode, StatusCode.noConnection)
		XCTAssertEqual(jlsftp.DataLayer.Version_3.StatusCodeV3.connectionLost.statusCode, StatusCode.connectionLost)
		XCTAssertEqual(jlsftp.DataLayer.Version_3.StatusCodeV3.operationUnsupported.statusCode, StatusCode.operationUnsupported)
	}

	static var allTests = [
		("testToStandard", testToStandard),
	]
}
