import XCTest
import Combine
import NIO
import NIOTestUtils
import Logging
@testable import jlsftp

final class HandleHandleStatusTests: XCTestCase {

	func testHandleHandlestatusValid() {
		BaseSftpServerTests._testWithTemporaryFile(content: "abc", openFlags: [.read]) { sftpHandleString, _, eventLoop, server in
			var lastMessage: SftpMessage?
			let replyHandler: ReplyHandler = { message in
				lastMessage = message
				return eventLoop.makeSucceededVoidFuture()
			}
			server.register(replyHandler: replyHandler)
			let handleStatusPacket: Packet = .handleStatus(.init(id: 1, handle: sftpHandleString))
			let handleStatusMessage = SftpMessage(packet: handleStatusPacket, dataLength: 0, shouldReadHandler: { _ in })
			XCTAssertNoThrow(try server.handle(message: handleStatusMessage, on: eventLoop).wait())

			guard let fileAttrsReply = lastMessage else {
				XCTFail()
				return
			}

			switch fileAttrsReply.packet {
			case let .attributesReply(fileAttrsPacket):
				XCTAssertEqual(fileAttrsPacket.id, 1)
				XCTAssertEqual(fileAttrsPacket.fileAttributes.sizeBytes, 3)
			default:
				XCTFail()
			}
		}
	}

	static var allTests = [
		("testHandleHandlestatusValid", testHandleHandlestatusValid),
	]
}
