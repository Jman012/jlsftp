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
		_testWithTemporaryFile(content:"abc", openFlags: [.read]) { _, _, _, _ in
			// Do nothing. Just open and close the file.
		}
	}

	func testHandleUnknownFile() {
		__withServer { eventLoop, server in
			// Open temporary file
			let openPacket: OpenPacket = .init(
				id: 1,
				filename: "/nonexistent.txt",
				pflags: [.read], // Use exclusive without create.
				fileAttributes: .empty)
			var lastReplyMessage: SftpMessage?
			let replyHandler: ReplyHandler = { message in
				lastReplyMessage = message
				return eventLoop.makeSucceededVoidFuture()
			}
			server.register(replyHandler: replyHandler)
			let message = SftpMessage(packet: .open(openPacket), dataLength: 0, shouldReadHandler: { _ in })
			XCTAssertNoThrow(try server.handle(message: message, on: eventLoop).wait())

			// Assert correct reply, extract handle
			guard let openReply = lastReplyMessage else {
				XCTFail()
				return
			}

			switch openReply.packet {
			case let .statusReply(statusReply):
				XCTAssertEqual(statusReply.id, 1)
				XCTAssertEqual(statusReply.statusCode, .noSuchFile)
			default:
				XCTFail()
			}
		}
	}

	func testHandleCloseBadHandle() {
		__withServer { eventLoop, server in
			// Use handle to close temporary file
			var lastReplyMessage: SftpMessage? = nil
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
		_testWithTemporaryFile(content: content, openFlags: [.read]) { sftpHandleString, _, eventLoop, server in
			// Use handle to read temporary file
			var lastReplyMessage: SftpMessage? = nil
			let lastReplyPromise: EventLoopPromise<Void> = eventLoop.makePromise()
			var accumulatedBuffer = ByteBuffer()
			var cancellable: AnyCancellable?
			var promises: [EventLoopPromise<Void>] = []
			let promiseLock = DispatchSemaphore(value: 1)
			let replyHandler: ReplyHandler = { message in
				lastReplyMessage = message
				cancellable = message.data.futureSink(maxConcurrent: 10, eventLoop: eventLoop, receiveCompletion: { completion in
					switch completion {
					case .finished:
						lastReplyPromise.succeed(())
					case let .failure(error):
						lastReplyPromise.fail(error)
					}
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
			let message = SftpMessage(packet: .read(readPacket), dataLength: 0, shouldReadHandler: { _ in })

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
				return
			}
			switch readReply.packet {
			case let .dataReply(dataReply):
				XCTAssertEqual(dataReply.id, 2)
			default:
				XCTFail()
			}

			XCTAssertNotNil(cancellable)
			XCTAssertEqual(accumulatedBuffer.getString(at: 0, length: accumulatedBuffer.readableBytes), expect)

		}
	}

	func testHandleReadBadHandle() {
		XCTAssertNoThrow(__withServer { eventLoop, server in
			var lastMessage: SftpMessage?
			let replyHandler: ReplyHandler = { message in
				lastMessage = message
				return eventLoop.makeSucceededVoidFuture()
			}
			server.register(replyHandler: replyHandler)
			let packet: Packet = .read(.init(id: 2, handle: "doesn't exist", offset: 0, length: 1))
			let message = SftpMessage(packet: packet, dataLength: 0, shouldReadHandler: { _ in })
			XCTAssertNoThrow(try server.handle(message: message, on: eventLoop).wait())

			guard let readReply = lastMessage else {
				XCTFail()
				return
			}

			switch readReply.packet {
			case let .statusReply(statusPacket):
				XCTAssertEqual(statusPacket.statusCode, .noSuchFile)
			default:
				XCTFail()
			}
		})
	}

	func testHandleReadDirectoryFail() {
		__withServer { eventLoop, server in
			XCTAssertNoThrow(try withTemporaryDirectory { folderPath in
				let sftpHandleString = __openFile(filePath: folderPath,
												  openFlags: [.read],
												  eventLoop: eventLoop,
												  server: server)

				var lastMessage: SftpMessage?
				let replyHandler: ReplyHandler = { message in
					lastMessage = message
					return eventLoop.makeSucceededVoidFuture()
				}
				server.register(replyHandler: replyHandler)
				let packet: Packet = .read(.init(id: 2, handle: sftpHandleString, offset: 0, length: 1))
				let message = SftpMessage(packet: packet, dataLength: 0, shouldReadHandler: { _ in })
				XCTAssertNoThrow(try server.handle(message: message, on: eventLoop).wait())

				guard let readReply = lastMessage else {
					XCTFail()
					return
				}

				switch readReply.packet {
				case let .statusReply(statusPacket):
					XCTAssertEqual(statusPacket.statusCode, .failure)
				default:
					XCTFail()
				}
			})
		}
	}

	func testHandleWriteSimple() {
		_testHandleWrite(initialContent: "", contentToWrite: "abc", offset: 0, expect: "abc")
	}

	func testHandleWriteOffset() {
		_testHandleWrite(initialContent: "", contentToWrite: "abc", offset: 1, expect: "\0abc")
	}

	func testHandleWriteOverwrite() {
		_testHandleWrite(initialContent: "abc", contentToWrite: "abc", offset: 1, expect: "aabc")
	}

	func testHandleWriteLargeFile() {
		let largeFileContent: String = String(repeating: "Hello ", count: 1_000)
		_testHandleWrite(initialContent: "", contentToWrite: largeFileContent, offset: 0, expect: largeFileContent)
	}

	func _testHandleWrite(initialContent: String, contentToWrite: String, offset: UInt64, expect: String) {
		_testWithTemporaryFile(content: initialContent, openFlags: [.write]) { sftpHandleString, filePath, eventLoop, server in
			// Use handle to write to temporary file
			var lastReplyMessage: SftpMessage? = nil
			let lastReplyPromise: EventLoopPromise<Void> = eventLoop.makePromise()
			lastReplyPromise.succeed(())
			let replyHandler: ReplyHandler = { message in
				lastReplyMessage = message
				return lastReplyPromise.futureResult
			}
			server.register(replyHandler: replyHandler)
			let writePacket: WritePacket = .init(id: 2, handle: sftpHandleString, offset: offset)
			var shouldWrite = false
			let message = SftpMessage(packet: .write(writePacket),
								  dataLength: UInt32(contentToWrite.utf8.count),
								  shouldReadHandler: { should in
									shouldWrite = should
								  })

			let replyFuture = server.handle(message: message, on: eventLoop)

			// Write data to message
			var index = contentToWrite.utf8.startIndex
			while index < contentToWrite.utf8.endIndex {
				if shouldWrite {
					let result = message.sendData(ByteBuffer(bytes: [contentToWrite.utf8[index]]))
					index = contentToWrite.utf8.index(index, offsetBy: 1)
					switch result {
					case let .success(isComplete):
						XCTAssertEqual(isComplete, index == contentToWrite.utf8.endIndex)
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
				return
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
		}
	}

	func testHandleWriteBadHandle() {
		XCTAssertNoThrow(__withServer { eventLoop, server in
			var lastMessage: SftpMessage?
			let replyHandler: ReplyHandler = { message in
				lastMessage = message
				return eventLoop.makeSucceededVoidFuture()
			}
			server.register(replyHandler: replyHandler)
			let packet: Packet = .write(.init(id: 2, handle: "doesn't exist", offset: 0))
			let message = SftpMessage(packet: packet, dataLength: 0, shouldReadHandler: { _ in })
			XCTAssertNoThrow(try server.handle(message: message, on: eventLoop).wait())

			guard let writeReply = lastMessage else {
				XCTFail()
				return
			}

			switch writeReply.packet {
			case let .statusReply(statusPacket):
				XCTAssertEqual(statusPacket.statusCode, .noSuchFile)
			default:
				XCTFail()
			}
		})
	}

//	func testHandleWriteDirectoryFail() {
//		__withServer { eventLoop, server in
//			XCTAssertNoThrow(try withTemporaryDirectory { folderPath in
//				let sftpHandleString = __openFile(filePath: folderPath,
//												  openFlags: [.read],
//												  eventLoop: eventLoop,
//												  server: server)
//
//				var lastMessage: SftpMessage?
//				let replyHandler: ReplyHandler = { message in
//					lastMessage = message
//					return eventLoop.makeSucceededVoidFuture()
//				}
//				server.register(replyHandler: replyHandler)
//				let packet: Packet = .write(.init(id: 2, handle: sftpHandleString, offset: 0))
//				let message = SftpMessage(packet: packet, dataLength: 1, shouldReadHandler: { _ in })
//				let replyFuture = server.handle(message: message, on: eventLoop)
//				_ = message.sendData(ByteBuffer(bytes: [0x97]))
//				message.completeData()
//				XCTAssertNoThrow(try replyFuture.wait())
//
//				guard let writeReply = lastMessage else {
//					XCTFail()
//					return
//				}
//
//				switch writeReply.packet {
//				case let .statusReply(statusPacket):
//					XCTAssertEqual(statusPacket.statusCode, .failure)
//				default:
//					XCTFail()
//				}
//			})
//		}
//	}

	func testHandleRemoveValid() {
		__withServer { eventLoop, server in
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
		__withServer { eventLoop, server in
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
		__withServer { eventLoop, server in
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
		("testRegisterReplyHandler", testRegisterReplyHandler),
		("testHandleNoReplyHandler", testHandleNoReplyHandler),
		("testHandleOpenClose", testHandleOpenClose),
		("testHandleUnknownFile", testHandleUnknownFile),
		("testHandleCloseBadHandle", testHandleCloseBadHandle),
		("testHandleReadSimple", testHandleReadSimple),
		("testHandleReadOffset", testHandleReadOffset),
		("testHandleReadEof", testHandleReadEof),
		("testHandleReadLargeFile", testHandleReadLargeFile),
		("testHandleReadBadHandle", testHandleReadBadHandle),
		("testHandleReadDirectoryFail", testHandleReadDirectoryFail),
		("testHandleWriteSimple", testHandleWriteSimple),
		("testHandleWriteOffset", testHandleWriteOffset),
		("testHandleWriteOverwrite", testHandleWriteOverwrite),
		("testHandleWriteLargeFile", testHandleWriteLargeFile),
		("testHandleWriteBadHandle", testHandleWriteBadHandle),
//		("testHandleWriteDirectoryFail", testHandleWriteDirectoryFail),
	]
}

extension BaseSftpServerTests {
	// Common functions

	func __openFile(filePath: String, openFlags: OpenFlags, eventLoop: EventLoop, server: BaseSftpServer) -> String {
		// Open temporary file
		let openPacket: OpenPacket = .init(
			id: 1,
			filename: filePath,
			pflags: openFlags,
			fileAttributes: .empty)
		var lastReplyMessage: SftpMessage?
		let replyHandler: ReplyHandler = { message in
			lastReplyMessage = message
			return eventLoop.makeSucceededVoidFuture()
		}
		server.register(replyHandler: replyHandler)
		let message = SftpMessage(packet: .open(openPacket), dataLength: 0, shouldReadHandler: { _ in })
		XCTAssertNoThrow(try server.handle(message: message, on: eventLoop).wait())

		// Assert correct reply, extract handle
		guard let openReply = lastReplyMessage else {
			XCTFail()
			return ""
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
			return ""
		}

		return sftpHandleString
	}

	func __closeFile(sftpHandleString: String, eventLoop: EventLoop, server: BaseSftpServer) {
		// Use handle to close temporary file
		var lastReplyMessage: SftpMessage? = nil
		server.register(replyHandler: { message in
			lastReplyMessage = message
			return eventLoop.makeSucceededVoidFuture()
		})
		let closePacket: ClosePacket = .init(id: 2, handle: sftpHandleString)
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
			XCTAssertEqual(statusReply.statusCode, .ok)
		default:
			XCTFail()
		}
	}

	func __withServer(_ body: (EventLoop, BaseSftpServer) throws -> Void) {
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

		XCTAssertNoThrow(try body(eventLoop, server))
	}

	func _testWithTemporaryFile(content: String, openFlags: OpenFlags, _ body: (String, String, EventLoop, BaseSftpServer) throws -> Void) {
		__withServer { eventLoop, server in
			XCTAssertNoThrow(try withTemporaryFile(content: content) { _, filePath in
				// Open the temporary file
				let sftpHandleString = __openFile(filePath: filePath, openFlags: openFlags, eventLoop: eventLoop, server: server)

				XCTAssertNoThrow(try body(sftpHandleString, filePath, eventLoop, server))

				__closeFile(sftpHandleString: sftpHandleString, eventLoop: eventLoop, server: server)
			})
		}
	}
}
