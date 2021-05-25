import XCTest
import Combine
import NIO
@testable import jlsftp

final class FutureSinkTests: XCTestCase {

	func testValid() {
		let channel = EmbeddedChannel()
		var promises = CircularBuffer<EventLoopPromise<Void>>()
		var receivedValues: [Int] = []

		let passthroughSubj = PassthroughSubject<Int, Never>()
		let futureSink = FutureSink<Int, Never>(maxConcurrent: 3, receiveCompletion: { _ in }, receiveValue: {
			receivedValues.append($0)
			let p = channel.eventLoop.makePromise(of: Void.self)
			promises.append(p)
			return p.futureResult
		})
		passthroughSubj.subscribe(futureSink)

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
		passthroughSubj.send(4)
		XCTAssertEqual(receivedValues, [1, 2, 3])
		XCTAssertEqual(promises.count, 3)
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
