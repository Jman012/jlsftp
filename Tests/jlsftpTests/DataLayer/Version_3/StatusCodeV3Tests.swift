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

	func testFromStandard() {
		XCTAssertEqual(jlsftp.DataLayer.Version_3.StatusCodeV3.ok, jlsftp.DataLayer.Version_3.StatusCodeV3(from: StatusCode.ok))
		XCTAssertEqual(jlsftp.DataLayer.Version_3.StatusCodeV3.endOfFile, jlsftp.DataLayer.Version_3.StatusCodeV3(from: StatusCode.endOfFile))
		XCTAssertEqual(jlsftp.DataLayer.Version_3.StatusCodeV3.noSuchFile, jlsftp.DataLayer.Version_3.StatusCodeV3(from: StatusCode.noSuchFile))
		XCTAssertEqual(jlsftp.DataLayer.Version_3.StatusCodeV3.permissionDenied, jlsftp.DataLayer.Version_3.StatusCodeV3(from: StatusCode.permissionDenied))
		XCTAssertEqual(jlsftp.DataLayer.Version_3.StatusCodeV3.failure, jlsftp.DataLayer.Version_3.StatusCodeV3(from: StatusCode.failure))
		XCTAssertEqual(jlsftp.DataLayer.Version_3.StatusCodeV3.badMessage, jlsftp.DataLayer.Version_3.StatusCodeV3(from: StatusCode.badMessage))
		XCTAssertEqual(jlsftp.DataLayer.Version_3.StatusCodeV3.noConnection, jlsftp.DataLayer.Version_3.StatusCodeV3(from: StatusCode.noConnection))
		XCTAssertEqual(jlsftp.DataLayer.Version_3.StatusCodeV3.connectionLost, jlsftp.DataLayer.Version_3.StatusCodeV3(from: StatusCode.connectionLost))
		XCTAssertEqual(jlsftp.DataLayer.Version_3.StatusCodeV3.operationUnsupported, jlsftp.DataLayer.Version_3.StatusCodeV3(from: StatusCode.operationUnsupported))
	}

	static var allTests = [
		("testToStandard", testToStandard),
		("testFromStandard", testFromStandard),
	]
}
