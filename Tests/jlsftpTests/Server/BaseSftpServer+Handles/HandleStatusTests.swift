import XCTest
import Combine
import NIO
import NIOTestUtils
import Logging
@testable import jlsftp

final class HandleStatusTests: XCTestCase {

	func testHandleStatusValid() {
		BaseSftpServerTests.__withServer { eventLoop, server in
			XCTAssertNoThrow(try withTemporaryFile(content: "abc") { _, filepath in
				var lastMessage: SftpMessage?
				let replyHandler: ReplyHandler = { message in
					lastMessage = message
					return eventLoop.makeSucceededVoidFuture()
				}
				server.register(replyHandler: replyHandler)
				let statusPacket: Packet = .status(.init(id: 1, path: filepath))
				let statusMessage = SftpMessage(packet: statusPacket, dataLength: 0, shouldReadHandler: { _ in })
				XCTAssertNoThrow(try server.handle(message: statusMessage, on: eventLoop).wait())

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
			})
		}
	}

	static var allTests = [
		("testHandleStatusValid", testHandleStatusValid),
	]
}
