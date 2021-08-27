import Foundation
import NIO

extension BaseSftpServer {
	public func handleReadLink(
		packet: ReadLinkPacket,
		on _: EventLoop,
		using replyHandler: @escaping ReplyHandler
	) -> EventLoopFuture<Void> {
		let nameString: String
		do {
			var nameBuffer: [CChar] = .init(repeating: 0, count: 256)
			try nameBuffer.withUnsafeMutableBufferPointer { bufferPtr in
				try syscall {
					readlink(packet.path, bufferPtr.baseAddress, bufferPtr.count)
				}
			}
			nameString = String(cString: nameBuffer)
		} catch {
			self.logger.warning("[\(packet.id)] Reading link of path '\(packet.path)' resulted in an error: \(error)")
			let errorReply: Packet = .statusReply(StatusReplyPacket(id: packet.id, statusCode: .failure, errorMessage: "There was an error reading the link of the path '\(packet.path)': \(error)", languageTag: "en-US"))
			return replyHandler(SftpMessage(packet: errorReply, dataLength: 0, shouldReadHandler: { _ in }))
		}

		let name = NameReplyPacket.Name(filename: nameString, longName: "", fileAttributes: .empty)
		let successReply: Packet = .nameReply(.init(id: packet.id, names: [name]))
		return replyHandler(SftpMessage(packet: successReply, dataLength: 0, shouldReadHandler: { _ in }))
	}
}
