import Foundation
import NIO

public class SftpServerVersioned: BaseSftpServer {

	let supportedPacketTypes: Set<jlsftp.SftpProtocol.PacketType>

	public init(version: jlsftp.SftpProtocol.SftpVersion, threadPool: NIOThreadPool) {
		supportedPacketTypes = jlsftp.SftpProtocol.PacketType.allPacketTypes(for: version)
		super.init(threadPool: threadPool)
	}

	override public func handle(message: SftpMessage, on eventLoop: EventLoop) {
		guard let packetType = message.packet.packetType else {
			// TODO: Error handle
			return
		}
		guard supportedPacketTypes.contains(packetType) else {
			// TODO: Error handle
			return
		}

		super.handle(message: message, on: eventLoop)
	}
}
