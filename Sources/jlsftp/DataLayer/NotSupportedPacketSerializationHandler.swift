import Foundation
import NIO

public class NotSupportedPacketSerializationHandler: PacketSerializationHandler {

	public func deserialize(buffer _: inout ByteBuffer) -> Result<Packet, PacketSerializationHandlerError> {
		return .success(.nopDebug(NOPDebugPacket(message: "This feature is not supported.")))
	}
}
