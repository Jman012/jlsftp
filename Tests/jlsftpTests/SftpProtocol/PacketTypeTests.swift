import NIO
import XCTest
@testable import jlsftp

final class PacketTypeTests: XCTestCase {

	func testAllPacketTypes() {
		let v3 = jlsftp.SftpProtocol.PacketType.allPacketTypes(for: .v3)
		let v4 = jlsftp.SftpProtocol.PacketType.allPacketTypes(for: .v4)
		let v5 = jlsftp.SftpProtocol.PacketType.allPacketTypes(for: .v5)
		let v6 = jlsftp.SftpProtocol.PacketType.allPacketTypes(for: .v6)

		XCTAssert(v4.isSuperset(of: v3))
		XCTAssert(v5.isSuperset(of: v4))
		XCTAssert(v6.isSuperset(of: v5))
	}

	func testHasBody() {
		XCTAssertEqual(true, jlsftp.SftpProtocol.PacketType.write.hasBody)
		XCTAssertEqual(true, jlsftp.SftpProtocol.PacketType.dataReply.hasBody)
		XCTAssertEqual(true, jlsftp.SftpProtocol.PacketType.extended.hasBody)
		XCTAssertEqual(true, jlsftp.SftpProtocol.PacketType.extendedReply.hasBody)
		XCTAssertEqual(false, jlsftp.SftpProtocol.PacketType.initialize.hasBody)
	}

	static var allTests = [
		("testAllPacketTypes", testAllPacketTypes),
		("testHasBody", testHasBody),
	]
}
