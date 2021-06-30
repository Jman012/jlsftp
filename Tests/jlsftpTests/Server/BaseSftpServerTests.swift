import XCTest
import Combine
import NIO
import NIOTestUtils
import Logging
@testable import jlsftp

final class BaseSftpServerTests: XCTestCase {

	func testHandleOpenClose() {
		let eventLoop = EmbeddedEventLoop()
		let threadPool = NIOThreadPool(numberOfThreads: 1)
		threadPool.start()
		defer {
			try! threadPool.syncShutdownGracefully()
		}
		let server = BaseSftpServer(forVersion: .v3, threadPool: threadPool)

		XCTAssertNoThrow(try withTemporaryFile(content: "abc") { _, filePath in
			// Open temporary file
			let openPacket: OpenPacket = .init(
				id: 1,
				filename: filePath,
				pflags: [.read],
				fileAttributes: .empty)
			var lastReplyMessage: SftpMessage?
			let replyHandler: ReplyHandler = { message in
				lastReplyMessage = message
				return eventLoop.makeSucceededFuture(())
			}
			XCTAssertNoThrow(try server.handleOpen(packet: openPacket, on: eventLoop, using: replyHandler).wait())

			// Assert correct reply, extract handle
			guard let openReply = lastReplyMessage else {
				XCTFail()
				assert(false)
			}
			var sftpHandle: String?
			switch openReply.packet {
			case let .handleReply(handleReply):
				XCTAssertEqual(handleReply.id, 1)
				sftpHandle = handleReply.handle
			default:
				XCTFail()
			}
			guard let sftpHandleString = sftpHandle else {
				XCTFail()
				assert(false)
			}

			// Use handle to close temporary file
			lastReplyMessage = nil
			let closePacket: ClosePacket = .init(id: 2, handle: sftpHandleString)
			XCTAssertNoThrow(try server.handleClose(packet: closePacket, on: eventLoop, using: replyHandler).wait())

			// Assert correct reply
			guard let closeReply = lastReplyMessage else {
				XCTFail()
				assert(false)
			}
			switch closeReply.packet {
			case let .statusReply(statusReply):
				XCTAssertEqual(statusReply.id, 2)
				XCTAssertEqual(statusReply.statusCode, .ok)
			default:
				XCTFail()
			}

		})
	}

	static var allTests = [
		("testHandleOpenClose", testHandleOpenClose),
	]
}
