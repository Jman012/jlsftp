import XCTest
import Combine
import NIO
import NIOTestUtils
import Logging
@testable import jlsftp

final class HandleReadLinkTests: XCTestCase {

	func testHandleReadLinkValid() {
		BaseSftpServerTests.__withServer { eventLoop, server in
			XCTAssertNoThrow(try withTemporaryFile(content: "abc") { _, filepath in
				let symlinkName = filepath + "_symlink"
				symlink(filepath, symlinkName)

				var lastMessage: SftpMessage?
				let replyHandler: ReplyHandler = { message in
					lastMessage = message
					return eventLoop.makeSucceededVoidFuture()
				}
				server.register(replyHandler: replyHandler)
				let statusPacket: Packet = .readLink(.init(id: 1, path: symlinkName))
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
					XCTAssertEqual(namePacket.names.first?.filename, filepath)
				default:
					XCTFail()
				}

				unlink(symlinkName)
			})
		}
	}

	static var allTests = [
		("testHandleReadLinkValid", testHandleReadLinkValid),
	]
}
