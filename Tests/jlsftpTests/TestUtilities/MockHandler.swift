import Foundation
import NIO
@testable import jlsftp

class MockHandler: PacketSerializationHandler {
	var isDeserializeCalled = false
	var isSerializeCalled = false
	var serializeReturn: PacketSerializationHandlerError?

	func deserialize(from _: inout ByteBuffer) -> Result<Packet, PacketDeserializationHandlerError> {
		isDeserializeCalled = true
		return .failure(.needMoreData)
	}

	func serialize(packet _: Packet, to _: inout ByteBuffer) -> PacketSerializationHandlerError? {
		isSerializeCalled = true
		return serializeReturn
	}
}
