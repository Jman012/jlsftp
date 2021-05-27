import XCTest
import Combine
import NIO
@testable import jlsftp

final class BufferedDataPublisherTests: XCTestCase {

	func testValid() {
		var receivedValues: [Int] = []
		let subj = PassthroughSubject<Int, Never>()
		let sink = CustomDemandSink<Int, Never>(demand: 2, receiveCompletion: { _ in }, receiveValue: { receivedValues.append($0) })
		subj.bufferedData(bufferSize: 3).subscribe(sink)

		// Pass values through normally, without buffer
		XCTAssertEqual(receivedValues, [])
		subj.send(1)
		XCTAssertEqual(receivedValues, [1])
		subj.send(2)
		XCTAssertEqual(receivedValues, [1, 2])
		// Buffer is full. Send a value through that is buffered.
		subj.send(3)
		XCTAssertEqual(receivedValues, [1, 2])
		// Increase demand to empty buffer.
		sink.increaseDemand(1)
		XCTAssertEqual(receivedValues, [1, 2, 3])
		// Buffer extra data.
		subj.send(4)
		subj.send(5)
		subj.send(6)
		XCTAssertEqual(receivedValues, [1, 2, 3])
		// Increase demand to empty buffer.
		sink.increaseDemand(3)
		XCTAssertEqual(receivedValues, [1, 2, 3, 4, 5, 6])
		// Ensure completion stops sending values.
		subj.send(completion: .finished)
		subj.send(7)
		XCTAssertEqual(receivedValues, [1, 2, 3, 4, 5, 6])
		sink.increaseDemand(1)
		XCTAssertEqual(receivedValues, [1, 2, 3, 4, 5, 6])
	}

	static var allTests = [
		("testValid", testValid),
	]
}
