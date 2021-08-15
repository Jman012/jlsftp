import XCTest
import Combine
import NIO
import NIOTestUtils
import Logging
@testable import jlsftp

final class HandleOpenDirectoryTests: XCTestCase {

	func testHandleOpenDirectoryValid() {
		BaseSftpServerTests._testWithTemporaryDirectory { _, _, _, _ in
			// Do nothing. Just open and close the file.
		}
	}

	func testHandleOpenDirectoryInvalid() {
		BaseSftpServerTests.__withServer { eventLoop, server in
			XCTAssertNoThrow(try withTemporaryDirectory { folderPath in
				var lastMessage: SftpMessage?
				let replyHandler: ReplyHandler = { message in
					lastMessage = message
					return eventLoop.makeSucceededVoidFuture()
				}
				server.register(replyHandler: replyHandler)
				let openDirPacket: Packet = .openDirectory(.init(id: 1, path: folderPath + "/doesnotexist/"))
				let openDirMessage = SftpMessage(packet: openDirPacket, dataLength: 0, shouldReadHandler: { _ in })
				XCTAssertNoThrow(try server.handle(message: openDirMessage, on: eventLoop).wait())

				guard let handleReply = lastMessage else {
					XCTFail()
					return
				}

				switch handleReply.packet {
				case let .statusReply(statusPacket):
					XCTAssertEqual(statusPacket.id, 1)
					XCTAssertEqual(statusPacket.statusCode, .failure)
				default:
					XCTFail()
				}
			})
		}
	}

	static var allTests = [
		("testHandleOpenDirectoryValid", testHandleOpenDirectoryValid),
		("testHandleOpenDirectoryInvalid", testHandleOpenDirectoryInvalid),
	]
}
