import XCTest
import Combine
import NIO
import Logging
@testable import jlsftp

final class SftpMessageStreamTests: XCTestCase {

	let noopLogger = Logger(label: "test", factory: { _ in SwiftLogNoOpLogHandler() })

	func testSendDataAwaiting() {
		let stream = SftpMessageStream(outstandingFutureLimit: 5,
									   onBackpressure: { _ in },
									   logger: noopLogger)
		XCTAssertEqual(stream.queuedData, [])

		stream.send(buffer: ByteBuffer(bytes: [0x01]))
		XCTAssertEqual(stream.queuedData, [ByteBuffer(bytes: [0x01])])
	}

	func testCollectQueued() {
		let eventLoop = EmbeddedEventLoop()
		let stream = SftpMessageStream(outstandingFutureLimit: 5,
									   onBackpressure: { _ in },
									   logger: noopLogger)
		var collectHistory: [ByteBuffer] = []

		stream.send(buffer: ByteBuffer(bytes: [0x01]))
		stream.send(buffer: ByteBuffer(bytes: [0x02]))
		XCTAssertEqual(stream.queuedData, [ByteBuffer(bytes: [0x01]), ByteBuffer(bytes: [0x02])])
		stream.collect(onComplete: { }, handler: { buffer in
			collectHistory.append(buffer)
			return eventLoop.makeSucceededVoidFuture()
		})

		XCTAssertEqual(collectHistory, [ByteBuffer(bytes: [0x01]), ByteBuffer(bytes: [0x02])])
		XCTAssertEqual(stream.queuedData, [])
	}

	func testSendWhileCollecting() {
		let eventLoop = EmbeddedEventLoop()
		let stream = SftpMessageStream(outstandingFutureLimit: 5,
									   onBackpressure: { _ in },
									   logger: noopLogger)
		var collectHistory: [ByteBuffer] = []

		stream.collect(onComplete: { }, handler: { buffer in
			collectHistory.append(buffer)
			return eventLoop.makeSucceededVoidFuture()
		})
		XCTAssertEqual(collectHistory, [])

		stream.send(buffer: ByteBuffer(bytes: [0x01]))
		XCTAssertEqual(collectHistory, [ByteBuffer(bytes: [0x01])])

		stream.send(buffer: ByteBuffer(bytes: [0x02]))
		XCTAssertEqual(collectHistory, [ByteBuffer(bytes: [0x01]), ByteBuffer(bytes: [0x02])])
	}

	func testQueueSendWhileFuturesFull() {
		let eventLoop = EmbeddedEventLoop()
		let stream = SftpMessageStream(outstandingFutureLimit: 1,
									   onBackpressure: { _ in },
									   logger: noopLogger)
		var collectHistory: [ByteBuffer] = []

		stream.collect(onComplete: { }, handler: { buffer in
			collectHistory.append(buffer)
			return eventLoop.makePromise().futureResult
		})
		XCTAssertEqual(collectHistory, [])

		stream.send(buffer: ByteBuffer(bytes: [0x01]))
		XCTAssertEqual(collectHistory, [ByteBuffer(bytes: [0x01])])
		XCTAssertEqual(stream.outstandingFutures.count, 1)
		XCTAssertEqual(stream.queuedData, [])

		stream.send(buffer: ByteBuffer(bytes: [0x02]))
		XCTAssertEqual(collectHistory, [ByteBuffer(bytes: [0x01])])
		XCTAssertEqual(stream.outstandingFutures.count, 1)
		XCTAssertEqual(stream.queuedData, [ByteBuffer(bytes: [0x02])])
	}

	func testBackpressure() {
		let eventLoop = EmbeddedEventLoop()
		var backpressure = false
		let stream = SftpMessageStream(outstandingFutureLimit: 2,
									   onBackpressure: { backpressure = $0 },
									   logger: noopLogger)
		XCTAssertEqual(backpressure, false)

		stream.collect(onComplete: { }, handler: { _ in eventLoop.makePromise().futureResult })
		XCTAssertEqual(backpressure, true)

		// 1 of 2 outstanding futures, empty queue
		stream.send(buffer: ByteBuffer(bytes: [0x01]))
		XCTAssertEqual(backpressure, true)

		// 2 of 2 outstanding futures, empty queue
		stream.send(buffer: ByteBuffer(bytes: [0x02]))
		XCTAssertEqual(backpressure, false)

		// 2 of 2 outstanding futures, items in queue
		stream.send(buffer: ByteBuffer(bytes: [0x03]))
		XCTAssertEqual(backpressure, false)
	}

	func testCompleteBeforeCollect() {
		let eventLoop = EmbeddedEventLoop()
		let stream = SftpMessageStream(outstandingFutureLimit: 1,
									   onBackpressure: { _ in },
									   logger: noopLogger)
		var isComplete = false

		stream.complete()
		XCTAssertEqual(isComplete, false)

		stream.collect(onComplete: { isComplete = true }, handler: { _ in eventLoop.makeSucceededVoidFuture() })
		XCTAssertEqual(isComplete, true)
	}

	func testCompleteAfterCollect() {
		let eventLoop = EmbeddedEventLoop()
		let stream = SftpMessageStream(outstandingFutureLimit: 1,
									   onBackpressure: { _ in },
									   logger: noopLogger)
		var isComplete = false

		stream.collect(onComplete: { isComplete = true }, handler: { _ in eventLoop.makeSucceededVoidFuture() })
		XCTAssertEqual(isComplete, false)

		stream.complete()
		XCTAssertEqual(isComplete, true)
	}

	static var allTests = [
		("testSendDataAwaiting", testSendDataAwaiting),
		("testCollectQueued", testCollectQueued),
		("testSendWhileCollecting", testSendWhileCollecting),
		("testQueueSendWhileFuturesFull", testQueueSendWhileFuturesFull),
		("testBackpressure", testBackpressure),
		("testCompleteBeforeCollect", testCompleteBeforeCollect),
		("testCompleteAfterCollect", testCompleteAfterCollect),
	]
}
