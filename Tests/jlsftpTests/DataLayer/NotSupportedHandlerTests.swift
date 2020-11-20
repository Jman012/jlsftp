import NIO
import XCTest
@testable import jlsftp

final class NotSupportedHandlerTests: XCTestCase {

	func testDeserialize() {
		let handler = NotSupportedPacketSerializationHandler()
		var buffer = ByteBuffer()

		let result = handler.deserialize(buffer: &buffer)
		XCTAssertNoThrow(try result.get())
		let packet = try! result.get()
		guard case .nopDebug = packet else {
			XCTFail()
			return
		}
	}

	static var allTests = [
		("testDeserialize", testDeserialize),
	]
}
