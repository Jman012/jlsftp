import Foundation
import NIO

extension BaseSftpServer {
	public func handleOpenDirectory(
		packet: OpenDirectoryPacket,
		on _: EventLoop,
		using replyHandler: @escaping ReplyHandler
	) -> EventLoopFuture<Void> {
		let dir: UnsafeMutablePointer<DIR>!
		do {
			dir = try syscall {
				opendir(packet.path)
			}
		} catch {
			self.logger.warning("[\(packet.id)] Opening directory '\(packet.path)' resulted in an error: \(error)")
			let errorReply: Packet = .statusReply(StatusReplyPacket(id: packet.id, statusCode: .failure, errorMessage: "There was an error opening the directory '\(packet.path)': \(error)", languageTag: "en-US"))
			return replyHandler(SftpMessage(packet: errorReply, dataLength: 0, shouldReadHandler: { _ in }))
		}

		let newSftpDirHandle = OpenDirHandle(path: packet.path, dir: dir)
		let newSftpFileHandleId = self.sftpFileHandles.insertHandle(handle: .dir(newSftpDirHandle))

		let successReply: Packet = .handleReply(.init(id: packet.id, handle: newSftpFileHandleId))
		return replyHandler(SftpMessage(packet: successReply, dataLength: 0, shouldReadHandler: { _ in }))
	}
}
