import XCTest
@testable import jlsftp

final class resultExtensionsTests: XCTestCase {

	// MARK: Test `error?`

	func testError() {
		let resultError: Result<Bool, PacketSerializationHandlerError> = .failure(.needMoreData)

		XCTAssertEqual(.some(.needMoreData), resultError.error)
	}

	func testSuccess() {
		let resultSuccess: Result<Bool, PacketSerializationHandlerError> = .success(true)

		XCTAssertNil(resultSuccess.error)
	}

	static var allTests = [
		("testError", testError),
		("testSuccess", testSuccess),
	]
}
