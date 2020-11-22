import XCTest
@testable import jlsftp

final class OpenFlagsV3Tests: XCTestCase {

	func testFlags() {
		// Values take from https://tools.ietf.org/html/draft-ietf-secsh-filexfer-02#section-5
		XCTAssertEqual(
			jlsftp.SftpProtocol.Version_3.OpenFlagsV3(rawValue: 0x0000_0001),
			jlsftp.SftpProtocol.Version_3.OpenFlagsV3.read)
		XCTAssertEqual(
			jlsftp.SftpProtocol.Version_3.OpenFlagsV3(rawValue: 0x0000_0002),
			jlsftp.SftpProtocol.Version_3.OpenFlagsV3.write)
		XCTAssertEqual(
			jlsftp.SftpProtocol.Version_3.OpenFlagsV3(rawValue: 0x0000_0004),
			jlsftp.SftpProtocol.Version_3.OpenFlagsV3.append)
		XCTAssertEqual(
			jlsftp.SftpProtocol.Version_3.OpenFlagsV3(rawValue: 0x0000_0008),
			jlsftp.SftpProtocol.Version_3.OpenFlagsV3.create)
		XCTAssertEqual(
			jlsftp.SftpProtocol.Version_3.OpenFlagsV3(rawValue: 0x0000_0010),
			jlsftp.SftpProtocol.Version_3.OpenFlagsV3.truncate)
		XCTAssertEqual(
			jlsftp.SftpProtocol.Version_3.OpenFlagsV3(rawValue: 0x0000_0020),
			jlsftp.SftpProtocol.Version_3.OpenFlagsV3.exclusive)
	}

	func testToStandard() {
		XCTAssert(jlsftp.SftpProtocol.Version_3.OpenFlagsV3.read.openFlags == [OpenFlag.read])
		XCTAssert(jlsftp.SftpProtocol.Version_3.OpenFlagsV3.write.openFlags == [OpenFlag.write])
		XCTAssert(jlsftp.SftpProtocol.Version_3.OpenFlagsV3.append.openFlags == [OpenFlag.append])
		XCTAssert(jlsftp.SftpProtocol.Version_3.OpenFlagsV3.create.openFlags == [OpenFlag.create])
		XCTAssert(jlsftp.SftpProtocol.Version_3.OpenFlagsV3.truncate.openFlags == [OpenFlag.truncate])
		XCTAssert(jlsftp.SftpProtocol.Version_3.OpenFlagsV3.exclusive.openFlags == [OpenFlag.exclusive])

		let all = jlsftp.SftpProtocol.Version_3.OpenFlagsV3([
			jlsftp.SftpProtocol.Version_3.OpenFlagsV3.read,
			jlsftp.SftpProtocol.Version_3.OpenFlagsV3.write,
			jlsftp.SftpProtocol.Version_3.OpenFlagsV3.append,
			jlsftp.SftpProtocol.Version_3.OpenFlagsV3.create,
			jlsftp.SftpProtocol.Version_3.OpenFlagsV3.truncate,
			jlsftp.SftpProtocol.Version_3.OpenFlagsV3.exclusive,
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
			jlsftp.SftpProtocol.Version_3.OpenFlagsV3(openFlags: [.read]),
			jlsftp.SftpProtocol.Version_3.OpenFlagsV3.read)
		XCTAssertEqual(
			jlsftp.SftpProtocol.Version_3.OpenFlagsV3(openFlags: [.write]),
			jlsftp.SftpProtocol.Version_3.OpenFlagsV3.write)
		XCTAssertEqual(
			jlsftp.SftpProtocol.Version_3.OpenFlagsV3(openFlags: [.append]),
			jlsftp.SftpProtocol.Version_3.OpenFlagsV3.append)
		XCTAssertEqual(
			jlsftp.SftpProtocol.Version_3.OpenFlagsV3(openFlags: [.create]),
			jlsftp.SftpProtocol.Version_3.OpenFlagsV3.create)
		XCTAssertEqual(
			jlsftp.SftpProtocol.Version_3.OpenFlagsV3(openFlags: [.truncate]),
			jlsftp.SftpProtocol.Version_3.OpenFlagsV3.truncate)
		XCTAssertEqual(
			jlsftp.SftpProtocol.Version_3.OpenFlagsV3(openFlags: [.exclusive]),
			jlsftp.SftpProtocol.Version_3.OpenFlagsV3.exclusive)
	}

	static var allTests = [
		("testFlags", testFlags),
		("testToStandard", testToStandard),
		("testFromStandard", testFromStandard),
	]
}
