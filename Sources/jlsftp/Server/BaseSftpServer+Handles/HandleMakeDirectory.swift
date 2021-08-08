import Foundation
import NIO

extension BaseSftpServer {
	public func handleMakeDirectory(
		packet: MakeDirectoryPacket,
		on _: EventLoop,
		using replyHandler: @escaping ReplyHandler
	) -> EventLoopFuture<Void> {
		logger.debug("[\(packet.id)] Handling make directory packet: \(packet)")

		let defaultPerms = Permissions(user: [.read, .write, .execute],
									   group: [.read, .execute],
									   other: [.read, .execute],
									   mode: [])
		let perms = packet.fileAttributes.permissions ?? defaultPerms
		do {
			try syscall {
				mkdir(packet.path, mode_t(fromPermissions: perms))
			}
		} catch {
			self.logger.warning("[\(packet.id)] Making directory '\(packet.path)' resulted in an error: \(error)")
			let errorReply: Packet = .statusReply(StatusReplyPacket(id: packet.id, statusCode: .failure, errorMessage: "There was an error making the directory '\(packet.path)': \(error)", languageTag: "en-US"))
			return replyHandler(SftpMessage(packet: errorReply, dataLength: 0, shouldReadHandler: { _ in }))
		}

		let successReply: Packet = .statusReply(StatusReplyPacket(id: packet.id, statusCode: .ok, errorMessage: "", languageTag: "en-US"))
		return replyHandler(SftpMessage(packet: successReply, dataLength: 0, shouldReadHandler: { _ in }))
	}
}
