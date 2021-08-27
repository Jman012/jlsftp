import Foundation
import NIO

extension BaseSftpServer {
	public func handleSetStatus(
		packet: SetStatusPacket,
		on _: EventLoop,
		using replyHandler: @escaping ReplyHandler
	) -> EventLoopFuture<Void> {
		var statResult: stat = stat()
		do {
			try withUnsafeMutablePointer(to: &statResult) { statResultPtr in
				try syscall {
					stat(packet.path, statResultPtr)
				}
			}
		} catch {
			self.logger.warning("[\(packet.id)] Getting status of path '\(packet.path)' resulted in an error: \(error)")
			let errorReply: Packet = .statusReply(StatusReplyPacket(id: packet.id, statusCode: .failure, errorMessage: "There was an error getting status of the path '\(packet.path)': \(error)", languageTag: "en-US"))
			return replyHandler(SftpMessage(packet: errorReply, dataLength: 0, shouldReadHandler: { _ in }))
		}

		do {
			let uid = packet.fileAttributes.userId ?? statResult.st_uid
			let gid = packet.fileAttributes.groupId ?? statResult.st_uid
			try syscall {
				chown(packet.path, uid, gid)
			}

			if let permissions = packet.fileAttributes.permissions {
				try syscall {
					chmod(packet.path, mode_t(fromPermissions: permissions))
				}
			}

			let dates = [
				// 0: Access Time
				packet.fileAttributes.accessDate?.timespec ?? statResult.st_atimespec,
				// 1: Modify Time
				packet.fileAttributes.modifyDate?.timespec ?? statResult.st_mtimespec,
			]
			try dates.withUnsafeBufferPointer { datesPtr in
				try syscall {
					utimensat(AT_FDCWD, packet.path, datesPtr.baseAddress, 0)
				}
			}
		} catch {
			self.logger.warning("[\(packet.id)] Setting status of path '\(packet.path)' resulted in an error: \(error)")
			let errorReply: Packet = .statusReply(StatusReplyPacket(id: packet.id, statusCode: .failure, errorMessage: "There was an error setting status of the path '\(packet.path)': \(error)", languageTag: "en-US"))
			return replyHandler(SftpMessage(packet: errorReply, dataLength: 0, shouldReadHandler: { _ in }))
		}

		let successReply: Packet = .statusReply(.init(id: packet.id, statusCode: .ok, errorMessage: "", languageTag: "en-US"))
		return replyHandler(SftpMessage(packet: successReply, dataLength: 0, shouldReadHandler: { _ in }))
	}
}
