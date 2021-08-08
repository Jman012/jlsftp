import Foundation
import NIO

extension BaseSftpServer {
	public func handleRename(
		packet: RenamePacket,
		on _: EventLoop,
		using replyHandler: @escaping ReplyHandler
	) -> EventLoopFuture<Void> {
		logger.debug("[\(packet.id)] Handling rename packet: \(packet)")

		do {
			try syscall {
				rename(packet.oldPath, packet.newPath)
			}
		} catch {
			self.logger.warning("[\(packet.id)] Renaming filename '\(packet.oldPath)' to '\(packet.newPath)' resulted in an error: \(error)")
			let errorReply: Packet = .statusReply(StatusReplyPacket(id: packet.id, statusCode: .failure, errorMessage: "There was an error renaming the file '\(packet.oldPath)' to '\(packet.newPath)': \(error)", languageTag: "en-US"))
			return replyHandler(SftpMessage(packet: errorReply, dataLength: 0, shouldReadHandler: { _ in }))
		}

		let successReply: Packet = .statusReply(StatusReplyPacket(id: packet.id, statusCode: .ok, errorMessage: "", languageTag: "en-US"))
		return replyHandler(SftpMessage(packet: successReply, dataLength: 0, shouldReadHandler: { _ in }))
	}
}
