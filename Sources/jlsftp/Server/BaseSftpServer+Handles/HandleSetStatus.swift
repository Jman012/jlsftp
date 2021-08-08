import Foundation
import NIO

extension BaseSftpServer {
	public func handleSetStatus(
		packet: SetStatusPacket,
		on _: EventLoop,
		using replyHandler: @escaping ReplyHandler
	) -> EventLoopFuture<Void> {
		logger.debug("[\(packet.id)] Handling set status packet: \(packet)")

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
			if let userId = packet.fileAttributes.userId, let groupId = packet.fileAttributes.groupId {
				try syscall {
					chown(packet.path, userId, groupId)
				}
			} else if let userId = packet.fileAttributes.userId {
				try syscall {
					chown(packet.path, userId, statResult.st_gid)
				}
			} else if let groupId = packet.fileAttributes.groupId {
				try syscall {
					chown(packet.path, statResult.st_uid, groupId)
				}
			}

			if let permissions = packet.fileAttributes.permissions {
				try syscall {
					chmod(packet.path, mode_t(fromPermissions: permissions))
				}
			}

			var dates = [
				// 0: Access Time
				statResult.st_atimespec,
				// 1: Modify Time
				statResult.st_mtimespec,
			]
			if let accessDate = packet.fileAttributes.accessDate {
				dates[0] = accessDate.timespec
			}
			if let modifyDate = packet.fileAttributes.modifyDate {
				dates[1] = modifyDate.timespec
			}

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
