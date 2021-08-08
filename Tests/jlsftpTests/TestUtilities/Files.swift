import Foundation
import NIO
import XCTest

func withTemporaryDirectory<T>(_ body: (String) throws -> T) rethrows -> T {
	let dir = createTemporaryDirectory()
	defer {
		try? FileManager.default.removeItem(atPath: dir)
	}
	return try body(dir)
}

func withTemporaryDirectoryNoRemove<T>(_ body: (String) throws -> T) rethrows -> T {
	let dir = createTemporaryDirectory()
	defer {
		try? FileManager.default.removeItem(atPath: dir)
	}
	return try body(dir)
}

func removeTemporaryDirectory(dir: String) {
	try? FileManager.default.removeItem(atPath: dir)
}

func withTemporaryFile<T>(content: String? = nil, _ body: (NIO.NIOFileHandle, String) throws -> T) rethrows -> T {
	let (fd, path) = openTemporaryFile()
	let fileHandle = NIOFileHandle(descriptor: fd)
	defer {
		XCTAssertNoThrow(try fileHandle.close())
		XCTAssertEqual(0, unlink(path))
	}
	if let content = content {
		Array(content.utf8).withUnsafeBufferPointer { ptr in
			var toWrite = ptr.count
			var start = ptr.baseAddress!
			while toWrite > 0 {
				let res = write(fd, start, toWrite)
				if res < 0 {
					XCTFail("Unexpected failure in creating file: \(errno)")
				} else {
					toWrite -= res
					start = start + res
				}
			}
			XCTAssertEqual(0, lseek(fd, 0, SEEK_SET))
		}
	}
	return try body(fileHandle, path)
}

func withTemporaryFileNoUnlink<T>(content: String? = nil, _ body: (NIO.NIOFileHandle, String) throws -> T) rethrows -> T {
	let (fd, path) = openTemporaryFile()
	let fileHandle = NIOFileHandle(descriptor: fd)
	defer {
		XCTAssertNoThrow(try fileHandle.close())
		//XCTAssertEqual(0, unlink(path))
	}
	if let content = content {
		Array(content.utf8).withUnsafeBufferPointer { ptr in
			var toWrite = ptr.count
			var start = ptr.baseAddress!
			while toWrite > 0 {
				let res = write(fd, start, toWrite)
				if res < 0 {
					XCTFail("Unexpected failure in creating file: \(errno)")
				} else {
					toWrite -= res
					start = start + res
				}
			}
			XCTAssertEqual(0, lseek(fd, 0, SEEK_SET))
		}
	}
	return try body(fileHandle, path)
}

var temporaryDirectory: String {
	#if targetEnvironment(simulator)
	// Simulator temp directories are so long (and contain the user name) that they're not usable
	// for UNIX Domain Socket paths (which are limited to 103 bytes).
	return "/tmp"
	#else
	#if os(Android)
	return "/data/local/tmp"
	#elseif os(Linux)
	return "/tmp"
	#else
	if #available(macOS 10.12, iOS 10, tvOS 10, watchOS 3, *) {
		return FileManager.default.temporaryDirectory.path
	} else {
		return "/tmp"
	}
	#endif // os
	#endif // targetEnvironment
}

func createTemporaryDirectory() -> String {
	let template = "\(temporaryDirectory)/.NIOTests-temp-dir_XXXXXX"

	var templateBytes = template.utf8 + [0]
	let templateBytesCount = templateBytes.count
	templateBytes.withUnsafeMutableBufferPointer { ptr in
		ptr.baseAddress!.withMemoryRebound(to: Int8.self, capacity: templateBytesCount) { (ptr: UnsafeMutablePointer<Int8>) in
			let ret = mkdtemp(ptr)
			XCTAssertNotNil(ret)
		}
	}
	templateBytes.removeLast()
	return String(decoding: templateBytes, as: Unicode.UTF8.self)
}

func openTemporaryFile() -> (CInt, String) {
	let template = "\(temporaryDirectory)/nio_XXXXXX"
	var templateBytes = template.utf8 + [0]
	let templateBytesCount = templateBytes.count
	let fd = templateBytes.withUnsafeMutableBufferPointer { ptr in
		ptr.baseAddress!.withMemoryRebound(to: Int8.self, capacity: templateBytesCount) { (ptr: UnsafeMutablePointer<Int8>) in
			return mkstemp(ptr)
		}
	}
	templateBytes.removeLast()
	return (fd, String(decoding: templateBytes, as: Unicode.UTF8.self))
}
