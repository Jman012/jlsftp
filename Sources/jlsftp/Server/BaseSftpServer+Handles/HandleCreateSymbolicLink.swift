import Foundation
import NIO

extension BaseSftpServer {
	public func handleCreateSymbolicLink(
		packet: CreateSymbolicLinkPacket,
		on _: EventLoop,
		using replyHandler: @escaping ReplyHandler
	) -> EventLoopFuture<Void> {
		do {
			try syscall {
				symlink(packet.linkPath, packet.targetPath)
			}
		} catch {
			self.logger.warning("[\(packet.id)] Creating symbolic link from '\(packet.linkPath)' to '\(packet.targetPath)' resulted in an error: \(error)")
			let errorReply: Packet = .statusReply(StatusReplyPacket(id: packet.id, statusCode: .failure, errorMessage: "There was an error creating the symbolic link from '\(packet.linkPath)' to '\(packet.targetPath)': \(error)", languageTag: "en-US"))
			return replyHandler(SftpMessage(packet: errorReply, dataLength: 0, shouldReadHandler: { _ in }))
		}

		let successReply: Packet = .statusReply(.init(id: packet.id, statusCode: .ok, errorMessage: "", languageTag: "en-US"))
		return replyHandler(SftpMessage(packet: successReply, dataLength: 0, shouldReadHandler: { _ in }))
	}
}
