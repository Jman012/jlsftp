import XCTest
import Combine
import NIO
@testable import jlsftp

final class SftpMessageTests: XCTestCase {

	func testValidInit() {
		var shouldRead = false
		let message = SftpMessage(
			packet: .initializeV4(InitializePacketV4(version: .v6)),
			dataLength: 4,
			shouldReadHandler: { read in shouldRead = read })

		XCTAssertEqual(message.packet, .initializeV4(InitializePacketV4(version: .v6)))
		XCTAssertEqual(shouldRead, false)
		_ = message.data.sink(receiveValue: { _ in })
		XCTAssertEqual(shouldRead, true)
	}

	func testValid() {
		var shouldReadHistory: [Bool] = []
		var sinkHistory: [[UInt8]] = []
		var customSink: CustomDemandSink<ByteBuffer, Never>!
		withExtendedLifetime(SftpMessage(
			packet: .initializeV3(.init(version: .v3, extensionData: [])),
			dataLength: 20,
			shouldReadHandler: { read in shouldReadHistory.append(read) })) { message in
			// No change yet
			XCTAssertEqual(shouldReadHistory, [])
			XCTAssertEqual(sinkHistory, [])

			// Attach the sink to the message.
			customSink = CustomDemandSink<ByteBuffer, Never>(
				demand: 2,
				receiveCompletion: { _ in },
				receiveValue: { sinkHistory.append($0.getBytes(at: 0, length: $0.readableBytes)!) })
			message.data.subscribe(customSink)

			// This should trigger the read, now that the demand has been established
			// from the sink. The buffered data operator doesn't initiate demand until then.
			XCTAssertEqual(shouldReadHistory, [true])
			XCTAssertEqual(sinkHistory, [])

			// Send byte 1 of 20. Should fall through to sink.
			var result = message.sendData(ByteBuffer(bytes: [0x01]))
			XCTAssertEqual(result, .success(false))
			XCTAssertEqual(shouldReadHistory, [true])
			XCTAssertEqual(sinkHistory, [[0x01]])

			// Send byte 2 of 20. Should fall through to sink.
			result = message.sendData(ByteBuffer(bytes: [0x02]))
			XCTAssertEqual(result, .success(false))
			XCTAssertEqual(shouldReadHistory, [true])
			XCTAssertEqual(sinkHistory, [[0x01], [0x02]])

			// Now, sink is full. Next bytes should be buffered.
			result = message.sendData(ByteBuffer(bytes: [0x03]))
			XCTAssertEqual(result, .success(false))
			XCTAssertEqual(shouldReadHistory, [true])
			XCTAssertEqual(sinkHistory, [[0x01], [0x02]])

			// Fill buffer to full
			result = message.sendData(ByteBuffer(bytes: [0x04]))
			result = message.sendData(ByteBuffer(bytes: [0x05]))
			result = message.sendData(ByteBuffer(bytes: [0x06]))
			result = message.sendData(ByteBuffer(bytes: [0x07]))
			result = message.sendData(ByteBuffer(bytes: [0x08]))
			result = message.sendData(ByteBuffer(bytes: [0x09]))
			result = message.sendData(ByteBuffer(bytes: [0x0A]))
			result = message.sendData(ByteBuffer(bytes: [0x0B]))
			XCTAssertEqual(result, .success(false))
			XCTAssertEqual(shouldReadHistory, [true])
			XCTAssertEqual(sinkHistory, [[0x01], [0x02]])
			result = message.sendData(ByteBuffer(bytes: [0x0C]))
			XCTAssertEqual(result, .success(false))
			XCTAssertEqual(shouldReadHistory, [true, false])
			XCTAssertEqual(sinkHistory, [[0x01], [0x02]])

			// Increase demand, and expect to get all results immediately
			customSink.increaseDemand(10)
			XCTAssertEqual(result, .success(false))
			XCTAssertEqual(shouldReadHistory, [true, false, true])
			XCTAssertEqual(sinkHistory, [[0x01], [0x02], [0x03], [0x04], [0x05], [0x06], [0x07], [0x08], [0x09], [0x0A], [0x0B], [0x0C]])

			// Finish
			result = message.sendData(ByteBuffer(bytes: [0x0D, 0x0E, 0x0F, 0x10, 0x11, 0x12, 0x13, 0x14]))
			XCTAssertEqual(result, .success(true))
			XCTAssertEqual(shouldReadHistory, [true, false, true])
			XCTAssertEqual(sinkHistory, [[0x01], [0x02], [0x03], [0x04], [0x05], [0x06], [0x07], [0x08], [0x09], [0x0A], [0x0B], [0x0C]])
			message.completeData()
		}

		customSink.increaseDemand(1)
		XCTAssertEqual(sinkHistory, [[0x01], [0x02], [0x03], [0x04], [0x05], [0x06], [0x07], [0x08], [0x09], [0x0A], [0x0B], [0x0C], [0x0D, 0x0E, 0x0F, 0x10, 0x11, 0x12, 0x13, 0x14]])
	}

	func testInvalidTooManyBytes() {
		var shouldRead = false
		let message = SftpMessage(
			packet: .initializeV4(InitializePacketV4(version: .v6)),
			dataLength: 4,
			shouldReadHandler: { read in shouldRead = read })

		XCTAssertEqual(message.packet, .initializeV4(InitializePacketV4(version: .v6)))
		XCTAssertEqual(shouldRead, false)

		var sinkHistory: [[UInt8]] = []
		let customSink = CustomDemandSink<ByteBuffer, Never>(
			demand: 2,
			receiveCompletion: { _ in },
			receiveValue: { sinkHistory.append($0.getBytes(at: 0, length: $0.readableBytes)!) })
		message.data.subscribe(customSink)

		XCTAssertEqual(shouldRead, true)

		let result = message.sendData(ByteBuffer(bytes: [0x00, 0x01, 0x02, 0x03, 0x04]))
		switch result {
		case .failure(.tooMuchData(_)):
			break
		default:
			XCTFail()
		}
		XCTAssertEqual(sinkHistory, [])
	}

	static var allTests = [
		("testValidInit", testValidInit),
	]
}
