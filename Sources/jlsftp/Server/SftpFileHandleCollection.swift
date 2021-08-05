import Foundation
import NIO

public class OpenFileHandle {
	let path: String
	let nioHandle: NIOFileHandle
	init(path: String, nioHandle: NIOFileHandle) {
		self.path = path
		self.nioHandle = nioHandle
	}
}

public class OpenDirHandle {
	let path: String
	let dir: UnsafeMutablePointer<DIR>
	init(path: String, dir: UnsafeMutablePointer<DIR>) {
		self.path = path
		self.dir = dir
	}
}

public enum OpenHandle {
	case file(OpenFileHandle)
	case dir(OpenDirHandle)
}

public class SftpHandleCollection {
	private var handles: [String: OpenHandle] = [:]

	/// Tracks a new `OpenHandle` and returns the string handle for sftp
	public func insertHandle(handle: OpenHandle) -> String {
		let handleIdentifier = generateNewUniqueHandle()
		handles[handleIdentifier] = handle
		return handleIdentifier
	}

	public func contains(handleIdentifier: String) -> Bool {
		return handles.keys.contains(handleIdentifier)
	}

	public func getHandle(handleIdentifier: String) -> OpenHandle? {
		return handles[handleIdentifier]
	}

	public func removeHandle(handleIdentifier: String) -> OpenHandle? {
		return handles.removeValue(forKey: handleIdentifier)
	}

	private func generateNewUniqueHandle() -> String {
		// The sftp spec enforces handles to be no more than 256 characters
		// long, so use the maximum initially.
		let length = 256
		let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

		var randomHandle: String
		repeat {
			randomHandle = String((0..<length).map { _ in letters.randomElement()! })
		} while handles.keys.contains(randomHandle)

		return randomHandle
	}

	deinit {
		for handle in handles.values {
			switch handle {
			case let .file(fileHandle):
				try? fileHandle.nioHandle.close()
			case let .dir(dirHandle):
				closedir(dirHandle.dir)
			}
		}
	}
}
