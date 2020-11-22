import Foundation
import XCTest
@testable import jlsftp

final class PacketSerializationHandlerTests: XCTestCase {

	func testCustomMapErrorNeedMoreData() {
		let errorNeedMoreData = PacketDeserializationHandlerError.needMoreData

		XCTAssertEqual(errorNeedMoreData.customMapError(wrapper: "test"), .needMoreData)
	}

	func testCustomMapErrorInvalidData() {
		let errorInvalidData = PacketDeserializationHandlerError.invalidData(reason: "test inner")

		XCTAssertEqual(errorInvalidData.customMapError(wrapper: "test outer"), .invalidData(reason: "test outer: test inner"))
	}

	static var allTests = [
		("testCustomMapErrorNeedMoreData", testCustomMapErrorNeedMoreData),
		("testCustomMapErrorInvalidData", testCustomMapErrorInvalidData),
	]
}
