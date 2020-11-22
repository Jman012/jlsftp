import NIO
import XCTest
@testable import jlsftp

final class StatusCodeV3Tests: XCTestCase {

	func testToStandard() {
		XCTAssertEqual(jlsftp.SftpProtocol.Version_3.StatusCodeV3.ok.statusCode, StatusCode.ok)
		XCTAssertEqual(jlsftp.SftpProtocol.Version_3.StatusCodeV3.endOfFile.statusCode, StatusCode.endOfFile)
		XCTAssertEqual(jlsftp.SftpProtocol.Version_3.StatusCodeV3.noSuchFile.statusCode, StatusCode.noSuchFile)
		XCTAssertEqual(jlsftp.SftpProtocol.Version_3.StatusCodeV3.permissionDenied.statusCode, StatusCode.permissionDenied)
		XCTAssertEqual(jlsftp.SftpProtocol.Version_3.StatusCodeV3.failure.statusCode, StatusCode.failure)
		XCTAssertEqual(jlsftp.SftpProtocol.Version_3.StatusCodeV3.badMessage.statusCode, StatusCode.badMessage)
		XCTAssertEqual(jlsftp.SftpProtocol.Version_3.StatusCodeV3.noConnection.statusCode, StatusCode.noConnection)
		XCTAssertEqual(jlsftp.SftpProtocol.Version_3.StatusCodeV3.connectionLost.statusCode, StatusCode.connectionLost)
		XCTAssertEqual(jlsftp.SftpProtocol.Version_3.StatusCodeV3.operationUnsupported.statusCode, StatusCode.operationUnsupported)
	}

	func testFromStandard() {
		XCTAssertEqual(jlsftp.SftpProtocol.Version_3.StatusCodeV3.ok, jlsftp.SftpProtocol.Version_3.StatusCodeV3(from: StatusCode.ok))
		XCTAssertEqual(jlsftp.SftpProtocol.Version_3.StatusCodeV3.endOfFile, jlsftp.SftpProtocol.Version_3.StatusCodeV3(from: StatusCode.endOfFile))
		XCTAssertEqual(jlsftp.SftpProtocol.Version_3.StatusCodeV3.noSuchFile, jlsftp.SftpProtocol.Version_3.StatusCodeV3(from: StatusCode.noSuchFile))
		XCTAssertEqual(jlsftp.SftpProtocol.Version_3.StatusCodeV3.permissionDenied, jlsftp.SftpProtocol.Version_3.StatusCodeV3(from: StatusCode.permissionDenied))
		XCTAssertEqual(jlsftp.SftpProtocol.Version_3.StatusCodeV3.failure, jlsftp.SftpProtocol.Version_3.StatusCodeV3(from: StatusCode.failure))
		XCTAssertEqual(jlsftp.SftpProtocol.Version_3.StatusCodeV3.badMessage, jlsftp.SftpProtocol.Version_3.StatusCodeV3(from: StatusCode.badMessage))
		XCTAssertEqual(jlsftp.SftpProtocol.Version_3.StatusCodeV3.noConnection, jlsftp.SftpProtocol.Version_3.StatusCodeV3(from: StatusCode.noConnection))
		XCTAssertEqual(jlsftp.SftpProtocol.Version_3.StatusCodeV3.connectionLost, jlsftp.SftpProtocol.Version_3.StatusCodeV3(from: StatusCode.connectionLost))
		XCTAssertEqual(jlsftp.SftpProtocol.Version_3.StatusCodeV3.operationUnsupported, jlsftp.SftpProtocol.Version_3.StatusCodeV3(from: StatusCode.operationUnsupported))
	}

	static var allTests = [
		("testToStandard", testToStandard),
		("testFromStandard", testFromStandard),
	]
}
