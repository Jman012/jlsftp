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

public class SftpFileHandleCollection {
	private var handles: [String: OpenFileHandle] = [:]

	/// Tracks a new `OpenFileHandle` and returns the string handle for sftp
	public func insertFileHandle(handle: OpenFileHandle) -> String {
		let handleIdentifier = generateNewUniqueHandle()
		handles[handleIdentifier] = handle
		return handleIdentifier
	}

	public func contains(handleIdentifier: String) -> Bool {
		return handles.keys.contains(handleIdentifier)
	}

	public func getHandle(handleIdentifier: String) -> OpenFileHandle? {
		return handles[handleIdentifier]
	}

	public func removeHandle(handleIdentifier: String) -> OpenFileHandle? {
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
		for fileHandle in handles.values {
			try? fileHandle.nioHandle.close()
		}
	}
}
