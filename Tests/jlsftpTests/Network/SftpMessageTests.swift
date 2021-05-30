import XCTest
import Combine
import NIO
@testable import jlsftp

final class SftpMessageTests: XCTestCase {

	func testValid() {
		var shouldRead = false
		let message = SftpMessage(
			packet: .initializeV4(InitializePacketV4(version: .v6)),
			dataLength: 4,
			shouldReadHandler: { read in shouldRead = read })

		XCTAssertEqual(message.packet, .initializeV4(InitializePacketV4(version: .v6)))
		XCTAssertEqual(shouldRead, false)
		_ = message.data.sink(receiveValue: { _ in })
		XCTAssertEqual(shouldRead, true)
	}

	static var allTests = [
		("testValid", testValid),
	]
}
