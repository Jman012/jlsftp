import Foundation
import NIO

/**
 A `ByteToMessageDecoder` for use with SwiftNIO channel pipelines. Converts an
 incoming stream of bytes into `MessagePart`s, usually whole `Packet`s, with
 occasional body parts.

 This decoder produces a stream of `MessagePart.header(Packet)`. Occasionally,
 a packet will be followed be 1 or more `MessagePart.body(ByteBuffer)` items
 and then a single `MessagePart.end`, before returning to producing headers.
 */
public class SftpPacketDecoder: ByteToMessageDecoder {
	public typealias InboundIn = ByteBuffer
	public typealias InboundOut = MessagePart

	/// The internal state of the the `SftpPacketDecoder`.
	enum State {
		/**
		 The next call to `decode` will expect header data, and attempt to
		 deserialize a complete `Packet`, to be passed on to the channel.
		 */
		case awaitingHeader
		/**
		 The last header converted had a trailing body, specifying how large
		 the body should be. Track the remaining body size here. Once complete,
		 transition back to `awaitingHeader`.
		 */
		case readingBody(remaining: UInt32)
	}

	/**
	 * Errors that can be thrown from the `SftpPacketDecoder` which may occur
	 * due to the binary nature of the protocol.
	 */
	enum DecoderError: Error, Equatable {
		/**
		 * A packet with length 0 was encountered. Instead of treating this as a
		 * NOP, this is more likely some kind of corruption.
		 */
		case emptyPacketPossiblyCorrupt
		/**
		 * An unknown packet type was encountered along with a length that might
		 * cause an unnecessary amount of buffering. This may be malicious (or
		 * corrupt), so the connection should be killed.
		 */
		case unknownPacketTypePossiblyMalicious(packetLength: UInt32, packetTypeInt: UInt8)
		/**
		 * The deserialization of a packet lead to an error. Pass the message.
		 */
		case deserializationError(errorMessage: String)
		/**
		 * After a successful deserialization of a packet from a payload, there
		 * are leftover bytes. Strictly handle this by treating it as a protocol
		 * error. If this wasn't correctly handled, the leftover bytes could be
		 * parsed as its own packet, leading to corruption.
		 */
		case leftoverPacketBytes(mismatchLength: UInt32)

		var description: String {
			switch self {
			case .emptyPacketPossiblyCorrupt:
				return "Packet length is invalid (0). Treating as corrupted."
			case let .unknownPacketTypePossiblyMalicious(packetLength: length, packetTypeInt: type):
				return "Unknown packet type (\(type)) was sent with potentially malicious packet length (\(length))"
			case let .deserializationError(errorMessage: message):
				return "Closing connection due to unexpected error reading network stream: \(message)"
			case let .leftoverPacketBytes(mismatchLength: length):
				return "Actual packet length did not match specific length (leftover bytes: \(length))"
			}
		}
	}

	var state: State = .awaitingHeader
	let packetSerializer: PacketSerializer

	public init(packetSerializer: PacketSerializer) {
		self.packetSerializer = packetSerializer
	}

	public func decode(context: ChannelHandlerContext, buffer: inout ByteBuffer) throws -> DecodingState {
		return try decodeCentral(context: context, buffer: &buffer, isLast: false, seenEOF: false)
	}

	public func decodeLast(context: ChannelHandlerContext, buffer: inout ByteBuffer, seenEOF: Bool) throws -> DecodingState {
		return try decodeCentral(context: context, buffer: &buffer, isLast: true, seenEOF: seenEOF)
	}

	/// Handle `decode(context:buffer:)` and `decodeLast(context:buffer:)` the same way.
	func decodeCentral(context: ChannelHandlerContext, buffer: inout ByteBuffer, isLast _: Bool, seenEOF _: Bool) throws -> DecodingState {
		switch state {
		case .awaitingHeader:
			// Make a copy (copy-on-write) of the buffer and only read it
			// on success
			var bufferSlice = buffer.slice()
			let result = try decodePacketHeader(context: context, buffer: &bufferSlice)

			switch result {
			case .needMoreData:
				// The original buffer is unread, no need to reset it.
				return .needMoreData
			case .continue:
				// A packet was created, mark the buffer read from the slice
				// onto the original buffer for the next invocation.
				buffer.moveReaderIndex(forwardBy: bufferSlice.readerIndex)
				return .continue
			}
		case let .readingBody(remaining: remainingBytes):
			// Since the body is just raw data, it always succeeds.
			decodeBody(context: context, buffer: &buffer, remainingBytes: remainingBytes)
			return .continue
		}
	}

	/**
	 * Decodes the packet length and packet type information.
	 */
	func decodePacketHeader(context: ChannelHandlerContext, buffer: inout ByteBuffer) throws -> DecodingState {
		// Need at least the first 5 bytes, length + type, in order
		// to proceed.
		guard let packetLength = buffer.readInteger(endianness: .big, as: UInt32.self) else {
			return .needMoreData
		}

		if packetLength == 0 {
			// A packet with length 0 is like a NOP. While it's possible
			// that a server or client might send this, it's more likely
			// that something corrupted and we shouldn't attempt to
			// interpret the data. Fail instead.
			throw DecoderError.emptyPacketPossiblyCorrupt
		}

		guard let packetTypeInt = buffer.readInteger(endianness: .big, as: UInt8.self) else {
			return .needMoreData
		}

		let payloadLength = packetLength - 1

		guard let packetType = jlsftp.SftpProtocol.PacketType(rawValue: packetTypeInt) else {
			// It's possible that the endpoint is sending a packet type not
			// known, so we should pass it along as an unknown packet to be
			// displayed. We'll need to consume the bytes for the packet as
			// well. Malicious payloads may consume the bandwidth with giant
			// data packets, which we can handle by killing the connection
			// instead.
			if payloadLength >= 10000 {
				// Arbitrary length cutoff
				throw DecoderError.unknownPacketTypePossiblyMalicious(packetLength: packetLength, packetTypeInt: packetTypeInt)
			} else if buffer.readableBytes >= payloadLength {
				// Consume the bytes of the unknown packet, so that we can
				// potentially recover and read more legitmate packets. We
				// could add a new state so that the buffer doesn't grow so
				// large, but the cap above isn't too large for this to be a
				// problem.
				buffer.moveReaderIndex(forwardBy: Int(payloadLength))
				let result = MessagePart.header(.nopDebug(NOPDebugPacket(message: "Unknown packet type '\(packetTypeInt)'")), 0)
				context.fireChannelRead(self.wrapInboundOut(result))
				return .continue
			} else {
				return .needMoreData
			}
		}

		// Create a slice of the packet payload (everything but the type byte,
		// which is 1 byte), or capped at the buffer length. Note that
		// buffer.getSlice(at:length:) works where the at:index=0 is at the
		// writerIndex. So, this starts after our read of the length and type
		// bytes.
		let sliceSize = min(Int(clamping: payloadLength), buffer.readableBytes)
		var bufferSlice = buffer.getSlice(at: buffer.readerIndex, length: sliceSize)!

		let result = try decodePayload(context: context, buffer: &bufferSlice, payloadLength: payloadLength, packetType: packetType)

		switch result {
		case .needMoreData:
			// The original buffer is unread, no need to reset it.
			return .needMoreData
		case .continue:
			// A packet was created, mark the buffer read from the slice
			// onto the original buffer for the next invocation.
			buffer.moveReaderIndex(forwardBy: bufferSlice.readerIndex)
			return .continue
		}
	}

	/**
	 * Decodes the payload of a packet, given the length and type of the packet.
	 */
	func decodePayload(context: ChannelHandlerContext, buffer: inout ByteBuffer, payloadLength: UInt32, packetType: jlsftp.SftpProtocol.PacketType) throws -> DecodingState {
		//Make an attempt to deserialize the byte buffer into a packet.
		let packetResult = packetSerializer.deserialize(packetType: packetType, buffer: &buffer)
		let bytesRead = buffer.readerIndex

		switch packetResult {
		case let .failure(error):
			switch error {
			case .needMoreData:
				// If attempted deserialization could not complete,
				// request more data for the next execution.
				return .needMoreData
			case let .invalidData(reason: errorMessage):
				// If attempted deserialization resulted in an
				// unrecoverable error, kill the connection.
				throw DecoderError.deserializationError(errorMessage: errorMessage)
			}
		case let .success(packet):
			// Pass the packet along as the header
			let bodyBytes = payloadLength - UInt32(bytesRead)
			let message = MessagePart.header(packet, bodyBytes)
			context.fireChannelRead(self.wrapInboundOut(message))

			// And set the state accordingly
			if packetType.hasBody {
				state = .readingBody(remaining: bodyBytes)
				return .continue
			} else {
				// Ensure there are no leftover bytes in the buffer. This may
				// be corruption or malice.
				guard payloadLength == bytesRead else {
					throw DecoderError.leftoverPacketBytes(mismatchLength: payloadLength - UInt32(bytesRead))
				}
				state = .awaitingHeader
				return .continue
			}
		}
	}

	func decodeBody(context: ChannelHandlerContext, buffer: inout ByteBuffer, remainingBytes: UInt32) {
		// Consume either the entire buffer, or the last remaining bytes
		// according to the state, and pass to the channel pipeline.
		let bytesToConsume = min(Int(clamping: remainingBytes), buffer.readableBytes)
		let slice = buffer.readSlice(length: bytesToConsume)!
		context.fireChannelRead(self.wrapInboundOut(.body(slice)))

		// Set the new state based on remaining bytes
		let newRemainingBytes = remainingBytes - UInt32(bytesToConsume)
		if newRemainingBytes == 0 {
			// This was the last read. Mark the end and reset state
			context.fireChannelRead(self.wrapInboundOut(.end))
			state = .awaitingHeader
		} else {
			// Continue to wait for more body data
			state = .readingBody(remaining: newRemainingBytes)
		}
	}
}
