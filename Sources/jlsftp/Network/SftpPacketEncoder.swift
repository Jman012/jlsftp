import Foundation
import NIO

public class SftpPacketEncoder: MessageToByteEncoder {
	public typealias OutboundIn = Packet

	public enum EncoderError: Error {
		case failedToSerialize
	}

	let serializer: PacketSerializer

	public init(serializer: PacketSerializer) {
		self.serializer = serializer
	}

	public func encode(data: OutboundIn, out: inout ByteBuffer) throws {
		let originalWriterIndex = out.writerIndex

		guard serializer.serialize(packet: data, to: &out) else {
			out.moveWriterIndex(to: originalWriterIndex)
			throw EncoderError.failedToSerialize
		}
	}
}
