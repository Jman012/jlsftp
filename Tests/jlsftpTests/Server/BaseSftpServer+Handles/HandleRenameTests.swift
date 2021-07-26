import XCTest
import Combine
import NIO
import NIOTestUtils
import Logging
@testable import jlsftp

final class HandleRenameTests: XCTestCase {

	func testHandleRenameFileValid() {
		BaseSftpServerTests.__withServer { eventLoop, server in
			var content = "abc"
			XCTAssertNoThrow(try withTemporaryFileNoUnlink(content: content) { _, filepath in
				let newFilepath = filepath + ".bak"

				var lastMessage: SftpMessage?
				let replyHandler: ReplyHandler = { message in
					lastMessage = message
					return eventLoop.makeSucceededVoidFuture()
				}
				server.register(replyHandler: replyHandler)
				let renamePacket: Packet = .rename(RenamePacket(id: 1, oldPath: filepath, newPath: newFilepath))
				let renameMessage = SftpMessage(packet: renamePacket, dataLength: 0, shouldReadHandler: { _ in })
				XCTAssertNoThrow(try server.handle(message: renameMessage, on: eventLoop).wait())

				guard let statusReply = lastMessage else {
					XCTFail()
					return
				}

				switch statusReply.packet {
				case let .statusReply(statusPacket):
					XCTAssertEqual(statusPacket.statusCode, .ok)
				default:
					XCTFail()
				}

				// Ensure the file was written correctly
				var fileData: Data?
				XCTAssertNoThrow(fileData = try Data(contentsOf: URL(fileURLWithPath: newFilepath)))
				content.withUTF8 { buffer in
					XCTAssertEqual(Data(buffer: buffer), fileData!)
				}

				XCTAssertEqual(0, unlink(newFilepath))
			})
		}
	}

	func testHandleRenameDirectoryValid() {
		BaseSftpServerTests.__withServer { eventLoop, server in
			XCTAssertNoThrow(try withTemporaryDirectoryNoRemove { filepath in
				let newFilepath = filepath + ".folder"

				var lastMessage: SftpMessage?
				let replyHandler: ReplyHandler = { message in
					lastMessage = message
					return eventLoop.makeSucceededVoidFuture()
				}
				server.register(replyHandler: replyHandler)
				let renamePacket: Packet = .rename(RenamePacket(id: 1, oldPath: filepath, newPath: newFilepath))
				let renameMessage = SftpMessage(packet: renamePacket, dataLength: 0, shouldReadHandler: { _ in })
				XCTAssertNoThrow(try server.handle(message: renameMessage, on: eventLoop).wait())

				guard let statusReply = lastMessage else {
					XCTFail()
					return
				}

				switch statusReply.packet {
				case let .statusReply(statusPacket):
					XCTAssertEqual(statusPacket.statusCode, .ok)
				default:
					XCTFail()
				}

				var statResult: stat = stat()
				withUnsafeMutablePointer(to: &statResult) { statResultPtr in
					XCTAssertEqual(0, stat(newFilepath, statResultPtr))
				}
				XCTAssertEqual(statResult.st_mode & S_IFDIR, S_IFDIR)
				removeTemporaryDirectory(dir: newFilepath)
			})
		}
	}

	func testHandleRenameUnknownOldPath() {
		BaseSftpServerTests.__withServer { eventLoop, server in
			let filepath = "/thisdoesnotexist"
			let newFilepath = filepath + ".bak"

			var lastMessage: SftpMessage?
			let replyHandler: ReplyHandler = { message in
				lastMessage = message
				return eventLoop.makeSucceededVoidFuture()
			}
			server.register(replyHandler: replyHandler)
			let renamePacket: Packet = .rename(RenamePacket(id: 1, oldPath: filepath, newPath: newFilepath))
			let renameMessage = SftpMessage(packet: renamePacket, dataLength: 0, shouldReadHandler: { _ in })
			XCTAssertNoThrow(try server.handle(message: renameMessage, on: eventLoop).wait())

			guard let statusReply = lastMessage else {
				XCTFail()
				return
			}

			switch statusReply.packet {
			case let .statusReply(statusPacket):
				XCTAssertEqual(statusPacket.statusCode, .failure)
			default:
				XCTFail()
			}
		}
	}

	func testHandleRenameInvalidNewPath() {
		BaseSftpServerTests.__withServer { eventLoop, server in
			let content = "abc"
			XCTAssertNoThrow(try withTemporaryFile(content: content) { _, filepath in
				let newFilepath = "blah://nothing"

				var lastMessage: SftpMessage?
				let replyHandler: ReplyHandler = { message in
					lastMessage = message
					return eventLoop.makeSucceededVoidFuture()
				}
				server.register(replyHandler: replyHandler)
				let renamePacket: Packet = .rename(RenamePacket(id: 1, oldPath: filepath, newPath: newFilepath))
				let renameMessage = SftpMessage(packet: renamePacket, dataLength: 0, shouldReadHandler: { _ in })
				XCTAssertNoThrow(try server.handle(message: renameMessage, on: eventLoop).wait())

				guard let statusReply = lastMessage else {
					XCTFail()
					return
				}

				switch statusReply.packet {
				case let .statusReply(statusPacket):
					XCTAssertEqual(statusPacket.statusCode, .failure)
				default:
					XCTFail()
				}
			})
		}
	}

	static var allTests = [
		("testHandleRenameFileValid", testHandleRenameFileValid),
		("testHandleRenameDirectoryValid", testHandleRenameDirectoryValid),
		("testHandleRenameUnknownOldPath", testHandleRenameUnknownOldPath),
		("testHandleRenameInvalidNewPath", testHandleRenameInvalidNewPath),
	]
}
