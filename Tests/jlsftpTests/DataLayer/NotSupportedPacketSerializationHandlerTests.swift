import NIO
import XCTest
@testable import jlsftp

final class NotSupportedPacketSerializationHandlerTests: XCTestCase {

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

	func testSerialize() {
		let handler = NotSupportedPacketSerializationHandler()
		var buffer = ByteBuffer()

		XCTAssertTrue(handler.serialize(packet: .nopDebug(NOPDebugPacket(message: "test")), to: &buffer))
		XCTAssertEqual(ByteBuffer(), buffer)
	}

	static var allTests = [
		("testDeserialize", testDeserialize),
		("testSerialize", testSerialize),
	]
}
