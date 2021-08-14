import XCTest
@testable import jlsftp

final class SyscallTests: XCTestCase {

	// MARK: Test `syscall<T: FixedWidthInteger>(where:_:)`

	func testSyscallIntegerValid() {
		XCTAssertNoThrow {
			try syscall {
				return 0
			}
		}
	}

	func testSyscallIntegerThrows() {
		XCTAssertThrowsError(
			try syscall { () -> Int in
				errno = EINVAL
				return -1
			}
		)
	}

	// MARK: Test `syscall<T>(where:_:)`

	func testSyscallTValid() {
		var result = timespec(tv_sec: 1, tv_nsec: 0)
		XCTAssertNoThrow {
			try syscall { () -> UnsafeMutablePointer<timespec>? in
				return withUnsafeMutablePointer(to: &result) {
					return $0
				}
			}
		}
	}

	func testSyscallTThrows() {
		XCTAssertThrowsError(
			try syscall { () -> UnsafeMutablePointer<timespec>? in
				errno = EINVAL
				return nil
			}
		)
	}

	static var allTests = [
		("testSyscallIntegerValid", testSyscallIntegerValid),
		("testSyscallIntegerThrows", testSyscallIntegerThrows),
		("testSyscallTValid", testSyscallTValid),
		("testSyscallTThrows", testSyscallTThrows),
	]
}
