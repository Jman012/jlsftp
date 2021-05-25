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

		XCTAssertEqual(receivedValues, [])
		subj.send(1)
		XCTAssertEqual(receivedValues, [1])
		subj.send(2)
		XCTAssertEqual(receivedValues, [1, 2])
		subj.send(3)
		XCTAssertEqual(receivedValues, [1, 2])
		sink.increaseDemand(1)
		XCTAssertEqual(receivedValues, [1, 2, 3])
		subj.send(4)
		subj.send(5)
		subj.send(6)
		XCTAssertEqual(receivedValues, [1, 2, 3])
		sink.increaseDemand(3)
		XCTAssertEqual(receivedValues, [1, 2, 3, 4, 5, 6])
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
