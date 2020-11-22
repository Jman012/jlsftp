import Foundation
import NIO

public class SftpPacketEncoder: MessageToByteEncoder {
	public typealias OutboundIn = Packet

	public enum EncoderError: Error, Equatable {
		case failedToSerialize(message: String)
	}

	let serializer: PacketSerializer

	public init(serializer: PacketSerializer) {
		self.serializer = serializer
	}

	public func encode(data: OutboundIn, out: inout ByteBuffer) throws {
		let originalWriterIndex = out.writerIndex

		switch serializer.serialize(packet: data, to: &out) {
		case .none:
			return
		case let .some(error):
			out.moveWriterIndex(to: originalWriterIndex)
			throw EncoderError.failedToSerialize(message: String(describing: error))
		}
	}
}
