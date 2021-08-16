import XCTest
import Combine
import NIO
import NIOTestUtils
import Logging
@testable import jlsftp

final class HandleRealPathTests: XCTestCase {

	func testHandleRealPathValid() {
		BaseSftpServerTests.__withServer { eventLoop, server in
			XCTAssertNoThrow(try withTemporaryFile(content: "abc") { _, filepath in
				var lastMessage: SftpMessage?
				let replyHandler: ReplyHandler = { message in
					lastMessage = message
					return eventLoop.makeSucceededVoidFuture()
				}
				server.register(replyHandler: replyHandler)
				let statusPacket: Packet = .realPath(.init(id: 1, path: filepath))
				let statusMessage = SftpMessage(packet: statusPacket, dataLength: 0, shouldReadHandler: { _ in })
				XCTAssertNoThrow(try server.handle(message: statusMessage, on: eventLoop).wait())

				guard let nameReply = lastMessage else {
					XCTFail()
					return
				}

				switch nameReply.packet {
				case let .nameReply(namePacket):
					XCTAssertEqual(namePacket.id, 1)
					XCTAssertEqual(namePacket.names.count, 1)
					XCTAssert(namePacket.names.first?.filename.count ?? 1 > 0)
				default:
					XCTFail()
				}
			})
		}
	}

	static var allTests = [
		("testHandleRealPathValid", testHandleRealPathValid),
	]
}
