import NIO
import XCTest
@testable import jlsftp

final class PacketSerializerV3Tests: XCTestCase {

	func testInit() {
		_ = jlsftp.DataLayer.Version_3.PacketSerializerV3()
	}

	static var allTests = [
		("testInit", testInit),
	]
}
