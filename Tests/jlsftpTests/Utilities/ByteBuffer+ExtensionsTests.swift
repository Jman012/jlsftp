import XCTest
import NIO
@testable import jlsftp

final class ByteBufferExtenstionsTests: XCTestCase {

	// MARK: Test `readSftpString()`

	func testReadSftpStringValid() {
		let data: [(ByteBuffer, String)] = [
			(ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x00]), ""),
			(ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x01, 0x61]), "a"),
			(ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x02, 0x41, 0x62]), "Ab"),
			(ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x01, 0x41, 0x62]), "A"),
		]

		for datum in data {
			var buffer = datum.0
			let result = buffer.readSftpString()
			switch result {
			case let .success(string):
				XCTAssertEqual(string, datum.1)
			case .failure:
				XCTFail()
			}
		}
	}

	func testReadSftpStringInvalid() {
		let data: [(ByteBuffer, PacketDeserializationHandlerError)] = [
			(ByteBuffer(bytes: [0x00, 0x00, 0x00]), .needMoreData),
			(ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x01]), .needMoreData),
			(ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x02, 0x41]), .needMoreData),
			(ByteBuffer(bytes: [0x00, 0x00, 0x00, 0x01, 0xff]), .invalidData(reason: "Invalid UTF8 string data")),
		]

		for datum in data {
			var buffer = datum.0
			let result = buffer.readSftpString()
			switch result {
			case .success:
				XCTFail()
			case let .failure(error):
				XCTAssertEqual(error, datum.1)
			}
		}
	}

	// MARK: Test `writeSftpString(_:)`

	func testWriteSftpStringValid() {
		let data: [(String, Int, [UInt8])] = [
			("", 4, [0x00, 0x00, 0x00, 0x00]),
			("a", 5, [0x00, 0x00, 0x00, 0x01, 0x61]),
			("Ab", 6, [0x00, 0x00, 0x00, 0x02, 0x41, 0x62]),
		]
		for datum in data {
			var byteBuffer = ByteBuffer()
			byteBuffer.writeSftpString(datum.0)
			XCTAssertEqual(byteBuffer.readableBytes, datum.1)
			XCTAssertEqual(byteBuffer.readBytes(length: byteBuffer.readableBytes), datum.2)
		}
	}

	static var allTests = [
		("testReadSftpStringValid", testReadSftpStringValid),
		("testWriteSftpStringValid", testWriteSftpStringValid),
	]
}
