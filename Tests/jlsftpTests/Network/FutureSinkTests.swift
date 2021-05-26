import XCTest
import Combine
import NIO
@testable import jlsftp

final class FutureSinkTests: XCTestCase {

	func testValid() {
		// Need a channel for Futures
		let channel = EmbeddedChannel()
		// Store received promises/futures in here
		var promises = CircularBuffer<EventLoopPromise<Void>>()
		// Store received values in here
		var receivedValues: [Int] = []

		let passthroughSubj = PassthroughSubject<Int, Never>()
		let futureSink = FutureSink<Int, Never>(maxConcurrent: 3, receiveCompletion: { _ in }, receiveValue: {
			// Record the value
			receivedValues.append($0)
			// Make a new promise and track it
			let p = channel.eventLoop.makePromise(of: Void.self)
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

	static var allTests = [
		("testValid", testValid),
	]
}
