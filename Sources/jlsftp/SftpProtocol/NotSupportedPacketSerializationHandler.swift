import Foundation
import NIO

public class NotSupportedPacketSerializationHandler: PacketSerializationHandler {

	public func deserialize(from _: inout ByteBuffer) -> Result<Packet, PacketDeserializationHandlerError> {
		return .success(.nopDebug(NOPDebugPacket(message: "This feature is not supported.")))
	}

	public func serialize(packet _: Packet, to _: inout ByteBuffer) -> PacketSerializationHandlerError? {
		return nil
	}
}
