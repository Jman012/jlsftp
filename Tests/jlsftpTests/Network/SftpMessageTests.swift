import XCTest
import Combine
import NIO
@testable import jlsftp

final class SftpMessageTests: XCTestCase {

	func testValidInit() {
		let eventLoop = EmbeddedEventLoop()
		var shouldRead = false
		let message = SftpMessage(
			packet: .initializeV4(InitializePacketV4(version: .v6)),
			dataLength: 4,
			shouldReadHandler: { read in shouldRead = read })

		XCTAssertEqual(message.packet, .initializeV4(InitializePacketV4(version: .v6)))
		XCTAssertEqual(shouldRead, false)
		message.stream.collect(onComplete: { }, handler: { _ in eventLoop.makeSucceededVoidFuture() })
		XCTAssertEqual(shouldRead, true)
	}

	func testSendData() {
		let eventLoop = EmbeddedEventLoop()
		let message = SftpMessage(
			packet: .write(.init(id: 1, handle: "", offset: 0)),
			dataLength: 5,
			shouldReadHandler: { _ in })
		var bufferHistory: [[UInt8]] = []

		message.stream.collect(onComplete: { }, handler: {
			bufferHistory.append($0.getBytes(at: 0, length: $0.readableBytes)!)
			return eventLoop.makeSucceededVoidFuture()
		})
		XCTAssertEqual(bufferHistory, [])

		var result = message.sendData(ByteBuffer(bytes: [0x01]))
		XCTAssertEqual(result, .success(false))
		XCTAssertEqual(bufferHistory, [[0x01]])

		result = message.sendData(ByteBuffer(bytes: [0x02, 0x03]))
		XCTAssertEqual(result, .success(false))
		XCTAssertEqual(bufferHistory, [[0x01], [0x02, 0x03]])

		result = message.sendData(ByteBuffer(bytes: [0x04, 0x05]))
		XCTAssertEqual(result, .success(true))
		XCTAssertEqual(bufferHistory, [[0x01], [0x02, 0x03], [0x04, 0x05]])

		result = message.sendData(ByteBuffer(bytes: [0x06]))
		XCTAssertEqual(result, .failure(.tooMuchData("Unexpected error: Too many bytes encountered in body of sftp packet")))
		XCTAssertEqual(bufferHistory, [[0x01], [0x02, 0x03], [0x04, 0x05]])
	}

	func testComplete() {
		let eventLoop = EmbeddedEventLoop()
		let message = SftpMessage(
			packet: .write(.init(id: 1, handle: "", offset: 0)),
			dataLength: 5,
			shouldReadHandler: { _ in })
		var didComplete = false

		message.stream.collect(onComplete: {
			didComplete = true
		}, handler: { _ in
			return eventLoop.makeSucceededVoidFuture()
		})
		XCTAssertEqual(didComplete, false)

		message.completeData()
		XCTAssertEqual(didComplete, true)
	}

	static var allTests = [
		("testValidInit", testValidInit),
		("testSendData", testSendData),
		("testComplete", testComplete),
	]
}
