import Foundation
import NIO

extension BaseSftpServer {
	public func handleRemove(
		packet: RemovePacket,
		on _: EventLoop,
		using replyHandler: @escaping ReplyHandler
	) -> EventLoopFuture<Void> {
		logger.debug("[\(packet.id)] Handling remove packet: \(packet)")

		// Call stat() on the filename to perform sanity checks later.
		var statResult: stat = stat()
		do {
			try withUnsafeMutablePointer(to: &statResult) { statResultPtr in
				try syscall {
					stat(packet.filename, statResultPtr)
				}
			}
		} catch {
			self.logger.warning("[\(packet.id)] While beginning to remove filename '\(packet.filename)', checking the filename resulted in an error: \(error)")
			let errorReply: Packet = .statusReply(StatusReplyPacket(id: packet.id, statusCode: .noSuchFile, errorMessage: "There was an error attempting to remove the file '\(packet.filename)': \(error)", languageTag: "en-US"))
			return replyHandler(SftpMessage(packet: errorReply, dataLength: 0, shouldReadHandler: { _ in }))
		}

		// Ensure the filename is a file instead of a directory in order to
		// move forward.
		if (statResult.st_mode & S_IFREG) != S_IFREG {
			self.logger.info("[\(packet.id)] Attempt to remove filename '\(packet.filename)' as a file, but it is a directory.")
			let errorReply: Packet = .statusReply(StatusReplyPacket(id: packet.id, statusCode: .failure, errorMessage: "The filename '\(packet.filename)' is a directory", languageTag: "en-US"))
			return replyHandler(SftpMessage(packet: errorReply, dataLength: 0, shouldReadHandler: { _ in }))
		}

		// Use unlink() to remove the file
		do {
			try syscall {
				unlink(packet.filename)
			}
		} catch {
			self.logger.warning("[\(packet.id)] Removing filename '\(packet.filename)' resulted in an error: \(error)")
			let errorReply: Packet = .statusReply(StatusReplyPacket(id: packet.id, statusCode: .failure, errorMessage: "There was an error removing the file '\(packet.filename)': \(error)", languageTag: "en-US"))
			return replyHandler(SftpMessage(packet: errorReply, dataLength: 0, shouldReadHandler: { _ in }))
		}

		let successReply: Packet = .statusReply(StatusReplyPacket(id: packet.id, statusCode: .ok, errorMessage: "", languageTag: "en-US"))
		return replyHandler(SftpMessage(packet: successReply, dataLength: 0, shouldReadHandler: { _ in }))
	}
}
