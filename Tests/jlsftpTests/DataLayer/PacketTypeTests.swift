import NIO
import XCTest
@testable import jlsftp

final class PacketTypeTests: XCTestCase {

	func testAllPacketTypes() {
		let v3 = jlsftp.DataLayer.PacketType.allPacketTypes(for: .v3)
		let v4 = jlsftp.DataLayer.PacketType.allPacketTypes(for: .v4)
		let v5 = jlsftp.DataLayer.PacketType.allPacketTypes(for: .v5)
		let v6 = jlsftp.DataLayer.PacketType.allPacketTypes(for: .v6)

		XCTAssert(v4.isSuperset(of: v3))
		XCTAssert(v5.isSuperset(of: v4))
		XCTAssert(v6.isSuperset(of: v5))
	}

	func testHasBody() {
		XCTAssertEqual(true, jlsftp.DataLayer.PacketType.write.hasBody)
		XCTAssertEqual(true, jlsftp.DataLayer.PacketType.dataReply.hasBody)
		XCTAssertEqual(true, jlsftp.DataLayer.PacketType.extended.hasBody)
		XCTAssertEqual(true, jlsftp.DataLayer.PacketType.extendedReply.hasBody)
		XCTAssertEqual(false, jlsftp.DataLayer.PacketType.initialize.hasBody)
	}

	static var allTests = [
		("testAllPacketTypes", testAllPacketTypes),
	]
}
