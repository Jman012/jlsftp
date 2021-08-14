import XCTest
import Combine
import NIO
import NIOTestUtils
import Logging
@testable import jlsftp

final class HandleMakeDirectoryTests: XCTestCase {

	func testHandleMakeDirectoryValid() {
		BaseSftpServerTests.__withServer { eventLoop, server in
			XCTAssertNoThrow(try withTemporaryDirectory { folderPath in
				var lastMessage: SftpMessage?
				let replyHandler: ReplyHandler = { message in
					lastMessage = message
					return eventLoop.makeSucceededVoidFuture()
				}
				server.register(replyHandler: replyHandler)
				let mkdirPacket: Packet = .makeDirectory(.init(id: 1, path: folderPath + "/HandleMakeDirectoryTests_TestDir", fileAttributes: .empty))
				let mkdirMessage = SftpMessage(packet: mkdirPacket, dataLength: 0, shouldReadHandler: { _ in })
				XCTAssertNoThrow(try server.handle(message: mkdirMessage, on: eventLoop).wait())

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

	func testHandleMakeDirectory() {
		BaseSftpServerTests.__withServer { eventLoop, server in
			var lastMessage: SftpMessage?
			let replyHandler: ReplyHandler = { message in
				lastMessage = message
				return eventLoop.makeSucceededVoidFuture()
			}
			server.register(replyHandler: replyHandler)
			let mkdirPacket: Packet = .makeDirectory(.init(id: 1, path: "", fileAttributes: .empty))
			let mkdirMessage = SftpMessage(packet: mkdirPacket, dataLength: 0, shouldReadHandler: { _ in })
			XCTAssertNoThrow(try server.handle(message: mkdirMessage, on: eventLoop).wait())

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
		}
	}

	static var allTests = [
		("testHandleMakeDirectoryValid", testHandleMakeDirectoryValid),
		("testHandleMakeDirectory", testHandleMakeDirectory),
	]
}
