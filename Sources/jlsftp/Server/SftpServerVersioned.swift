import Foundation
import NIO
import Logging

public class SftpServerVersioned: BaseSftpServer {

	let supportedPacketTypes: Set<jlsftp.SftpProtocol.PacketType>

	public init(version: jlsftp.SftpProtocol.SftpVersion, threadPool: NIOThreadPool, logger: Logger) {
		supportedPacketTypes = jlsftp.SftpProtocol.PacketType.allPacketTypes(for: version)
		super.init(forVersion: version, threadPool: threadPool, logger: logger)
	}

	override public func handle(message: SftpMessage, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
		guard let replyHandler = replyHandler else {
			preconditionFailure("In order to handle incoming sftp messages, a reply handler must be setup first, or else the server can not reply to the client.")
		}

		guard let packetType = message.packet.packetType else {
			let errorReplyPacket: Packet = .statusReply(.init(id: 0 /* TODO? */, statusCode: .badMessage, errorMessage: "No-OP detected.", languageTag: "en-US"))
			return replyHandler(SftpMessage(packet: errorReplyPacket, dataLength: 0, shouldReadHandler: { _ in }))
		}
		guard supportedPacketTypes.contains(packetType) else {
			let errorReplyPacket: Packet = .statusReply(.init(id: 0 /* TODO? */, statusCode: .operationUnsupported, errorMessage: "The message is unsupported for sftp \(self.version)", languageTag: "en-US"))
			return replyHandler(SftpMessage(packet: errorReplyPacket, dataLength: 0, shouldReadHandler: { _ in }))
		}

		return super.handle(message: message, on: eventLoop)
	}
}
