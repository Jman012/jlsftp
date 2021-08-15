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
		let message = SftpMessage(packet: .close(.init(id: 1, handle: "a")), dataLength: 0, shouldReadHandler: { _ in })
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

	static var allTests = [
		("testRegisterReplyHandler", testRegisterReplyHandler),
		("testHandleNoReplyHandler", testHandleNoReplyHandler),
	]
}

// Common functions
extension BaseSftpServerTests {

	static func __openFile(filePath: String, openFlags: OpenFlags, eventLoop: EventLoop, server: BaseSftpServer) -> String {
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
		XCTAssert(sftpHandleString.count > 0)

		return sftpHandleString
	}

	static func __closeFile(sftpHandleString: String, eventLoop: EventLoop, server: BaseSftpServer) {
		// Use handle to close temporary file
		var lastReplyMessage: SftpMessage?
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

	static func __openDirectory(folderPath: String, eventLoop: EventLoop, server: BaseSftpServer) -> String {
		// Open temporary file
		let openDirPacket: OpenDirectoryPacket = .init(id: 1, path: folderPath)
		var lastReplyMessage: SftpMessage?
		let replyHandler: ReplyHandler = { message in
			lastReplyMessage = message
			return eventLoop.makeSucceededVoidFuture()
		}
		server.register(replyHandler: replyHandler)
		let message = SftpMessage(packet: .openDirectory(openDirPacket), dataLength: 0, shouldReadHandler: { _ in })
		XCTAssertNoThrow(try server.handle(message: message, on: eventLoop).wait())

		// Assert correct reply, extract handle
		guard let openDirReply = lastReplyMessage else {
			XCTFail()
			return ""
		}
		var sftpHandle: String?
		switch openDirReply.packet {
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
		XCTAssert(sftpHandleString.count > 0)

		return sftpHandleString
	}


	static func __withServer(_ body: (EventLoop, BaseSftpServer) throws -> Void) {
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

	static func _testWithTemporaryFile(content: String, openFlags: OpenFlags, _ body: (String, String, EventLoop, BaseSftpServer) throws -> Void) {
		__withServer { eventLoop, server in
			XCTAssertNoThrow(try withTemporaryFile(content: content) { _, filePath in
				// Open the temporary file
				let sftpHandleString = __openFile(filePath: filePath, openFlags: openFlags, eventLoop: eventLoop, server: server)

				XCTAssertNoThrow(try body(sftpHandleString, filePath, eventLoop, server))

				__closeFile(sftpHandleString: sftpHandleString, eventLoop: eventLoop, server: server)
			})
		}
	}

	static func _testWithTemporaryDirectory(_ body: (String, String, EventLoop, BaseSftpServer) throws -> Void) {
		__withServer { eventLoop, server in
			XCTAssertNoThrow(try withTemporaryDirectory { folderPath in
				// Open the temporary folder
				let sftpHandleString = __openDirectory(folderPath: folderPath, eventLoop: eventLoop, server: server)

				XCTAssertNoThrow(try body(sftpHandleString, folderPath, eventLoop, server))

				__closeFile(sftpHandleString: sftpHandleString, eventLoop: eventLoop, server: server)
			})
		}
	}
}
