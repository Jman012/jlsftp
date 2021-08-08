import XCTest
import Combine
import NIO
import NIOTestUtils
import Logging
@testable import jlsftp

final class HandleWriteTests: XCTestCase {

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
		let largeFileContent: String = String(repeating: "Hello ", count: 1000)
		_testHandleWrite(initialContent: "", contentToWrite: largeFileContent, offset: 0, expect: largeFileContent)
	}

	func _testHandleWrite(initialContent: String, contentToWrite: String, offset: UInt64, expect: String) {
		BaseSftpServerTests._testWithTemporaryFile(content: initialContent, openFlags: [.write]) { sftpHandleString, filePath, eventLoop, server in
			// Use handle to write to temporary file
			var lastReplyMessage: SftpMessage?
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
		XCTAssertNoThrow(BaseSftpServerTests.__withServer { eventLoop, server in
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

	static var allTests = [
		("testHandleWriteSimple", testHandleWriteSimple),
		("testHandleWriteOffset", testHandleWriteOffset),
		("testHandleWriteOverwrite", testHandleWriteOverwrite),
		("testHandleWriteLargeFile", testHandleWriteLargeFile),
		("testHandleWriteBadHandle", testHandleWriteBadHandle),
//		("testHandleWriteDirectoryFail", testHandleWriteDirectoryFail),
	]
}
