import XCTest
@testable import jlftp

final class PacketParserTests: XCTestCase {
	
	class MockParserHandler: SftpVersion3PacketParserHandler {
		var timesCalled = 0
		func parse(fromPayload data: Data) -> Result<Packet, jlftp.DataLayer.Version_3.PacketParser.ParseError> {
			timesCalled += 1
			return .failure(.invalidDataPayload(reason: "test"))
		}
	}
	
	func testInvalidTypeZero() {
		let mockOther = MockParserHandler()
		let packetParser = jlftp.DataLayer.Version_3.PacketParser(
			initializePacketParser: mockOther,
			versionPacketParser: mockOther
		)
		
		let result = packetParser.parseRawPacket(
			from: jlftp.DataLayer.Version_3.RawPacket(length: 0, type: 0, dataPayload: Data())
		)
		
		guard case .failure(.invalidType) = result else {
			XCTFail("Expected invalidType failure. Got '\(result)'")
			return
		}
		
		XCTAssertEqual(0, mockOther.timesCalled)
	}
	
	func testInvalidTypeUnhandled() {
		let mockOther = MockParserHandler()
		let packetParser = jlftp.DataLayer.Version_3.PacketParser(
			initializePacketParser: mockOther,
			versionPacketParser: mockOther
		)
		
		let result = packetParser.parseRawPacket(
			from: jlftp.DataLayer.Version_3.RawPacket(
				length: 0,
				type: jlftp.DataLayer.Version_3.PacketType.extended.rawValue,
				dataPayload: Data()
			)
		)
		
		guard case .failure(.invalidType) = result else {
			XCTFail("Expected invalidType failure. Got '\(result)'")
			return
		}
		
		XCTAssertEqual(0, mockOther.timesCalled)
	}
	
	func testInitialize() {
		
		let mockInitilize = MockParserHandler()
		let mockOther = MockParserHandler()
		let packetParser = jlftp.DataLayer.Version_3.PacketParser(
			initializePacketParser: mockInitilize,
			versionPacketParser: mockOther
		)
		
		let result = packetParser.parseRawPacket(
			from: jlftp.DataLayer.Version_3.RawPacket(
				length: 0,
				type: jlftp.DataLayer.Version_3.PacketType.initialize.rawValue,
				dataPayload: Data([0x03])
			)
		)
		
		guard case .failure(.invalidDataPayload(reason: "test")) = result else {
			XCTFail("Expected failure. Got '\(result)'")
			return
		}
				
		XCTAssertEqual(1, mockInitilize.timesCalled)
		XCTAssertEqual(0, mockOther.timesCalled)
	}
	
	func testVersion() {
		
		let mockVersion = MockParserHandler()
		let mockOther = MockParserHandler()
		let packetParser = jlftp.DataLayer.Version_3.PacketParser(
			initializePacketParser: mockOther,
			versionPacketParser: mockVersion
		)
		
		let result = packetParser.parseRawPacket(
			from: jlftp.DataLayer.Version_3.RawPacket(
				length: 0,
				type: jlftp.DataLayer.Version_3.PacketType.version.rawValue,
				dataPayload: Data([0x03])
			)
		)
		
		guard case .failure(.invalidDataPayload(reason: "test")) = result else {
			XCTFail("Expected failure. Got '\(result)'")
			return
		}
		
		XCTAssertEqual(1, mockVersion.timesCalled)
		XCTAssertEqual(0, mockOther.timesCalled)
	}
	
	static var allTests = [
		("testInvalidTypeZero", testInvalidTypeZero),
		("testInvalidTypeUnhandled", testInvalidTypeUnhandled),
		("testInitialize", testInitialize),
		("testVersion", testVersion),
	]
}
