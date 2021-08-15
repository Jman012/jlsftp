import XCTest
import Combine
import NIO
import NIOTestUtils
import Logging
@testable import jlsftp

final class HandleLinkStatusTests: XCTestCase {

	func testHandleLinkStatusValid() {
		BaseSftpServerTests.__withServer { eventLoop, server in
			XCTAssertNoThrow(try withTemporaryFile(content: "abc") { _, filepath in
				var lastMessage: SftpMessage?
				let replyHandler: ReplyHandler = { message in
					lastMessage = message
					return eventLoop.makeSucceededVoidFuture()
				}
				server.register(replyHandler: replyHandler)
				let linkStatusPacket: Packet = .linkStatus(.init(id: 1, path: filepath))
				let linkStatusMessage = SftpMessage(packet: linkStatusPacket, dataLength: 0, shouldReadHandler: { _ in })
				XCTAssertNoThrow(try server.handle(message: linkStatusMessage, on: eventLoop).wait())

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
		("testHandleLinkStatusValid", testHandleLinkStatusValid),
	]
}
