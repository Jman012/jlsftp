import Foundation
import NIO

/**
The output of `SftpPacketDecoder`.
*/
public enum MessagePart: Equatable {
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
