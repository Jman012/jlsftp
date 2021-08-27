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
		let data: [(Permissions, OpenFlags, NIOFileHandle.Flags)] = [
			(Permissions(user: [], group: [], other: [], mode: [], fileType: nil), [],
			 NIOFileHandle.Flags(posixMode: 0, posixFlags: O_NONBLOCK)),
			(Permissions(user: [.read], group: [.write], other: [.execute], mode: [], fileType: nil), [],
			 NIOFileHandle.Flags(posixMode: S_IRUSR | S_IWGRP | S_IXOTH, posixFlags: O_NONBLOCK)),
			(Permissions(user: [], group: [], other: [], mode: [], fileType: nil), [.read],
			 NIOFileHandle.Flags(posixMode: 0, posixFlags: O_NONBLOCK | O_RDONLY)),
			(Permissions(user: [], group: [], other: [], mode: [], fileType: nil), [.write],
			 NIOFileHandle.Flags(posixMode: 0, posixFlags: O_NONBLOCK | O_WRONLY)),
			(Permissions(user: [], group: [], other: [], mode: [], fileType: nil), [.read, .write],
			 NIOFileHandle.Flags(posixMode: 0, posixFlags: O_NONBLOCK | O_RDWR)),
			(Permissions(user: [], group: [], other: [], mode: [], fileType: nil), [.append],
			 NIOFileHandle.Flags(posixMode: 0, posixFlags: O_NONBLOCK | O_APPEND)),
			(Permissions(user: [], group: [], other: [], mode: [], fileType: nil), [.create],
			 NIOFileHandle.Flags(posixMode: 0, posixFlags: O_NONBLOCK | O_CREAT)),
			(Permissions(user: [], group: [], other: [], mode: [], fileType: nil), [.exclusive],
			 NIOFileHandle.Flags(posixMode: 0, posixFlags: O_NONBLOCK | O_EXCL)),
			(Permissions(user: [], group: [], other: [], mode: [], fileType: nil), [.truncate],
			 NIOFileHandle.Flags(posixMode: 0, posixFlags: O_NONBLOCK | O_TRUNC)),
			(Permissions(user: [], group: [], other: [], mode: [], fileType: nil), [.read, .write, .append],
			 NIOFileHandle.Flags(posixMode: 0, posixFlags: O_NONBLOCK | O_RDWR | O_APPEND)),
			(Permissions(user: [], group: [], other: [], mode: [], fileType: nil), [.read, .truncate],
			 NIOFileHandle.Flags(posixMode: 0, posixFlags: O_NONBLOCK | O_RDONLY | O_TRUNC)),
			(Permissions(user: [], group: [], other: [], mode: [], fileType: nil), [.read, .write, .append, .create, .exclusive, .truncate],
			 NIOFileHandle.Flags(posixMode: 0, posixFlags: O_NONBLOCK | O_RDWR | O_APPEND | O_CREAT | O_EXCL | O_TRUNC)),
		]

		for datum in data {
			let flags = NIOFileHandle.Flags.jlsftp(permissions: datum.0, openFlags: datum.1)
			XCTAssertEqual(flags.posixFlags, datum.2.posixFlags)
			XCTAssertEqual(flags.posixMode, datum.2.posixMode)
		}
	}

	static var allTests = [
		("testValidModeFromOpenFlags", testValidModeFromOpenFlags),
		("testValidFlags", testValidFlags),
	]
}
