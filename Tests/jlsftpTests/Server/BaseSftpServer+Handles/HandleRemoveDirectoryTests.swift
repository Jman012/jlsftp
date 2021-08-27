import XCTest
import Combine
import NIO
import NIOTestUtils
import Logging
@testable import jlsftp

final class HandleRemoveDirectoryTests: XCTestCase {

	func testHandleRemoveDirectoryValid() {
		BaseSftpServerTests.__withServer { eventLoop, server in
			XCTAssertNoThrow(try withTemporaryDirectoryNoRemove { folderPath in
				var lastMessage: SftpMessage?
				let replyHandler: ReplyHandler = { message in
					lastMessage = message
					return eventLoop.makeSucceededVoidFuture()
				}
				server.register(replyHandler: replyHandler)
				let removeDirPacket: Packet = .removeDirectory(.init(id: 1, path: folderPath))
				let removeDirMessage = SftpMessage(packet: removeDirPacket, dataLength: 0, shouldReadHandler: { _ in })
				XCTAssertNoThrow(try server.handle(message: removeDirMessage, on: eventLoop).wait())

				guard let statusReply = lastMessage else {
					XCTFail()
					return
				}

				switch statusReply.packet {
				case let .statusReply(statusPacket):
					XCTAssertEqual(statusPacket.id, 1)
					XCTAssertEqual(statusPacket.statusCode, .ok)
				default:
					XCTFail()
				}
			})
		}
	}

	static var allTests = [
		("testHandleRemoveDirectoryValid", testHandleRemoveDirectoryValid),
	]
}
