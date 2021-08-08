import Foundation
import NIO

extension BaseSftpServer {
	public func handleLinkStatus(
		packet: LinkStatusPacket,
		on _: EventLoop,
		using replyHandler: @escaping ReplyHandler
	) -> EventLoopFuture<Void> {
		logger.debug("[\(packet.id)] Handling link status packet: \(packet)")

		var statResult: stat = stat()
		do {
			try withUnsafeMutablePointer(to: &statResult) { statResultPtr in
				try syscall {
					lstat(packet.path, statResultPtr)
				}
			}
		} catch {
			self.logger.warning("[\(packet.id)] Getting link status of path '\(packet.path)' resulted in an error: \(error)")
			let errorReply: Packet = .statusReply(StatusReplyPacket(id: packet.id, statusCode: .failure, errorMessage: "There was an error getting link status of the path '\(packet.path)': \(error)", languageTag: "en-US"))
			return replyHandler(SftpMessage(packet: errorReply, dataLength: 0, shouldReadHandler: { _ in }))
		}

		let fileAttributes = FileAttributes(stat: statResult, extensionData: [])

		let successReply: Packet = .attributesReply(.init(id: packet.id, fileAttributes: fileAttributes))
		return replyHandler(SftpMessage(packet: successReply, dataLength: 0, shouldReadHandler: { _ in }))
	}
}
