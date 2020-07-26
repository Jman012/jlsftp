import Foundation

public class DataReadStream {

	public enum ReadError: Error {
		case endOfStream
	}

	internal let inputStream: InputStream

	public init(from inputStream: InputStream) {
		self.inputStream = inputStream
	}

	public func readBytes(exactCount count: Int) -> Result<Data, ReadError> {
		if count == 0 {
			return .success(Data())
		}

		var buffer = [UInt8](repeating: 0, count: count)
		if self.inputStream.read(&buffer, maxLength: count) != count {
			return .failure(.endOfStream)
		}
		return .success(Data(bytes: buffer, count: buffer.count))
	}

	public func readBytes(maxCount count: Int) -> Data {
		if count == 0 {
			return Data()
		}

		var buffer = [UInt8](repeating: 0, count: count)
		let readLen = self.inputStream.read(&buffer, maxLength: count)
		return Data(bytes: buffer, count: min(readLen, buffer.count))
	}
}
