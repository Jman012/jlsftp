import Foundation
import NIO

/**
 The output of `SftpPacketDecoder`.
 */
enum MessagePart: Equatable {
	/**
	 An entire deserialized `Packet`. Depending on a packet type, a body may
	 follow.
	 */
	case header(Packet)
	/**
	  A container for a chunk of body data.
	 */
	case body(ByteBuffer)
	/**
	  Marks the end of the stream of `.body(ByteBuffer)` messages.
	 */
	case end
}

/**
 A `ByteToMessageDecoder` for use with SwiftNIO channel pipelines. Converts an
 incoming stream of bytes into `MessagePart`s, usually whole `Packet`s, with
 occasional body parts.

 This decoder produces a stream of `MessagePart.header(Packet)`. Occasionally,
 a packet will be followed be 1 or more `MessagePart.body(ByteBuffer)` items
 and then a single `MessagePart.end`, before returning to producing headers.
 */
class SftpPacketDecoder: ByteToMessageDecoder {
	typealias InboundIn = ByteBuffer
	typealias InboundOut = MessagePart

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

	// Begin the decoder's state by looking for a header
	var state: State = .awaitingHeader
	let packetSerializer: PacketSerializer

	public init(packetSerializer: PacketSerializer) {
		self.packetSerializer = packetSerializer
	}

//	func decode(context: ChannelHandlerContext, buffer: inout ByteBuffer) throws -> DecodingState {
//		switch state {
//		case .awaitingHeader:
//
//			// The following operations will read on the buffer instead of get.
//			// Upon unsuccessful deserialization, this will be used to reset the
//			// buffer.
////			let originalBufferReaderIndex = buffer.readerIndex
//
//			// Need at least the first 5 bytes, length + type, in order
//			// to proceed.
//			guard let packetLength = buffer.readInteger(endianness: .big, as: UInt32.self) else {
////				buffer.moveReaderIndex(to: originalBufferReaderIndex)
//				return .needMoreData
//			}
//			if packetLength == 0 {
//				// A packet with length 0 is like a NOP. While it's possible
//				// that a server or client might send this, it's more likely
//				// that something corrupted and we shouldn't attempt to
//				// interpret the data. Fail instead.
//				let result = MessagePart.header(.serializationError(SerializationErrorPacket(errorMessage: "Packet length is invalid (0). Treating as corrupted.")))
//				// TODO: fireError?
//				context.fireChannelRead(self.wrapInboundOut(result))
//				return .continue
//			}
//			guard let packetTypeInt = buffer.readInteger(endianness: .big, as: UInt8.self) else {
////				buffer.moveReaderIndex(to: originalBufferReaderIndex)
//				return .needMoreData
//			}
//			guard let packetType = jlsftp.DataLayer.PacketType(rawValue: packetTypeInt) else {
//				// It's possible that the endpoint is sending a packet type not
//				// known, so we should pass it along as an unknown packet to be
//				// displayed. We'll need to consume the bytes for the packet as
//				// well. Malicious payloads may consume the bandwidth with giant
//				// data packets, which we can handle by killing the connection
//				// instead.
//				if packetLength > 10000 { // Arbitrary length cutoff
//					let result = MessagePart.header(.serializationError(SerializationErrorPacket(errorMessage: "Unknown packet type (\(packetTypeInt)) was sent with potentially malicious packet length.")))
//					// TODO: fireError?
//					context.fireChannelRead(self.wrapInboundOut(result))
//					return .continue
//				} else {
//					if buffer.readableBytes >= packetLength {
//						// Consume the bytes. We could add a new state so that
//						// the buffer doesn't grow so large but the cap above
//						// isn't too large.
//						// TODO: handle UInt32.maxValue correctly
//						buffer.moveReaderIndex(forwardBy: Int(packetLength))
//						let result = MessagePart.header(.serializationError(SerializationErrorPacket(errorMessage: "Unknown packet type (\(packetTypeInt))")))
//						// TODO: fireError?
//						context.fireChannelRead(self.wrapInboundOut(result))
//						return .continue
//					} else {
//						return .needMoreData
//					}
//				}
//			}
//
//			// Operate on a slice capped at the packetLength, so that the
//			// deseriliazer doesn't read too far (mainly for InitializePacketV3
//			// which relies on the packet length and not a count for extensions)
//			// but also for safety. The actual buffer's readerIndex will be
//			// moved below.
//			// Note: packetLength includes the packetType, so we subtract 1 to
//			// ignore that, and slice after the length and type fields.
//			let sliceSize = min(Int(clamping: packetLength - 1), buffer.readableBytes)
//			var packetSliceBuffer = buffer.getSlice(at: 5, length: sliceSize)!
//			let packetSliceBufferOriginalReaderIndex = packetSliceBuffer.readerIndex
//
//			// Make an attempt to deserilize the byte buffer into a packet.
//			let packetResult = packetSerializer.deserialize(packetType: packetType, buffer: &packetSliceBuffer)
//			let bytesRead = 5 + packetSliceBuffer.readerIndex - packetSliceBufferOriginalReaderIndex
//
//			switch packetResult {
//			case let .failure(error):
//				switch error {
//				case .needMoreData:
//					// If attempted deserialization could not complete,
//					// request more data for the next execution.
//					return .needMoreData
//				case let .invalidData(reason: errorMessage):
//					// If attempted deserialization resulted in an
//					// unrecoverable error, kill the connection.
//					buffer.moveReaderIndex(forwardBy: bytesRead)
//					// TODO: fireErrorCaught instead?
//					context.fireChannelRead(self.wrapInboundOut(.header(.serializationError(SerializationErrorPacket(errorMessage: "Closing connection due to unexpected error reading network stream: \(errorMessage)")))))
//					_ = context.close()
//					return .continue
//				}
//			case let .success(packet):
//				// Mark the bytes as read
//				buffer.moveReaderIndex(forwardBy: bytesRead)
//
//				// Pass the packet along as the header
//				let message = MessagePart.header(packet)
//				context.fireChannelRead(self.wrapInboundOut(message))
//
//				// And set the state accordingly
//				if packetType.hasBody {
//					// Body length = total length - header length
//					state = .readingBody(remaining: packetLength - UInt32(bytesRead))
//					return .continue
//				} else {
//					state = .awaitingHeader
//					return .continue
//				}
//			}
//
//		case let .readingBody(remaining: remainingBytes):
//			// Consume either the entire buffer, or the last remaining bytes
//			// according to the state, and pass to the channel pipeline.
//			let bytesToConsume = min(Int(clamping: remainingBytes), buffer.readableBytes)
//			let slice = buffer.readSlice(length: bytesToConsume)!
//			context.fireChannelRead(self.wrapInboundOut(.body(slice)))
//
//			// Set the new state based on remaining bytes
//			let newRemainingBytes = remainingBytes - UInt32(bytesToConsume)
//			if newRemainingBytes == 0 {
//				// This was the last read. Mark the end and reset state
//				context.fireChannelRead(self.wrapInboundOut(.end))
//				state = .awaitingHeader
//			} else {
//				// Continue to wait for more body data
//				state = .readingBody(remaining: newRemainingBytes)
//			}
//
//			return .continue
//		}
//	}

	func decode(context: ChannelHandlerContext, buffer: inout ByteBuffer) throws -> DecodingState {
		switch state {
		case .awaitingHeader:
			var bufferSlice = buffer.slice()
			let result = decodeStep1(context: context, buffer: &bufferSlice)

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

	func decodeLast(context _: ChannelHandlerContext, buffer _: inout ByteBuffer, seenEOF _: Bool) throws -> DecodingState {
		return .continue
	}

	func decodeStep1(context: ChannelHandlerContext, buffer: inout ByteBuffer) -> DecodingState {
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
			let result = MessagePart.header(.serializationError(SerializationErrorPacket(errorMessage: "Packet length is invalid (0). Treating as corrupted.")))
			// TODO: fireError?
			context.fireChannelRead(self.wrapInboundOut(result))
			return .continue
		}

		guard let packetTypeInt = buffer.readInteger(endianness: .big, as: UInt8.self) else {
			return .needMoreData
		}

		guard let packetType = jlsftp.DataLayer.PacketType(rawValue: packetTypeInt) else {
			// It's possible that the endpoint is sending a packet type not
			// known, so we should pass it along as an unknown packet to be
			// displayed. We'll need to consume the bytes for the packet as
			// well. Malicious payloads may consume the bandwidth with giant
			// data packets, which we can handle by killing the connection
			// instead.
			if packetLength > 10000 { // Arbitrary length cutoff
				let result = MessagePart.header(.serializationError(SerializationErrorPacket(errorMessage: "Unknown packet type (\(packetTypeInt)) was sent with potentially malicious packet length")))
				// TODO: fireError?
				context.fireChannelRead(self.wrapInboundOut(result))
				return .continue
			} else {
				if buffer.readableBytes >= packetLength {
					// Consume the bytes of the unknown packet, so that we can
					// potentially recover and read more legitmate packets. We
					// could add a new state so that the buffer doesn't grow so
					// large, but the cap above isn't too large for this to be a
					// problem.
					let result = MessagePart.header(.serializationError(SerializationErrorPacket(errorMessage: "Unknown packet type (\(packetTypeInt))")))
					// TODO: fireError?
					context.fireChannelRead(self.wrapInboundOut(result))
					return .continue
				} else {
					return .needMoreData
				}
			}
		}

		// Create a slice of the packet payload (everything but the type byte,
		// which is 1 byte), or capped at the buffer length. Note that
		// buffer.getSlice(at:length:) works where the at:index=0 is at the
		// writerIndex. So, this starts after our read of the length and type
		// bytes.
		let payloadLength = packetLength - 1
		let sliceSize = min(Int(clamping: payloadLength), buffer.readableBytes)
		var bufferSlice = buffer.getSlice(at: buffer.readerIndex, length: sliceSize)!

		let result = decodeStep2(context: context, buffer: &bufferSlice, payloadLength: payloadLength, packetType: packetType)

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

	func decodeStep2(context: ChannelHandlerContext, buffer: inout ByteBuffer, payloadLength: UInt32, packetType: jlsftp.DataLayer.PacketType) -> DecodingState {
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
				// TODO: fireErrorCaught instead?
				context.fireChannelRead(self.wrapInboundOut(.header(.serializationError(SerializationErrorPacket(errorMessage: "Closing connection due to unexpected error reading network stream: \(errorMessage)")))))
//				_ = context.close()
				return .continue
			}
		case let .success(packet):
			// Pass the packet along as the header
			let message = MessagePart.header(packet)
			context.fireChannelRead(self.wrapInboundOut(message))

			// And set the state accordingly
			if packetType.hasBody {
				state = .readingBody(remaining: payloadLength - UInt32(bytesRead))
				return .continue
			} else {
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
