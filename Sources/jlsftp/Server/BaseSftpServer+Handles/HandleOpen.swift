import Foundation
import NIO

extension BaseSftpServer {
	public func handleOpen(
		packet: OpenPacket,
		on eventLoop: EventLoop,
		using replyHandler: @escaping ReplyHandler
	) -> EventLoopFuture<Void> {
		// Prepare data
		let nfio = NonBlockingFileIO(threadPool: threadPool)
		let nioMode = NIOFileHandle.Mode(fromOpenFlags: packet.pflags)
		let nioFlagsComps = NIOFileHandle.Flags.jlsftp(permissions: packet.fileAttributes.permissions, openFlags: packet.pflags)
		let nioFlags = NIOFileHandle.Flags.posix(flags: nioFlagsComps.0, mode: nioFlagsComps.1)

		// Open the file
		logger.trace("[\(packet.id)] Opening file with mode \(nioMode), flags \(nioFlags)")
		let openFileFuture = nfio.openFile(path: packet.filename,
										   mode: nioMode,
										   flags: nioFlags,
										   eventLoop: eventLoop)

		return openFileFuture.flatMap { nioFileHandle in
			self.logger.trace("[\(packet.id)] Opened handle received: \(nioFileHandle)")

			// Create a file handle and reply to the client
			let newSftpFileHandle = OpenFileHandle(path: packet.filename, nioHandle: nioFileHandle)
			let newSftpFileHandleId = self.sftpFileHandles.insertHandle(handle: .file(newSftpFileHandle))
			let replyPacket: Packet = .handleReply(HandleReplyPacket(id: packet.id, handle: newSftpFileHandleId))
			return replyHandler(SftpMessage(packet: replyPacket, dataLength: 0, shouldReadHandler: { _ in }))
		}.flatMapError { error in
			self.logger.warning("[\(packet.id)] Opening handle resulted in an error: \(error)")
			let errorReply: Packet = .statusReply(StatusReplyPacket(id: packet.id, statusCode: .noSuchFile, errorMessage: "There was an error opening the file \(packet.filename): \(error)", languageTag: "en-US"))
			return replyHandler(SftpMessage(packet: errorReply, dataLength: 0, shouldReadHandler: { _ in }))
		}
	}
}
