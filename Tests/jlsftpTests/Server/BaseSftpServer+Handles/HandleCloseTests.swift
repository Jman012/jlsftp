import XCTest
import Combine
import NIO
import NIOTestUtils
import Logging
@testable import jlsftp

final class HandleCloseTests: XCTestCase {

	func testHandleOpenClose() {
		BaseSftpServerTests._testWithTemporaryFile(content: "abc", openFlags: [.read]) { _, _, _, _ in
			// Do nothing. Just open and close the file.
		}
	}

	func testHandleCloseBadHandle() {
		BaseSftpServerTests.__withServer { eventLoop, server in
			// Use handle to close temporary file
			var lastReplyMessage: SftpMessage?
			server.register(replyHandler: { message in
				lastReplyMessage = message
				return eventLoop.makeSucceededVoidFuture()
			})
			let closePacket: ClosePacket = .init(id: 2, handle: "this handle does not exist")
			let message = SftpMessage(packet: .close(closePacket), dataLength: 0, shouldReadHandler: { _ in })
			XCTAssertNoThrow(try server.handle(message: message, on: eventLoop).wait())

			// Assert correct reply
			guard let closeReply = lastReplyMessage else {
				XCTFail()
				return
			}
			switch closeReply.packet {
			case let .statusReply(statusReply):
				XCTAssertEqual(statusReply.id, 2)
				XCTAssertEqual(statusReply.statusCode, .noSuchFile)
			default:
				XCTFail()
			}
		}
	}

	static var allTests = [
		("testHandleOpenClose", testHandleOpenClose),
		("testHandleCloseBadHandle", testHandleCloseBadHandle),
	]
}
