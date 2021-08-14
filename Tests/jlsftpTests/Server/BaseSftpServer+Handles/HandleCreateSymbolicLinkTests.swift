import XCTest
import Combine
import NIO
import NIOTestUtils
import Logging
@testable import jlsftp

final class HandleCreateSymbolicLinkTests: XCTestCase {

	func testHandleCreateSymbolicLinkValidExists() {
		BaseSftpServerTests.__withServer { eventLoop, server in
			XCTAssertNoThrow(try withTemporaryFile { _, filePath in
				var lastMessage: SftpMessage?
				let replyHandler: ReplyHandler = { message in
					lastMessage = message
					return eventLoop.makeSucceededVoidFuture()
				}
				server.register(replyHandler: replyHandler)
				let symlinkPacket: Packet = .createSymbolicLink(.init(id: 1, linkPath: filePath, targetPath: filePath + "_symlink"))
				let symlinkMessage = SftpMessage(packet: symlinkPacket, dataLength: 0, shouldReadHandler: { _ in })
				XCTAssertNoThrow(try server.handle(message: symlinkMessage, on: eventLoop).wait())

				guard let statusReply = lastMessage else {
					XCTFail()
					return
				}

				switch statusReply.packet {
				case let .statusReply(statusPacket):
					XCTAssertEqual(statusPacket.statusCode, .ok)
					unlink(filePath + "_symlink")
				default:
					XCTFail()
				}
			})
		}
	}

	func testHandleCreateSymbolicLinkValidNonexistent() {
		BaseSftpServerTests.__withServer { eventLoop, server in
			XCTAssertNoThrow(try withTemporaryFile { _, filePath in
				var lastMessage: SftpMessage?
				let replyHandler: ReplyHandler = { message in
					lastMessage = message
					return eventLoop.makeSucceededVoidFuture()
				}
				server.register(replyHandler: replyHandler)
				let symlinkPacket: Packet = .createSymbolicLink(.init(id: 1, linkPath: filePath + "_doesnotexist", targetPath: filePath + "_symlink"))
				let symlinkMessage = SftpMessage(packet: symlinkPacket, dataLength: 0, shouldReadHandler: { _ in })
				XCTAssertNoThrow(try server.handle(message: symlinkMessage, on: eventLoop).wait())

				guard let statusReply = lastMessage else {
					XCTFail()
					return
				}

				switch statusReply.packet {
				case let .statusReply(statusPacket):
					XCTAssertEqual(statusPacket.statusCode, .ok)
					unlink(filePath + "_symlink")
				default:
					XCTFail()
				}
			})
		}
	}

	func testHandleCreateSymbolicLinkInvalid() {
		BaseSftpServerTests.__withServer { eventLoop, server in
			XCTAssertNoThrow(try withTemporaryFile { _, filePath in
				var lastMessage: SftpMessage?
				let replyHandler: ReplyHandler = { message in
					lastMessage = message
					return eventLoop.makeSucceededVoidFuture()
				}
				server.register(replyHandler: replyHandler)
				let symlinkPacket: Packet = .createSymbolicLink(.init(id: 1, linkPath: filePath + "_doesnotexist", targetPath: ""))
				let symlinkMessage = SftpMessage(packet: symlinkPacket, dataLength: 0, shouldReadHandler: { _ in })
				XCTAssertNoThrow(try server.handle(message: symlinkMessage, on: eventLoop).wait())

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
		("testHandleCreateSymbolicLinkValidExists", testHandleCreateSymbolicLinkValidExists),
		("testHandleCreateSymbolicLinkValidNonexistent", testHandleCreateSymbolicLinkValidNonexistent),
		("testHandleCreateSymbolicLinkInvalid", testHandleCreateSymbolicLinkInvalid),
	]
}
