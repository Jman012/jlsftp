import Foundation
import NIO

@inline(__always)
internal func syscall<T: FixedWidthInteger>(
	where function: String = #function,
	_ body: () throws -> T) throws {
	let res = try body()
	if res == -1 {
		let err = errno
		throw IOError(errnoCode: err, reason: function)
	}
}

@inline(__always)
internal func syscall<T>(
	where function: String = #function,
	_ body: () throws -> UnsafeMutablePointer<T>?) throws -> UnsafeMutablePointer<T>! {
	let res = try body()
	if res == nil {
		let err = errno
		throw IOError(errnoCode: err, reason: function)
	}
	return res
}

@inline(__always)
internal func syscallAcceptableNil<T>(
	where function: String = #function,
	_ body: () throws -> UnsafeMutablePointer<T>?) throws -> UnsafeMutablePointer<T>? {
	let res = try body()
	if res == nil {
		let err = errno
		if err == 0 {
			return nil
		}
		throw IOError(errnoCode: err, reason: function)
	}
	return res
}
