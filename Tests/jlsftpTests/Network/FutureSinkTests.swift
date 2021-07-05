import XCTest
import Combine
import NIO
@testable import jlsftp

final class FutureSinkTests: XCTestCase {

	enum TestError: Error {
		case exampleError1
		case exampleError2
	}

	func testValid() {
		// Need a channel for Futures
		let eventLoop = EmbeddedEventLoop()
		// Store received promises/futures in here
		var promises = CircularBuffer<EventLoopPromise<Void>>()
		// Store received values in here
		var receivedValues: [Int] = []

		let passthroughSubj = PassthroughSubject<Int, Never>()
		let futureSink = FutureSink<Int, Never>(maxConcurrent: 3, receiveCompletion: { _, _ in }, receiveValue: {
			// Record the value
			receivedValues.append($0)
			// Make a new promise and track it
			let p: EventLoopPromise<Void> = eventLoop.makePromise()
			promises.append(p)
			return p.futureResult
		})
		passthroughSubj.subscribe(futureSink)

		// First, some standard tracking of received values and promises after
		// sending values.
		XCTAssertEqual(receivedValues, [])
		XCTAssertEqual(promises.count, 0)
		passthroughSubj.send(1)
		XCTAssertEqual(receivedValues, [1])
		XCTAssertEqual(promises.count, 1)
		passthroughSubj.send(2)
		XCTAssertEqual(receivedValues, [1, 2])
		XCTAssertEqual(promises.count, 2)
		passthroughSubj.send(3)
		XCTAssertEqual(receivedValues, [1, 2, 3])
		XCTAssertEqual(promises.count, 3)
		// The sink is full and has no more demand from upstream.
		// Attempting to send a value should fail silently with no changed data.
		passthroughSubj.send(4)
		XCTAssertEqual(receivedValues, [1, 2, 3])
		XCTAssertEqual(promises.count, 3)
		// Next, mark a Future as completed, which should free up some space
		// in the sink. Sending 5 should be tracked now.
		promises.popFirst()!.succeed(())
		XCTAssertEqual(receivedValues, [1, 2, 3])
		XCTAssertEqual(promises.count, 2)
		passthroughSubj.send(5)
		XCTAssertEqual(receivedValues, [1, 2, 3, 5])
		XCTAssertEqual(promises.count, 3)
	}

	func testErrorCancelsClean() {
		// Need an event loop for Futures
		let eventLoop = EmbeddedEventLoop()
		// Store received promises/futures in here
		var promises = CircularBuffer<EventLoopPromise<Void>>()
		// Store received values in here
		var receivedValues: [Int] = []

		let passthroughSubj = PassthroughSubject<Int, Error>()
		var didComplete = false
		let futureSink = FutureSink<Int, Error>(
			maxConcurrent: 3,
			receiveCompletion: { completion, outstandingFutures in
				didComplete = true
				switch completion {
				case .finished:
					break
				default:
					XCTFail()
				}
				XCTAssert(outstandingFutures.isEmpty)
			},
			receiveValue: {
				// Record the value
				receivedValues.append($0)
				// Make a new promise and track it
				let p: EventLoopPromise<Void> = eventLoop.makePromise()
				promises.append(p)
				return p.futureResult
			})
		passthroughSubj.subscribe(futureSink)

		// First, some standard tracking of received values and promises after
		// sending values.
		XCTAssertEqual(receivedValues, [])
		XCTAssertEqual(promises.count, 0)
		passthroughSubj.send(1)
		XCTAssertEqual(receivedValues, [1])
		XCTAssertEqual(promises.count, 1)
		passthroughSubj.send(2)
		XCTAssertEqual(receivedValues, [1, 2])
		XCTAssertEqual(promises.count, 2)

		// Succeed our first promise.
		promises.popFirst()!.succeed(())
		// No new values, first promise was popped.
		XCTAssertEqual(receivedValues, [1, 2])
		XCTAssertEqual(promises.count, 1)

		// Succeed our second promise.
		promises.popFirst()!.succeed(())
		XCTAssertEqual(receivedValues, [1, 2])
		XCTAssertEqual(promises.count, 0)

		// Complete
		passthroughSubj.send(completion: .finished)
		// Completion handler should have been called.
		XCTAssert(didComplete)
		XCTAssertEqual(receivedValues, [1, 2])
		XCTAssertEqual(promises.count, 0)

		// If it was cancelled, no new values should get through.
		passthroughSubj.send(3)
		XCTAssertEqual(receivedValues, [1, 2])
		XCTAssertEqual(promises.count, 0)
	}

	func testErrorCancelsOutstanding() { // TODO: duplicate. one with outstanding, one without.
		// Need an event loop for Futures
		let eventLoop = EmbeddedEventLoop()
		// Store received promises/futures in here
		var promises = CircularBuffer<EventLoopPromise<Void>>()
		// Store received values in here
		var receivedValues: [Int] = []

		let passthroughSubj = PassthroughSubject<Int, Error>()
		var didComplete = false
		let futureSink = FutureSink<Int, Error>(
			maxConcurrent: 3,
			receiveCompletion: { completion, outstandingFutures in
				didComplete = true
				switch completion {
				case .finished:
					XCTFail()
				case .failure(TestError.exampleError2):
					break
				default:
					XCTFail()
				}
				XCTAssertEqual(outstandingFutures.count, 1)
			},
			receiveValue: {
				// Record the value
				receivedValues.append($0)
				// Make a new promise and track it
				let p: EventLoopPromise<Void> = eventLoop.makePromise()
				promises.append(p)
				return p.futureResult
			})
		passthroughSubj.subscribe(futureSink)

		// First, some standard tracking of received values and promises after
		// sending values.
		XCTAssertEqual(receivedValues, [])
		XCTAssertEqual(promises.count, 0)
		passthroughSubj.send(1)
		XCTAssertEqual(receivedValues, [1])
		XCTAssertEqual(promises.count, 1)
		passthroughSubj.send(2)
		XCTAssertEqual(receivedValues, [1, 2])
		XCTAssertEqual(promises.count, 2)

		// Fail our first promise.
		promises.popFirst()!.fail(TestError.exampleError2)
		// Completion handler should have been called.
		XCTAssert(didComplete)
		// No new values, first promise was popped.
		XCTAssertEqual(receivedValues, [1, 2])
		XCTAssertEqual(promises.count, 1)

		// If it was cancelled, no new values should get through.
		passthroughSubj.send(3)
		XCTAssertEqual(receivedValues, [1, 2])
		XCTAssertEqual(promises.count, 1)
	}

	static var allTests = [
		("testValid", testValid),
		("testErrorCancelsClean", testErrorCancelsClean),
		("testErrorCancelsOutstanding", testErrorCancelsOutstanding)
	]
}
