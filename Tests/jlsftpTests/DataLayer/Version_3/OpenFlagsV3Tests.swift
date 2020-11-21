import XCTest
@testable import jlsftp

final class OpenFlagsV3Tests: XCTestCase {

	func testFlags() {
		// Values take from https://tools.ietf.org/html/draft-ietf-secsh-filexfer-02#section-5
		XCTAssertEqual(
			jlsftp.DataLayer.Version_3.OpenFlagsV3(rawValue: 0x0000_0001),
			jlsftp.DataLayer.Version_3.OpenFlagsV3.read)
		XCTAssertEqual(
			jlsftp.DataLayer.Version_3.OpenFlagsV3(rawValue: 0x0000_0002),
			jlsftp.DataLayer.Version_3.OpenFlagsV3.write)
		XCTAssertEqual(
			jlsftp.DataLayer.Version_3.OpenFlagsV3(rawValue: 0x0000_0004),
			jlsftp.DataLayer.Version_3.OpenFlagsV3.append)
		XCTAssertEqual(
			jlsftp.DataLayer.Version_3.OpenFlagsV3(rawValue: 0x0000_0008),
			jlsftp.DataLayer.Version_3.OpenFlagsV3.create)
		XCTAssertEqual(
			jlsftp.DataLayer.Version_3.OpenFlagsV3(rawValue: 0x0000_0010),
			jlsftp.DataLayer.Version_3.OpenFlagsV3.truncate)
		XCTAssertEqual(
			jlsftp.DataLayer.Version_3.OpenFlagsV3(rawValue: 0x0000_0020),
			jlsftp.DataLayer.Version_3.OpenFlagsV3.exclusive)
	}

	func testToStandard() {
		XCTAssert(jlsftp.DataLayer.Version_3.OpenFlagsV3.read.openFlags == [OpenFlag.read])
		XCTAssert(jlsftp.DataLayer.Version_3.OpenFlagsV3.write.openFlags == [OpenFlag.write])
		XCTAssert(jlsftp.DataLayer.Version_3.OpenFlagsV3.append.openFlags == [OpenFlag.append])
		XCTAssert(jlsftp.DataLayer.Version_3.OpenFlagsV3.create.openFlags == [OpenFlag.create])
		XCTAssert(jlsftp.DataLayer.Version_3.OpenFlagsV3.truncate.openFlags == [OpenFlag.truncate])
		XCTAssert(jlsftp.DataLayer.Version_3.OpenFlagsV3.exclusive.openFlags == [OpenFlag.exclusive])

		let all = jlsftp.DataLayer.Version_3.OpenFlagsV3([
			jlsftp.DataLayer.Version_3.OpenFlagsV3.read,
			jlsftp.DataLayer.Version_3.OpenFlagsV3.write,
			jlsftp.DataLayer.Version_3.OpenFlagsV3.append,
			jlsftp.DataLayer.Version_3.OpenFlagsV3.create,
			jlsftp.DataLayer.Version_3.OpenFlagsV3.truncate,
			jlsftp.DataLayer.Version_3.OpenFlagsV3.exclusive,
		])
		XCTAssert(all.openFlags == [
			OpenFlag.read,
			OpenFlag.write,
			OpenFlag.append,
			OpenFlag.create,
			OpenFlag.truncate,
			OpenFlag.exclusive,
		])
	}

	func testFromStandard() {
		XCTAssertEqual(
			jlsftp.DataLayer.Version_3.OpenFlagsV3(openFlags: [.read]),
			jlsftp.DataLayer.Version_3.OpenFlagsV3.read)
		XCTAssertEqual(
			jlsftp.DataLayer.Version_3.OpenFlagsV3(openFlags: [.write]),
			jlsftp.DataLayer.Version_3.OpenFlagsV3.write)
		XCTAssertEqual(
			jlsftp.DataLayer.Version_3.OpenFlagsV3(openFlags: [.append]),
			jlsftp.DataLayer.Version_3.OpenFlagsV3.append)
		XCTAssertEqual(
			jlsftp.DataLayer.Version_3.OpenFlagsV3(openFlags: [.create]),
			jlsftp.DataLayer.Version_3.OpenFlagsV3.create)
		XCTAssertEqual(
			jlsftp.DataLayer.Version_3.OpenFlagsV3(openFlags: [.truncate]),
			jlsftp.DataLayer.Version_3.OpenFlagsV3.truncate)
		XCTAssertEqual(
			jlsftp.DataLayer.Version_3.OpenFlagsV3(openFlags: [.exclusive]),
			jlsftp.DataLayer.Version_3.OpenFlagsV3.exclusive)
	}

	static var allTests = [
		("testFlags", testFlags),
		("testToStandard", testToStandard),
		("testFromStandard", testFromStandard),
	]
}
