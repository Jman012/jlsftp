import XCTest
import Combine
import NIO
import NIOTestUtils
import Logging
@testable import jlsftp

final class HandleRemoveTests: XCTestCase {

	func testHandleRemoveValid() {
		BaseSftpServerTests.__withServer { eventLoop, server in
			XCTAssertNoThrow(try withTemporaryFileNoUnlink(content: "abc") { _, filepath in
				var lastMessage: SftpMessage?
				let replyHandler: ReplyHandler = { message in
					lastMessage = message
					return eventLoop.makeSucceededVoidFuture()
				}
				server.register(replyHandler: replyHandler)
				let removePacket: Packet = .remove(RemovePacket(id: 1, filename: filepath))
				let removeMessage = SftpMessage(packet: removePacket, dataLength: 0, shouldReadHandler: { _ in })
				XCTAssertNoThrow(try server.handle(message: removeMessage, on: eventLoop).wait())

				guard let statusReply = lastMessage else {
					XCTFail()
					return
				}

				switch statusReply.packet {
				case let .statusReply(statusPacket):
					XCTAssertEqual(statusPacket.statusCode, .ok)
				default:
					XCTFail()
				}
			})
		}
	}

	func testHandleRemoveUnknownPath() {
		BaseSftpServerTests.__withServer { eventLoop, server in
			var lastMessage: SftpMessage?
			let replyHandler: ReplyHandler = { message in
				lastMessage = message
				return eventLoop.makeSucceededVoidFuture()
			}
			server.register(replyHandler: replyHandler)
			let removePacket: Packet = .remove(RemovePacket(id: 1, filename: "/thisdoesnotexist"))
			let removeMessage = SftpMessage(packet: removePacket, dataLength: 0, shouldReadHandler: { _ in })
			XCTAssertNoThrow(try server.handle(message: removeMessage, on: eventLoop).wait())

			guard let statusReply = lastMessage else {
				XCTFail()
				return
			}

			switch statusReply.packet {
			case let .statusReply(statusPacket):
				XCTAssertEqual(statusPacket.statusCode, .noSuchFile)
			default:
				XCTFail()
			}
		}
	}

	func testHandleRemoveInvalidDirectory() {
		BaseSftpServerTests.__withServer { eventLoop, server in
			XCTAssertNoThrow(try withTemporaryDirectory { folderPath in
				var lastMessage: SftpMessage?
				let replyHandler: ReplyHandler = { message in
					lastMessage = message
					return eventLoop.makeSucceededVoidFuture()
				}
				server.register(replyHandler: replyHandler)
				let removePacket: Packet = .remove(RemovePacket(id: 1, filename: folderPath))
				let removeMessage = SftpMessage(packet: removePacket, dataLength: 0, shouldReadHandler: { _ in })
				XCTAssertNoThrow(try server.handle(message: removeMessage, on: eventLoop).wait())

				guard let statusReply = lastMessage else {
					XCTFail()
					return
				}

				switch statusReply.packet {
				case let .statusReply(statusPacket):
					XCTAssertEqual(statusPacket.statusCode, .failure)
				default:
					XCTFail()
				}
			})
		}
	}

	static var allTests = [
		("testHandleRemoveValid", testHandleRemoveValid),
		("testHandleRemoveUnknownPath", testHandleRemoveUnknownPath),
		("testHandleRemoveInvalidDirectory", testHandleRemoveInvalidDirectory),
	]
}
