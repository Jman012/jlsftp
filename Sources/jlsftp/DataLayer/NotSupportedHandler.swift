import Foundation
import NIO

public class NotSupportedHandler: PacketSerializationHandler {

	public func deserialize(buffer _: inout ByteBuffer) -> Result<Packet, PacketSerializationHandlerError> {
		return .success(.serializationError(SerializationErrorPacket(errorMessage: "This feature is not supported.")))
	}
}
