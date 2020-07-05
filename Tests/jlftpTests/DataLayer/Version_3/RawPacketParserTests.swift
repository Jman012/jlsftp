import XCTest
@testable import jlftp

final class RawPacketParserTests: XCTestCase {
	
	func testParseDataNoData() {
		let data = Data([])
	
		let result = jlftp.DataLayer.Version_3.RawPacketParser().parseData(from: data)
		
		XCTAssertEqual(Result<jlftp.DataLayer.Version_3.RawPacket, jlftp.DataLayer.Version_3.RawPacketParser.ParsingError>.failure(.noData), result)
	}
	
	func testParseDataNoLength() {
		// Any packet that is not 5 bytes (length + type) or more is empty.
		let testcases = [
			Data([0x00]),
			Data([0x00, 0x00]),
			Data([0x00, 0x00, 0x00]),
			
		]
		
		for testcaseData in testcases {
			let result = jlftp.DataLayer.Version_3.RawPacketParser().parseData(from: testcaseData)
			
			XCTAssertEqual(Result<jlftp.DataLayer.Version_3.RawPacket, jlftp.DataLayer.Version_3.RawPacketParser.ParsingError>.failure(.noLength), result)
		}
	}
	
	func testParseDataNoType() {
		let data = Data([
			// Length (0)
			0x00, 0x00, 0x00, 0x00,
			// Type (nothing)
		])
		
		let result = jlftp.DataLayer.Version_3.RawPacketParser().parseData(from: data)
		
		XCTAssertEqual(Result<jlftp.DataLayer.Version_3.RawPacket, jlftp.DataLayer.Version_3.RawPacketParser.ParsingError>.failure(.noType), result)
	}
	
	func testParseDataNoDataPayload() {
		let data = Data([
			// Length (0)
			0x00, 0x00, 0x00, 0x00,
			// Type (0)
			0x00,
		])
		
		let result = jlftp.DataLayer.Version_3.RawPacketParser().parseData(from: data)
		
		XCTAssertEqual(Result<jlftp.DataLayer.Version_3.RawPacket, jlftp.DataLayer.Version_3.RawPacketParser.ParsingError>.failure(.noDataPayload), result)
	}
	
	func testParseDataValidOneByte() {
		let data = Data([
			// Length (2 (1 byte type, one byte payload)
			0x02, 0x00, 0x00, 0x00,
			// Type (2)
			0x02,
			// Data Payload (1 byte: 3)
			0x03
		])
		
		let result = jlftp.DataLayer.Version_3.RawPacketParser().parseData(from: data)
		
		guard case let .success(rawPacket) = result else {
			XCTFail("Expected success. Received failure: \(result)")
			return
		}
		
		XCTAssertEqual(0x02, rawPacket.length)
		XCTAssertEqual(0x02, rawPacket.type)
		XCTAssertEqual(1, rawPacket.dataPayload.count)
		XCTAssertEqual(0x03, rawPacket.dataPayload[0])
	}
	
	func testParseDataValidLarge() {
		let header: [UInt8] = [
			// Length (101 (1 byte type, 100 bytes payload))
			101, 0x00, 0x00, 0x00,
			// Type (2)
			0x02,
		]
		let payload = Array<UInt8>(repeating: 0x03, count: 100)
		var data = Data()
		data.append(contentsOf: header)
		data.append(contentsOf: payload)
		
		let result = jlftp.DataLayer.Version_3.RawPacketParser().parseData(from: data)
		
		guard let rawPacket = try? result.get() else {
			XCTFail("Expected success. Received failure.")
			return
		}
		
		XCTAssertEqual(101, rawPacket.length)
		XCTAssertEqual(0x02, rawPacket.type)
		XCTAssertEqual(100, rawPacket.dataPayload.count)
		XCTAssertEqual(0x03, rawPacket.dataPayload[0])
		XCTAssertEqual(0x03, rawPacket.dataPayload[98])
	}
	
	func testParseDataLengthMismatchLow() {
		let data = Data([
			// Length (10 (1 byte type, 9 bytes payload))
			0x0A, 0x00, 0x00, 0x00,
			// Type
			0x00,
			// Payload (10 bytes)
			0x00, 0x00, 0x00, 0x00, 0x00,
			0x00, 0x00, 0x00, 0x00, 0x00,
		])
		
		let result = jlftp.DataLayer.Version_3.RawPacketParser().parseData(from: data)
		
		XCTAssertEqual(Result<jlftp.DataLayer.Version_3.RawPacket, jlftp.DataLayer.Version_3.RawPacketParser.ParsingError>.failure(.lengthMismatch), result)
	}
	
	func testParseDataLengthMismatchLHigh() {
		let data = Data([
			// Length (10 (1 byte type, 9 bytes payload))
			0x0A, 0x00, 0x00, 0x00,
			// Type
			0x00,
			// Payload (8 bytes)
			0x00, 0x00, 0x00, 0x00, 0x00,
			0x00, 0x00, 0x00, 0x00, 0x00,
		])
		
		let result = jlftp.DataLayer.Version_3.RawPacketParser().parseData(from: data)
		
		XCTAssertEqual(Result<jlftp.DataLayer.Version_3.RawPacket, jlftp.DataLayer.Version_3.RawPacketParser.ParsingError>.failure(.lengthMismatch), result)
	}
	
	static var allTests = [
		("testParseDataNoData", testParseDataNoData),
		("testParseDataNoLength", testParseDataNoLength),
		("testParseDataNoType", testParseDataNoType),
		("testParseDataNoDataPayload", testParseDataNoDataPayload),
		("testParseDataValidOneByte", testParseDataValidOneByte),
		("testParseDataLengthMismatchLow", testParseDataLengthMismatchLow),
		("testParseDataLengthMismatchLHigh", testParseDataLengthMismatchLHigh),
	]
}
