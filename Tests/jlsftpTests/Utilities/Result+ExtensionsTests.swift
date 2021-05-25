import XCTest
@testable import jlsftp

final class ResultExtensionsTests: XCTestCase {

	// MARK: Test `error?`

	func testError() {
		let resultError: Result<Bool, PacketDeserializationHandlerError> = .failure(.needMoreData)

		XCTAssertEqual(.some(.needMoreData), resultError.error)
	}

	func testSuccess() {
		let resultSuccess: Result<Bool, PacketDeserializationHandlerError> = .success(true)

		XCTAssertNil(resultSuccess.error)
	}

	static var allTests = [
		("testError", testError),
		("testSuccess", testSuccess),
	]
}
