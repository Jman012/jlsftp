import Foundation
import NIO

extension BaseSftpServer {
	public func handleClose(
		packet: ClosePacket,
		on _: EventLoop,
		using replyHandler: ReplyHandler
	) -> EventLoopFuture<Void> {
		logger.debug("[\(packet.id)] Handling close packet: \(packet)")

		guard let sftpHandle = self.sftpFileHandles.getHandle(handleIdentifier: packet.handle) else {
			logger.warning("[\(packet.id)] The handle identifier '\(packet.handle)' was not found")
			let errorReply: Packet = .statusReply(.init(id: packet.id, statusCode: .noSuchFile, errorMessage: "The handle being closed is not tracked by the server. Was it already closed?", languageTag: "en-US"))
			return replyHandler(SftpMessage(packet: errorReply, dataLength: 0, shouldReadHandler: { _ in }))
		}

		switch sftpHandle {
		case let .file(sftpFileHandle):
			do {
				try sftpFileHandle.nioHandle.close()
			} catch {
				logger.warning("[\(packet.id)] Encountered error attempting to close file handle: \(error)")
				let errorReply: Packet = .statusReply(.init(id: packet.id, statusCode: .failure, errorMessage: "Error encountered when closing file: \(error)", languageTag: "en-US"))
				return replyHandler(SftpMessage(packet: errorReply, dataLength: 0, shouldReadHandler: { _ in }))
			}
		case let .dir(sftpFileHandle):
			do {
				try syscall {
					closedir(sftpFileHandle.dir)
				}
			} catch {
				logger.warning("[\(packet.id)] Encountered error attempting to close file handle: \(error)")
				let errorReply: Packet = .statusReply(.init(id: packet.id, statusCode: .failure, errorMessage: "Error encountered when closing file: \(error)", languageTag: "en-US"))
				return replyHandler(SftpMessage(packet: errorReply, dataLength: 0, shouldReadHandler: { _ in }))
			}
		}

		_ = self.sftpFileHandles.removeHandle(handleIdentifier: packet.handle)

		let successReply: Packet = .statusReply(.init(id: packet.id, statusCode: .ok, errorMessage: "", languageTag: "en-US"))
		return replyHandler(SftpMessage(packet: successReply, dataLength: 0, shouldReadHandler: { _ in }))
	}
}
