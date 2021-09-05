import XCTest
import Combine
import NIO
import NIOTestUtils
import Logging
@testable import jlsftp

final class HandleReadTests: XCTestCase {

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
		BaseSftpServerTests._testWithTemporaryFile(content: content, openFlags: [.read]) { sftpHandleString, _, eventLoop, server in
			// Use handle to read temporary file
			var lastReplyMessage: SftpMessage?
			let lastReplyPromise: EventLoopPromise<Void> = eventLoop.makePromise()
			var accumulatedBuffer = ByteBuffer()
			var promises: [EventLoopPromise<Void>] = []
			let promiseLock = DispatchSemaphore(value: 1)
			let replyHandler: ReplyHandler = { message in
				lastReplyMessage = message
				message.stream.collect(onComplete: {
//					switch completion {
//					case .finished:
						lastReplyPromise.succeed(())
//					case let .failure(error):
//						lastReplyPromise.fail(error)
//					}
				}, handler: { byteBuffer in
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

			XCTAssertEqual(accumulatedBuffer.getString(at: 0, length: accumulatedBuffer.readableBytes), expect)
		}
	}

	func testHandleReadBadHandle() {
		XCTAssertNoThrow(BaseSftpServerTests.__withServer { eventLoop, server in
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
		BaseSftpServerTests.__withServer { eventLoop, server in
			XCTAssertNoThrow(try withTemporaryDirectory { folderPath in
				let sftpHandleString = BaseSftpServerTests.__openFile(filePath: folderPath,
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

	static var allTests = [
		("testHandleReadSimple", testHandleReadSimple),
		("testHandleReadOffset", testHandleReadOffset),
		("testHandleReadEof", testHandleReadEof),
		("testHandleReadLargeFile", testHandleReadLargeFile),
		("testHandleReadBadHandle", testHandleReadBadHandle),
		("testHandleReadDirectoryFail", testHandleReadDirectoryFail),
	]
}
