import Foundation
import NIO

extension BaseSftpServer {
	public func handleHandleStatus(
		packet: HandleStatusPacket,
		on _: EventLoop,
		using replyHandler: @escaping ReplyHandler
	) -> EventLoopFuture<Void> {
		guard let sftpHandle = self.sftpFileHandles.getHandle(handleIdentifier: packet.handle) else {
			logger.warning("[\(packet.id)] The handle identifier '\(packet.handle)' was not found")
			let errorReply: Packet = .statusReply(.init(id: packet.id, statusCode: .noSuchFile, errorMessage: "The handle being closed is not tracked by the server. Was it already closed?", languageTag: "en-US"))
			return replyHandler(SftpMessage(packet: errorReply, dataLength: 0, shouldReadHandler: { _ in }))
		}
		guard case let .file(sftpFileHandle) = sftpHandle else {
			logger.warning("[\(packet.id)] The handle identifier '\(packet.handle)' was not for a file")
			let errorReply: Packet = .statusReply(.init(id: packet.id, statusCode: .noSuchFile, errorMessage: "The handle being closed is not tracked by the server. Was it already closed?", languageTag: "en-US"))
			return replyHandler(SftpMessage(packet: errorReply, dataLength: 0, shouldReadHandler: { _ in }))
		}

		var statResult: stat = stat()
		do {
			try withUnsafeMutablePointer(to: &statResult) { statResultPtr in
				try sftpFileHandle.nioHandle.withUnsafeFileDescriptor { fd in
					try syscall {
						fstat(fd, statResultPtr)
					}
				}
			}
		} catch {
			self.logger.warning("[\(packet.id)] Getting handle status of handle '\(packet.handle)' resulted in an error: \(error)")
			let errorReply: Packet = .statusReply(StatusReplyPacket(id: packet.id, statusCode: .failure, errorMessage: "There was an error getting handle status of the handle '\(packet.handle)': \(error)", languageTag: "en-US"))
			return replyHandler(SftpMessage(packet: errorReply, dataLength: 0, shouldReadHandler: { _ in }))
		}

		let fileAttributes = FileAttributes(stat: statResult, extensionData: [])

		let successReply: Packet = .attributesReply(.init(id: packet.id, fileAttributes: fileAttributes))
		return replyHandler(SftpMessage(packet: successReply, dataLength: 0, shouldReadHandler: { _ in }))
	}
}
