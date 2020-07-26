import Foundation

public class BoundDataReadStream: DataReadStream {

	public let maxBytes: UInt64
	public private(set) var bytesRead: UInt64
	public private(set) var bytesRemaining: UInt64

	public init(from inputStream: InputStream, maxBytes: UInt64) {
		self.maxBytes = maxBytes
		self.bytesRead = 0
		self.bytesRemaining = maxBytes
		super.init(from: inputStream)
		self.bytesRemaining = maxBytes
	}

	// MARK: DataReadStream Methods

	public override func readBytes(exactCount count: Int) -> Result<Data, DataReadStream.ReadError> {
		// Expected failure
		if count > bytesRemaining {
			return .failure(.endOfStream)
		}

		let result = super.readBytes(exactCount: count)

		switch result {
		case let .failure(error):
			bytesRead += UInt64(count)
			bytesRemaining = 0
			return .failure(error)
		case let .success(bytes):
			bytesRead += UInt64(count)
			bytesRemaining -= UInt64(count)
			return .success(bytes)
		}
	}

	public override func readBytes(maxCount count: Int) -> Data {
		// Restrict reading bytes to what is allowed.
		// If bytesRemaining is too large, it's okay to just use Int.max since
		// count will likely be smaller, not larger.
		let maxAllowedBytesToRead = min(count, Int(exactly: bytesRemaining) ?? Int.max)

		let result = super.readBytes(maxCount: maxAllowedBytesToRead)

		// Increment the counter
		bytesRead += UInt64(result.count)
		bytesRemaining -= UInt64(result.count)

		// If the stream has ended, mark ourselves as ended too
		if result.count < count || !self.inputStream.hasBytesAvailable {
			bytesRemaining = 0
		}

		return result
	}
}
