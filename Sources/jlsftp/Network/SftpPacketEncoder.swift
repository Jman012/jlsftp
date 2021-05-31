import Foundation
import NIO

public class SftpPacketEncoder: MessageToByteEncoder {
	public typealias OutboundIn = MessagePart

	public enum EncoderError: Error, Equatable {
		case failedToSerialize(message: String)
	}

	let serializer: PacketSerializer
	let allocator: ByteBufferAllocator

	public init(serializer: PacketSerializer, allocator: ByteBufferAllocator) {
		self.serializer = serializer
		self.allocator = allocator
	}

	public func encode(data: OutboundIn, out: inout ByteBuffer) throws {
		switch data {
		case let .header(packet, bodyLength):
			// Serialize and write a packet

			// Ignore packets that aren't meant to go over the wire
			guard let packetType = packet.packetType else {
				return
			}

			// Serialize to a payload buffer, since we need to prepend it
			// correctly later
			var payloadBuffer = allocator.buffer(capacity: 1024)
			switch serializer.serialize(packet: packet, to: &payloadBuffer) {
			case .none:
				// Successful serialization. Write payload to buffer with packet information
				let packetTypeAndHeaderLength = UInt32(exactly: 1 + payloadBuffer.readableBytes)
				precondition(packetTypeAndHeaderLength != nil)
				let packetLength = UInt32(exactly: packetTypeAndHeaderLength! + bodyLength)
				precondition(packetLength != nil)
				let packetTypeInt: UInt8 = packetType.rawValue

				out.writeInteger(packetLength!, endianness: .big, as: UInt32.self)
				out.writeInteger(packetTypeInt, endianness: .big, as: UInt8.self)
				out.writeBuffer(&payloadBuffer)
				return
			case let .some(error):
				// Error serializing. Throw error.
				throw EncoderError.failedToSerialize(message: String(describing: error))
			}
		case let .body(buffer):
			// Body data. No data to prepend, just dump the contents through.
			out.writeImmutableBuffer(buffer)
		case .end:
			return
		}
	}
}
