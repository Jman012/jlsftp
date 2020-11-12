import NIO
import XCTest
@testable import jlsftp

final class NotSupportedHandlerTests: XCTestCase {

	func testDeserialize() {
		let handler = NotSupportedHandler()
		var buffer = ByteBuffer()

		let result = handler.deserialize(buffer: &buffer)
		XCTAssertNoThrow(try result.get())
		let packet = try! result.get()
		XCTAssert(packet is SerializationErrorPacket)
	}

	static var allTests = [
		("testDeserialize", testDeserialize),
	]
}
