import XCTest
import Combine
import NIO
@testable import jlsftp

final class SftpServerChannelHandlerTests: XCTestCase {

	func testChannelReadValid() {
		let channel = EmbeddedChannel()
		var lastMessage: SftpMessage?
		let server = CustomSftpServer(handleMessageHandler: { message in
			lastMessage = message
			return channel.eventLoop.makePromise(of: Void.self).futureResult
		})
		let handler = SftpServerChannelHandler(server: server)
		XCTAssertNoThrow(try channel.pipeline.addHandler(handler).wait())

		let packet: Packet = .status(.init(id: 1, path: "a"))
		let message = SftpMessage(packet: packet, dataLength: 0, shouldReadHandler: { _ in })
		XCTAssertNoThrow(try channel.writeInbound(message))

		XCTAssertEqual(lastMessage?.packet, packet)
	}

	func testChannelSecondReadValid() {
		let channel = EmbeddedChannel()
		var lastMessage: SftpMessage?
		let promise = channel.eventLoop.makePromise(of: Void.self)
		let server = CustomSftpServer(handleMessageHandler: { message in
			lastMessage = message
			return promise.futureResult
		})
		let handler = SftpServerChannelHandler(server: server)
		XCTAssertNoThrow(try channel.pipeline.addHandler(handler).wait())

		var packet: Packet = .status(.init(id: 1, path: "a"))
		var message = SftpMessage(packet: packet, dataLength: 0, shouldReadHandler: { _ in })
		XCTAssertNoThrow(try channel.writeInbound(message))

		XCTAssertEqual(lastMessage?.packet, packet)
		promise.succeed(())

		packet = .linkStatus(.init(id: 2, path: "b"))
		message = SftpMessage(packet: packet, dataLength: 0, shouldReadHandler: { _ in })
		XCTAssertNoThrow(try channel.writeInbound(message))
	}

	func testChannelSecondReadInvalid() {
		let channel = EmbeddedChannel()
		var lastMessage: SftpMessage?
		let server = CustomSftpServer(handleMessageHandler: { message in
			lastMessage = message
			return channel.eventLoop.makePromise(of: Void.self).futureResult
		})
		let handler = SftpServerChannelHandler(server: server)
		XCTAssertNoThrow(try channel.pipeline.addHandler(handler).wait())

		var packet: Packet = .status(.init(id: 1, path: "a"))
		var message = SftpMessage(packet: packet, dataLength: 0, shouldReadHandler: { _ in })
		XCTAssertNoThrow(try channel.writeInbound(message))

		XCTAssertEqual(lastMessage?.packet, packet)

		packet = .linkStatus(.init(id: 2, path: "b"))
		message = SftpMessage(packet: packet, dataLength: 0, shouldReadHandler: { _ in })
		XCTAssertThrowsError(try channel.writeInbound(message)) { error in
			switch error as? SftpServerChannelHandler.ChannelError {
			case .some(.unexpectedInboundMessage):
				break
			case .none:
				XCTFail()
			}
		}
	}

	func testReadFires() {
		let channel = EmbeddedChannel()
		let promise = channel.eventLoop.makePromise(of: Void.self)
		let server = CustomSftpServer(handleMessageHandler: { message in
			return promise.futureResult
		})
		let readEventHitHandler = ReadEventHitHandler()
		let handler = SftpServerChannelHandler(server: server)
		XCTAssertNoThrow(try channel.pipeline.addHandlers([readEventHitHandler, handler]).wait())
		XCTAssertEqual(readEventHitHandler.readHitCounter, 0)

		channel.read()
		XCTAssertEqual(readEventHitHandler.readHitCounter, 1)

		let packet: Packet = .status(.init(id: 1, path: "a"))
		let message = SftpMessage(packet: packet, dataLength: 0, shouldReadHandler: { _ in })
		XCTAssertNoThrow(try channel.writeInbound(message))
		channel.read()
		XCTAssertEqual(readEventHitHandler.readHitCounter, 1)

		promise.succeed(())
		channel.read()
		XCTAssertEqual(readEventHitHandler.readHitCounter, 2)
	}

	func testReply() {
		let channel = EmbeddedChannel()
		let server = CustomSftpServer()
		let handler = SftpServerChannelHandler(server: server)
		XCTAssertNoThrow(try channel.pipeline.addHandler(handler).wait())
		XCTAssertNoThrow(try channel.register().wait())

		let packet: Packet = .status(.init(id: 1, path: "a"))
		let message = SftpMessage(packet: packet, dataLength: 0, shouldReadHandler: { _ in })

		let replyFuture = channel.writeAndFlush(message)
		XCTAssertNoThrow(try replyFuture.wait())
		let replyMessage = try? channel.readOutbound(as: SftpMessage.self)
		XCTAssertEqual(replyMessage?.packet, packet)
	}

	static let allTests = [
		("testChannelReadValid", testChannelReadValid),
		("testChannelSecondReadValid", testChannelSecondReadValid),
		("testChannelSecondReadInvalid", testChannelSecondReadInvalid),
		("testReadFires", testReadFires),
		("testReply", testReply),
	]
}
