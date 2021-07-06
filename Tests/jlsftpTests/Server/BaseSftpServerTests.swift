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
		let server = BaseSftpServer(forVersion: .min, threadPool: threadPool, logger: Logger(label: "test"))

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

	func testHandleNoReplyHandler() {
		let eventLoop = EmbeddedEventLoop()
		let threadPool = NIOThreadPool(numberOfThreads: 1)
		let server = BaseSftpServer(forVersion: .min, threadPool: threadPool, logger: Logger(label: "test"))

		// Purposefully do not register a ReplyHandler
		let message = SftpMessage(packet: .close(.init(id: 1, handle: "a")), dataLength: 0, shouldReadHandler: { _ in})
		let future = server.handle(message: message, on: eventLoop)
		var didCall = false
		_ = future.always {
			didCall = true
			switch $0 {
			case .success:
				XCTFail()
			case .failure(BaseSftpServer.HandleError.noReplyHandlerSetup):
				break
			default:
				XCTFail()
			}
		}
		XCTAssert(didCall)
	}

	func testHandleOpenClose() {
		let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
		defer {
			try! group.syncShutdownGracefully()
		}
		let eventLoop = group.next()
		let threadPool = NIOThreadPool(numberOfThreads: 1)
		threadPool.start()
		defer {
			try! threadPool.syncShutdownGracefully()
		}
		let server = BaseSftpServer(forVersion: .v3, threadPool: threadPool, logger: Logger(label: "test"))

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
			server.register(replyHandler: replyHandler)
			var message = SftpMessage(packet: .open(openPacket), dataLength: 0, shouldReadHandler: { _ in })
			XCTAssertNoThrow(try server.handle(message: message, on: eventLoop).wait())

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
			message = SftpMessage(packet: .close(closePacket), dataLength: 0, shouldReadHandler: { _ in })
			XCTAssertNoThrow(try server.handle(message: message, on: eventLoop).wait())

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
		_testHandleRead(content: largeFileContent, offset: 0, length: UInt32(largeFileContent.utf8.count), expect: largeFileContent)
	}

	func _testHandleRead(content: String, offset: UInt64, length: UInt32, expect: String) {
		let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
		defer {
			try! group.syncShutdownGracefully()
		}
		let eventLoop = group.next()
		let threadPool = NIOThreadPool(numberOfThreads: 1)
		threadPool.start()
		defer {
			try! threadPool.syncShutdownGracefully()
		}
		let server = BaseSftpServer(forVersion: .v3, threadPool: threadPool, logger: Logger(label: "test"))

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
			server.register(replyHandler: replyHandler)
			var message = SftpMessage(packet: .open(openPacket), dataLength: 0, shouldReadHandler: { _ in })
			XCTAssertNoThrow(try server.handle(message: message, on: eventLoop).wait())

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
			var promises: [EventLoopPromise<Void>] = []
			let promiseLock = DispatchSemaphore(value: 1)
			replyHandler = { message in
				lastReplyMessage = message
				cancellable = message.data.futureSink(maxConcurrent: 10, receiveCompletion: { completion, outstanding in
					EventLoopFuture
						.reduce((), outstanding, on: eventLoop, { _, _ in () })
						.cascade(to: lastReplyPromise)
				}, receiveValue: { byteBuffer in
					let promise: EventLoopPromise<Void> = eventLoop.makePromise()
					promiseLock.wait()
					promises.append(promise)
					promiseLock.signal()
					accumulatedBuffer.writeBytes(byteBuffer.getBytes(at: 0, length: byteBuffer.readableBytes)!)
					return promise.futureResult
				})

				return lastReplyPromise.futureResult
			}

			let readPacket: ReadPacket = .init(id: 2, handle: sftpHandleString, offset: offset, length: length)
			server.register(replyHandler: replyHandler)
			message = SftpMessage(packet: .read(readPacket), dataLength: 0, shouldReadHandler: { _ in })

			// Every 50ms, succeed the queued promises from reading. This should trigger
			// backpressure inside of BaseSftpServer.handleRead(:::) for code coverage.
			// Difficult to tell if it actually triggered, or if it should trigger.
			let queue = DispatchQueue(label: "_testHandleRead")
			let queueScheduleCancellabe = queue.schedule(after: queue.now, interval: .milliseconds(50)) {
				promiseLock.wait()
				promises.forEach {
					$0.succeed(())
				}
				promises.removeAll()
				promiseLock.signal()
			}
			XCTAssertNoThrow(try server.handle(message: message, on: eventLoop).wait())
			queueScheduleCancellabe.cancel()


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

	func testHandleWriteSimple() {
		_testHandleWrite(content: "abc", offset: 0, expect: "abc")
	}

	func testHandleWriteOffset() {
		_testHandleWrite(content: "abc", offset: 1, expect: "\0abc")
	}

	func testHandleWriteLargeFile() {
		let largeFileContent: String = String(repeating: "Hello ", count: 1_000)
		_testHandleWrite(content: largeFileContent, offset: 0, expect: largeFileContent)
	}

	func _testHandleWrite(content: String, offset: UInt64, expect: String) {
		let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
		defer {
			try! group.syncShutdownGracefully()
		}
		let eventLoop = group.next()
		let threadPool = NIOThreadPool(numberOfThreads: 1)
		threadPool.start()
		defer {
			try! threadPool.syncShutdownGracefully()
		}
		let server = BaseSftpServer(forVersion: .v3, threadPool: threadPool, logger: Logger(label: "test"))

		XCTAssertNoThrow(try withTemporaryFile(content: "") { _, filePath in
			// Open temporary file
			let openPacket: OpenPacket = .init(
				id: 1,
				filename: filePath,
				pflags: [.write],
				fileAttributes: .empty)
			var lastReplyMessage: SftpMessage?
			var lastReplyPromise: EventLoopPromise<Void> = eventLoop.makePromise()
			var replyHandler: ReplyHandler = { message in
				lastReplyMessage = message
				return lastReplyPromise.futureResult
			}
			lastReplyPromise.completeWith(.success(()))
			server.register(replyHandler: replyHandler)
			var message = SftpMessage(packet: .open(openPacket), dataLength: 0, shouldReadHandler: { _ in })
			XCTAssertNoThrow(try server.handle(message: message, on: eventLoop).wait())

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

			// Use handle to write to temporary file
			lastReplyMessage = nil
			lastReplyPromise = eventLoop.makePromise()
			lastReplyPromise.succeed(())
			replyHandler = { message in
				lastReplyMessage = message
				return lastReplyPromise.futureResult
			}
			server.register(replyHandler: replyHandler)
			let writePacket: WritePacket = .init(id: 2, handle: sftpHandleString, offset: offset)
			var shouldWrite = false
			message = SftpMessage(packet: .write(writePacket),
								  dataLength: UInt32(content.utf8.count),
								  shouldReadHandler: { should in
									shouldWrite = should
								  })

			let replyFuture = server.handle(message: message, on: eventLoop)

			// Write data to message
			var index = content.utf8.startIndex
			while index < content.utf8.endIndex {
				if shouldWrite {
					let result = message.sendData(ByteBuffer(bytes: [content.utf8[index]]))
					index = content.utf8.index(index, offsetBy: 1)
					switch result {
					case let .success(isComplete):
						XCTAssertEqual(isComplete, index == content.utf8.endIndex)
					default:
						XCTFail()
					}
				} else {
					let promise = eventLoop.makePromise(of: Void.self)
					eventLoop.execute {
						promise.succeed(())
					}
					XCTAssertNoThrow(try promise.futureResult.wait())
				}
			}
			message.completeData()
			XCTAssertNoThrow(try replyFuture.wait())

			// Ensure the server responded correctly.
			guard let writeReply = lastReplyMessage else {
				XCTFail()
				assert(false)
			}
			switch writeReply.packet {
			case let .statusReply(packet):
				XCTAssertEqual(packet.statusCode, .ok)
			default:
				XCTFail()
			}

			// Ensure the file was written correctly
			var fileData: Data?
			XCTAssertNoThrow(fileData = try Data(contentsOf: URL(fileURLWithPath: filePath)))
			var expect2 = expect
			expect2.withUTF8 { buffer in
				XCTAssertEqual(Data(buffer: buffer), fileData!)
			}
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
