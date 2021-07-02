import XCTest
import Combine
import NIO
import NIOTestUtils
import Logging
@testable import jlsftp

final class BaseSftpServerTests: XCTestCase {

	func testRegisterReplyHandler() {
		let eventLoop = EmbeddedEventLoop()
		let threadPool = NIOThreadPool(numberOfThreads: 1)
		let server = BaseSftpServer(forVersion: .min, threadPool: threadPool)

		var lastMessage: SftpMessage?
		server.register(replyHandler: { message in
			lastMessage = message
			return eventLoop.makeSucceededFuture(())
		})

		let message = SftpMessage(packet: .close(.init(id: 1, handle: "a")), dataLength: 0, shouldReadHandler: { _ in })
		_ = server.replyHandler?(message)
		XCTAssertNotNil(lastMessage)
		switch lastMessage?.packet {
		case .close:
			break
		default:
			XCTFail()
		}
	}

	func testHandle() {
		
	}

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

	func testHandleReadSimple() {
		_testHandleRead(content: "abc", offset: 0, length: 3, expect: "abc")
	}

	func testHandleReadOffset() {
		_testHandleRead(content: "abc", offset: 1, length: 2, expect: "bc")
	}

	func testHandleReadEof() {
		_testHandleRead(content: "abcdef", offset: 2, length: 6, expect: "cdef")
	}

	func testHandleReadLargeFile() {
		let largeFileContent: String = String(repeating: "Hello ", count: 1_000_000)
		_testHandleRead(content: largeFileContent, offset: 0, length: UInt32("Hello ".utf8.count * 1_000_000), expect: largeFileContent)
	}

	func _testHandleRead(content: String, offset: UInt64, length: UInt32, expect: String) {
		let eventLoop = EmbeddedEventLoop()
		let threadPool = NIOThreadPool(numberOfThreads: 1)
		threadPool.start()
		defer {
			try! threadPool.syncShutdownGracefully()
		}
		let server = BaseSftpServer(forVersion: .v3, threadPool: threadPool)

		XCTAssertNoThrow(try withTemporaryFile(content: content) { _, filePath in
			// Open temporary file
			let openPacket: OpenPacket = .init(
				id: 1,
				filename: filePath,
				pflags: [.read],
				fileAttributes: .empty)
			var lastReplyMessage: SftpMessage?
			var lastReplyPromise: EventLoopPromise<Void> = eventLoop.makePromise()
			var replyHandler: ReplyHandler = { message in
				lastReplyMessage = message
				return lastReplyPromise.futureResult
			}
			lastReplyPromise.completeWith(.success(()))
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

			// Use handle to read temporary file
			lastReplyMessage = nil
			lastReplyPromise = eventLoop.makePromise()
			var accumulatedBuffer = ByteBuffer()
			var cancellable: AnyCancellable?
			replyHandler = { message in
				lastReplyMessage = message
				cancellable = message.data.sink(receiveCompletion: { _ in
					lastReplyPromise.succeed(())
				}, receiveValue: { byteBuffer in
					accumulatedBuffer.writeBytes(byteBuffer.getBytes(at: 0, length: byteBuffer.readableBytes)!)
				})

				return lastReplyPromise.futureResult
			}

			let readPacket: ReadPacket = .init(id: 2, handle: sftpHandleString, offset: offset, length: length)
			XCTAssertNoThrow(try server.handleRead(packet: readPacket, on: eventLoop, using: replyHandler).wait())

			// Assert correct reply
			guard let readReply = lastReplyMessage else {
				XCTFail()
				assert(false)
			}
			switch readReply.packet {
			case let .dataReply(dataReply):
				XCTAssertEqual(dataReply.id, 2)
			default:
				XCTFail()
			}

			XCTAssertNotNil(cancellable)
			XCTAssertEqual(accumulatedBuffer.getString(at: 0, length: accumulatedBuffer.readableBytes), expect)

		})
	}

	static var allTests = [
		("testHandleOpenClose", testHandleOpenClose),
		("testHandleReadSimple", testHandleReadSimple),
		("testHandleReadOffset", testHandleReadOffset),
		("testHandleReadEof", testHandleReadEof),
		("testHandleReadLargeFile", testHandleReadLargeFile),
	]
}
