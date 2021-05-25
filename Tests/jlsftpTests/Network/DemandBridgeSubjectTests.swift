import XCTest
import Combine
import NIO
@testable import jlsftp

final class DemandBridgeSubjectTests: XCTestCase {

	func testValid() {
		var canSendValues: [Bool] = []
		let demandBridgeSubj = DemandBridgeSubject<Int, Never>(handler: { shouldSend in
			canSendValues.append(shouldSend)
		})

		XCTAssertEqual(canSendValues, [])

		var receivedValues: [Int] = []
		let sink = CustomDemandSink<Int, Never>(demand: 2, receiveCompletion: { _ in }, receiveValue: { input in
			receivedValues.append(input)
		})
		demandBridgeSubj.subscribe(sink)

		XCTAssertEqual(canSendValues, [true])
		XCTAssertEqual(receivedValues, [])
		demandBridgeSubj.send(1)
		XCTAssertEqual(canSendValues, [true])
		XCTAssertEqual(receivedValues, [1])
		demandBridgeSubj.send(2)
		XCTAssertEqual(canSendValues, [true, false])
		XCTAssertEqual(receivedValues, [1, 2])
		sink.increaseDemand(1)
		XCTAssertEqual(canSendValues, [true, false, true])
		XCTAssertEqual(receivedValues, [1, 2])
		demandBridgeSubj.send(3)
		XCTAssertEqual(canSendValues, [true, false, true, false])
		XCTAssertEqual(receivedValues, [1, 2, 3])
	}

	static var allTests = [
		("testValid", testValid),
	]
}
