import XCTest
import Combine
import NIO
import NIOTestUtils
import Logging
@testable import jlsftp

final class HandleReadDirectoryTests: XCTestCase {

	enum Expected {
		case eof
		case name(String)
	}

	func _runReadDir(expected: Expected, sftpHandleString: String, eventLoop: EventLoop, server: BaseSftpServer) {
		var lastMessage: SftpMessage?
		let replyHandler: ReplyHandler = { message in
			lastMessage = message
			return eventLoop.makeSucceededVoidFuture()
		}
		server.register(replyHandler: replyHandler)
		let linkStatusPacket: Packet = .readDirectory(.init(id: 2, handle: sftpHandleString))
		let linkStatusMessage = SftpMessage(packet: linkStatusPacket, dataLength: 0, shouldReadHandler: { _ in })
		XCTAssertNoThrow(try server.handle(message: linkStatusMessage, on: eventLoop).wait())

		guard let reply = lastMessage else {
			XCTFail()
			return
		}

		switch (reply.packet, expected) {
		case let (.nameReply(nameReplyPacket), .name(expectedName)):
			XCTAssertEqual(nameReplyPacket.names.count, 1)
			XCTAssertEqual(nameReplyPacket.names.first?.filename, expectedName)
		case let (.statusReply(statusReplyPacket), .eof):
			XCTAssertEqual(statusReplyPacket.statusCode, .endOfFile)
		default:
			XCTFail()
		}
	}

	func testHandleReadDirectoryEmpty() {
		BaseSftpServerTests._testWithTemporaryDirectory { sftpHandleString, _, eventLoop, server in
			_runReadDir(expected: .name("."), sftpHandleString: sftpHandleString, eventLoop: eventLoop, server: server)
			_runReadDir(expected: .name(".."), sftpHandleString: sftpHandleString, eventLoop: eventLoop, server: server)
			_runReadDir(expected: .eof, sftpHandleString: sftpHandleString, eventLoop: eventLoop, server: server)
		}
	}

	func testHandleReadDirectorySingleItem() {
		BaseSftpServerTests._testWithTemporaryDirectory { sftpHandleString, folderPath, eventLoop, server in

			// Insert a file in the directory
			let openFileSftpHandleString = BaseSftpServerTests.__openFile(filePath: folderPath + "/testfile.txt", openFlags: [.create, .read], eventLoop: eventLoop, server: server)

			_runReadDir(expected: .name("."), sftpHandleString: sftpHandleString, eventLoop: eventLoop, server: server)
			_runReadDir(expected: .name(".."), sftpHandleString: sftpHandleString, eventLoop: eventLoop, server: server)
			_runReadDir(expected: .name("testfile.txt"), sftpHandleString: sftpHandleString, eventLoop: eventLoop, server: server)
			_runReadDir(expected: .eof, sftpHandleString: sftpHandleString, eventLoop: eventLoop, server: server)

			BaseSftpServerTests.__closeFile(sftpHandleString: openFileSftpHandleString, eventLoop: eventLoop, server: server)
		}
	}

	static var allTests = [
		("testHandleReadDirectoryEmpty", testHandleReadDirectoryEmpty),
		("testHandleReadDirectorySingleItem", testHandleReadDirectorySingleItem),
	]
}
