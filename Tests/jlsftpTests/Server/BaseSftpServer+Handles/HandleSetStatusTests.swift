import XCTest
import Combine
import NIO
import NIOTestUtils
import Logging
@testable import jlsftp

final class HandleSetStatusTests: XCTestCase {

	func testHandleSetStatusValid() {
		BaseSftpServerTests.__withServer { eventLoop, server in
			XCTAssertNoThrow(try withTemporaryFile(content: "abc") { _, filepath in
				var statResult: stat = .init()
				stat(filepath, &statResult)

				var lastMessage: SftpMessage?
				let replyHandler: ReplyHandler = { message in
					lastMessage = message
					return eventLoop.makeSucceededVoidFuture()
				}
				server.register(replyHandler: replyHandler)

				let fileAttrs = FileAttributes(sizeBytes: nil,
											   userId: statResult.st_uid,
											   groupId: statResult.st_gid,
											   permissions: Permissions(user: [.read, .write, .execute], group: [.read, .write, .execute], other: [.read, .write, .execute], mode: [], fileType: nil),
											   accessDate: Date(timeIntervalSince1970: 1),
											   modifyDate: Date(timeIntervalSince1970: 2),
											   linkCount: nil,
											   extensionData: [])
				let fileAttrsPacket: Packet = .setStatus(.init(id: 1, path: filepath, fileAttributes: fileAttrs))
				let fileAttrsMessage = SftpMessage(packet: fileAttrsPacket, dataLength: 0, shouldReadHandler: { _ in })
				XCTAssertNoThrow(try server.handle(message: fileAttrsMessage, on: eventLoop).wait())

				guard let statusReply = lastMessage else {
					XCTFail()
					return
				}

				switch statusReply.packet {
				case let .statusReply(statusPacket):
					XCTAssertEqual(statusPacket.id, 1)
					XCTAssertEqual(statusPacket.statusCode, .ok)
				default:
					XCTFail()
				}
			})
		}
	}

	static var allTests = [
		("testHandleSetStatusValid", testHandleSetStatusValid),
	]
}
