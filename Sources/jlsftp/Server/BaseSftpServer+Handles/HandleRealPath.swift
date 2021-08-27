import Foundation
import NIO

extension BaseSftpServer {
	public func handleRealPath(
		packet: RealPathPacket,
		on _: EventLoop,
		using replyHandler: @escaping ReplyHandler
	) -> EventLoopFuture<Void> {
		let nameString: String
		do {
			let path = try syscall {
				return realpath(packet.path, nil)
			}
			if let path = path {
				nameString = String(cString: path)
				free(path)
			} else {
				nameString = ""
			}
		} catch {
			self.logger.warning("[\(packet.id)] Resolving real path of path '\(packet.path)' resulted in an error: \(error)")
			let errorReply: Packet = .statusReply(StatusReplyPacket(id: packet.id, statusCode: .failure, errorMessage: "There was an error resolving the real path of the path '\(packet.path)': \(error)", languageTag: "en-US"))
			return replyHandler(SftpMessage(packet: errorReply, dataLength: 0, shouldReadHandler: { _ in }))
		}

		let name = NameReplyPacket.Name(filename: nameString, longName: "", fileAttributes: .empty)
		let successReply: Packet = .nameReply(.init(id: packet.id, names: [name]))
		return replyHandler(SftpMessage(packet: successReply, dataLength: 0, shouldReadHandler: { _ in }))
	}
}
