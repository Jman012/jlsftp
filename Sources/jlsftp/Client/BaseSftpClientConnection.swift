import Foundation
import NIO

public class BaseSftpClientConnection: SftpClientConnection {

	public enum SftpClientError: Error {
		case unsuported(String)
	}

	public let version: jlsftp.SftpProtocol.SftpVersion
	private let supportedPacketTypes: Set<jlsftp.SftpProtocol.PacketType>
	private let channel: Channel

	private var packetId: PacketId = 0
	private var sftpHandles = SftpHandleCollection()

	public init(version: jlsftp.SftpProtocol.SftpVersion, channel: Channel) {
		self.version = version
		self.supportedPacketTypes = jlsftp.SftpProtocol.PacketType.allPacketTypes(for: self.version)
		self.channel = channel
	}

	private func getNextPacketId() -> PacketId {
		packetId += 1
		return packetId
	}

	public func openFile(remotePath: String) -> EventLoopFuture<String> {
		guard supportedPacketTypes.contains(.open) else {
			return channel.eventLoop.makeFailedFuture(SftpClientError.unsuported("This operation is unsupported for this server (using sftp version \(self.version))"))
		}

		let packet: Packet = .open(.init(id: getNextPacketId(), filename: remotePath, pflags: [.read], fileAttributes: .empty))
		let message = SftpMessage(packet: packet, dataLength: 0, shouldReadHandler: { _ in })
		let clientRequest = ClientRequest(message: message, eventLoop: channel.eventLoop)
		channel.writeAndFlush(packet, promise: nil)
		return clientRequest.promise.futureResult.map { _ in
			return "test"
		}
	}
}
