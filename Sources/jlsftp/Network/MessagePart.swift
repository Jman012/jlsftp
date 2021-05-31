import Foundation
import NIO

/**
 The output of `SftpPacketDecoder`.
 */
public enum MessagePart: Equatable {
	/**
	 An entire deserialized `Packet`. Depending on a packet type, a body may
	 follow.
	 This includes the total body length. This is required for both
	 serialization and deserialization/handling body length properly.
	 */
	case header(Packet, UInt32)
	/**
	 A container for a chunk of body data.
	 */
	case body(ByteBuffer)
	/**
	 Marks the end of the stream of `.body(ByteBuffer)` messages.
	 */
	case end
}
