import XCTest
@testable import NIO
@testable import jlsftp

final class NIOFileHandleExtensionsTests: XCTestCase {

	func testValidModeFromOpenFlags() {
		let data: [(OpenFlags, NIOFileHandle.Mode)] = [
			([], []),
			([.read], [.read]),
			([.write], [.write]),
			([.read, .append], [.read]),
			([.write, .create], [.write]),
			([.truncate], []),
			([.read, .write], [.read, .write]),
			([.read, .write, .exclusive], [.read, .write]),
		]

		for datum in data {
			XCTAssertEqual(NIOFileHandle.Mode(fromOpenFlags: datum.0), datum.1)
		}
	}

	func testValidFlags() {
		// Don't bother testing Permissions and posixMode much, since it's
		// tested in testValidModeFromOpenFlags above mostly. Just ensure it
		// passes through.
		// O_NONBLOCK is always added.
		let data: [(Permissions, OpenFlags, CInt, mode_t)] = [
			(Permissions(user: [], group: [], other: [], mode: [], fileType: nil), [],
			 O_NONBLOCK, 0),
			(Permissions(user: [.read], group: [.write], other: [.execute], mode: [], fileType: nil), [],
			 O_NONBLOCK, S_IRUSR | S_IWGRP | S_IXOTH),
			(Permissions(user: [], group: [], other: [], mode: [], fileType: nil), [.read],
			 O_NONBLOCK | O_RDONLY, 0),
			(Permissions(user: [], group: [], other: [], mode: [], fileType: nil), [.write],
			 O_NONBLOCK | O_WRONLY, 0),
			(Permissions(user: [], group: [], other: [], mode: [], fileType: nil), [.read, .write],
			 O_NONBLOCK | O_RDWR, 0),
			(Permissions(user: [], group: [], other: [], mode: [], fileType: nil), [.append],
			 O_NONBLOCK | O_APPEND, 0),
			(Permissions(user: [], group: [], other: [], mode: [], fileType: nil), [.create],
			 O_NONBLOCK | O_CREAT, 0),
			(Permissions(user: [], group: [], other: [], mode: [], fileType: nil), [.exclusive],
			 O_NONBLOCK | O_EXCL, 0),
			(Permissions(user: [], group: [], other: [], mode: [], fileType: nil), [.truncate],
			 O_NONBLOCK | O_TRUNC, 0),
			(Permissions(user: [], group: [], other: [], mode: [], fileType: nil), [.read, .write, .append],
			 O_NONBLOCK | O_RDWR | O_APPEND, 0),
			(Permissions(user: [], group: [], other: [], mode: [], fileType: nil), [.read, .truncate],
			 O_NONBLOCK | O_RDONLY | O_TRUNC, 0),
			(Permissions(user: [], group: [], other: [], mode: [], fileType: nil), [.read, .write, .append, .create, .exclusive, .truncate],
			 O_NONBLOCK | O_RDWR | O_APPEND | O_CREAT | O_EXCL | O_TRUNC, 0),
		]

		for datum in data {
			let nioFlagComps = NIOFileHandle.Flags.jlsftp(permissions: datum.0, openFlags: datum.1)
			XCTAssertEqual(nioFlagComps.0, datum.2)
			XCTAssertEqual(nioFlagComps.1, datum.3)
		}
	}

	static var allTests = [
		("testValidModeFromOpenFlags", testValidModeFromOpenFlags),
		("testValidFlags", testValidFlags),
	]
}
