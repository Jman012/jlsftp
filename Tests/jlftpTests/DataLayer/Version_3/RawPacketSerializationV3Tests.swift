import XCTest
@testable import jlftp

final class RawPacketSerializationV3Tests: XCTestCase {

	private func getSerialization() -> jlftp.DataLayer.Version_3.RawPacketSerializationV3 {
		return jlftp.DataLayer.Version_3.RawPacketSerializationV3(sshProtocolSerialization: SSHProtocolSerializationDraft9())
	}

	func testDeserializeNoData() {
		let data = Data([])

		let result = getSerialization().deserialize(from: data)

		XCTAssertEqual(.failure(.noData), result)
	}

	func testDeserializeNoLength() {
		// Any packet that is not 4 bytes (length) or more is empty.
		let testcases = [
			Data([0x00]),
			Data([0x00, 0x00]),
			Data([0x00, 0x00, 0x00]),
		]

		for testcaseData in testcases {
			let result = getSerialization().deserialize(from: testcaseData)

			XCTAssertEqual(.failure(.noLength), result)
		}
	}

	func testDeserializeNoType() {
		let data = Data([
			// Length (0)
			0x00, 0x00, 0x00, 0x00,
			// Type (nothing)
		])

		let result = getSerialization().deserialize(from: data)

		XCTAssertEqual(.failure(.noType), result)
	}

	func testDeserializeNoDataPayload() {
		let data = Data([
			// Length (UInt32 Network Byte Order: 1)
			0x00, 0x00, 0x00, 0x01,
			// Type (0)
			0x00,
		])

		let result = getSerialization().deserialize(from: data)

		XCTAssertEqual(.failure(.noDataPayload), result)
	}

	func testDeserializeValidOneByte() {
		let data = Data([
			// Length (UInt32 Network order: 2 (1 byte type, one byte payload))
			0x00, 0x00, 0x00, 0x02,
			// Type (2)
			0x02,
			// Data Payload (1 byte: 3)
			0x03,
		])

		let result = getSerialization().deserialize(from: data)

		guard case let .success(rawPacket) = result else {
			XCTFail("Expected success. Received failure: \(result)")
			return
		}

		XCTAssertEqual(0x02, rawPacket.length)
		XCTAssertEqual(0x02, rawPacket.type)
		XCTAssertEqual(1, rawPacket.dataPayload.count)
		XCTAssertEqual(0x03, rawPacket.dataPayload.first)
	}

	func testDeserializeValidLarge() {
		let header: [UInt8] = [
			// Length (UInt32 Network Order: 101 (1 byte type, 100 bytes payload))
			0x00, 0x00, 0x00, 101,
			// Type (2)
			0x02,
		]
		let payload = [UInt8](repeating: 0x03, count: 100)
		var data = Data()
		data.append(contentsOf: header)
		data.append(contentsOf: payload)

		let result = getSerialization().deserialize(from: data)

		guard let rawPacket = try? result.get() else {
			XCTFail("Expected success. Received failure.")
			return
		}

		XCTAssertEqual(101, rawPacket.length)
		XCTAssertEqual(0x02, rawPacket.type)
		XCTAssertEqual(100, rawPacket.dataPayload.count)
		XCTAssertEqual(0x03, rawPacket.dataPayload.first)
		XCTAssertEqual(0x03, rawPacket.dataPayload.last)
	}

	func testDeserializeLengthMismatchLow() {
		let data = Data([
			// Length (UInt32 Network Order: 10 (1 byte type, 9 bytes payload))
			0x00, 0x00, 0x00, 0x0A,
			// Type
			0x00,
			// Payload (10 bytes)
			0x00, 0x00, 0x00, 0x00, 0x00,
			0x00, 0x00, 0x00, 0x00, 0x00,
		])

		let result = getSerialization().deserialize(from: data)

		XCTAssertEqual(.failure(.lengthMismatch), result)
	}

	func testDeserializeLengthMismatchLHigh() {
		let data = Data([
			// Length (UInt32 Network Order: 10 (1 byte type, 9 bytes payload))
			0x00, 0x00, 0x00, 0x0A,
			// Type
			0x00,
			// Payload (8 bytes)
			0x00, 0x00, 0x00, 0x00, 0x00,
			0x00, 0x00, 0x00, 0x00, 0x00,
		])

		let result = getSerialization().deserialize(from: data)

		XCTAssertEqual(.failure(.lengthMismatch), result)
	}

	static var allTests = [
		("testDeserializeNoData", testDeserializeNoData),
		("testDeserializeNoLength", testDeserializeNoLength),
		("testDeserializeNoType", testDeserializeNoType),
		("testDeserializeNoDataPayload", testDeserializeNoDataPayload),
		("testDeserializeValidOneByte", testDeserializeValidOneByte),
		("testDeserializeLengthMismatchLow", testDeserializeLengthMismatchLow),
		("testDeserializeLengthMismatchLHigh", testDeserializeLengthMismatchLHigh),
	]
}
