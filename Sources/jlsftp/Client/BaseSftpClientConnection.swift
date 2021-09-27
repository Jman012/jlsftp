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

	private func unsupportedOperation<T>() -> EventLoopFuture<T> {
		return channel.eventLoop.makeFailedFuture(SftpClientError.unsuported("This operation is unsupported for this server (using sftp version \(self.version))"))
	}

	public func status(remotePath: String) -> EventLoopFuture<String> {
		guard supportedPacketTypes.contains(.status) else {
			return unsupportedOperation()
		}

		let packet: Packet = .status(.init(id: getNextPacketId(), path: remotePath))
		let message = SftpMessage(packet: packet, dataLength: 0, shouldReadHandler: { _ in })
		let clientRequest = ClientRequest(message: message, eventLoop: channel.eventLoop)
		channel.writeAndFlush(clientRequest, promise: nil)

		return clientRequest.responseFuture.map { responseMessage in
			switch responseMessage.packet {
			case let .attributesReply(packet):
				return packet.fileAttributes.longName(shortName: remotePath)
			default:
				return "Error" // TODO:
			}
		}
	}
}
