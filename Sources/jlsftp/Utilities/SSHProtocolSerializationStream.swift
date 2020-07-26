import Foundation

/**
Serializes data types found in in the RFC 4251 family of "SSH Protocol
Architecture" documents, for use in sftp communication packets.
*/
public protocol SSHProtocolSerializationStream {
	func deserializeByte(from stream: DataReadStream) -> Result<UInt8, DataReadStream.ReadError>
	func deserializeUInt32(from stream: DataReadStream) -> Result<UInt32, DataReadStream.ReadError>
	func deserializeUInt64(from stream: DataReadStream) -> Result<UInt64, DataReadStream.ReadError>
	func deserializeString(from stream: DataReadStream) -> Result<String, DataReadStream.ReadError>
}

/**
Draft 9 of the "SSH Protocol Architecture" data type serializer. See:
https://tools.ietf.org/html/draft-ietf-secsh-architecture-09. Referenced in
sftp version 3.
*/
public class SSHProtocolSerializationStreamDraft9: SSHProtocolSerializationStream {

	public func deserializeFixedWidthInteger<T: FixedWidthInteger>(_: T.Type, from stream: DataReadStream) -> Result<T, DataReadStream.ReadError> {
		switch stream.readBytes(exactCount: T.byteWidth) {
		case let .failure(error):
			return .failure(error)
		case let .success(bytes):
			return .success(bytes.to(T.self, from: .networkOrder)!)
		}
	}

	public func deserializeByte(from stream: DataReadStream) -> Result<UInt8, DataReadStream.ReadError> {
		return deserializeFixedWidthInteger(UInt8.self, from: stream)
	}

	public func deserializeUInt32(from stream: DataReadStream) -> Result<UInt32, DataReadStream.ReadError> {
		return deserializeFixedWidthInteger(UInt32.self, from: stream)
	}

	public func deserializeUInt64(from stream: DataReadStream) -> Result<UInt64, DataReadStream.ReadError> {
		return deserializeFixedWidthInteger(UInt64.self, from: stream)
	}

	public func deserializeString(from stream: DataReadStream) -> Result<String, DataReadStream.ReadError> {
		return self.deserializeUInt32(from: stream)
			.flatMap { stream.readBytes(exactCount: Int($0)) }
			.flatMap {
				let s = String(bytes: $0, encoding: .utf8)
				if let s = s {
					return .success(s)
				} else {
					return .failure(.endOfStream)
				}
		}
	}

}
