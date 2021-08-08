import Foundation
import NIO

extension BaseSftpServer {
	public func handleSetHandleStatus(
		packet: SetHandleStatusPacket,
		on eventLoop: EventLoop,
		using replyHandler: @escaping ReplyHandler
	) -> EventLoopFuture<Void> {
		logger.debug("[\(packet.id)] Handling set handle status packet: \(packet)")

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

		do {
			if let userId = packet.fileAttributes.userId, let groupId = packet.fileAttributes.groupId {
				try sftpFileHandle.nioHandle.withUnsafeFileDescriptor { fd in
					try syscall {
						fchown(fd, userId, groupId)
					}
				}
			} else if let userId = packet.fileAttributes.userId {
				try sftpFileHandle.nioHandle.withUnsafeFileDescriptor { fd in
					try syscall {
						fchown(fd, userId, statResult.st_gid)
					}
				}
			} else if let groupId = packet.fileAttributes.groupId {
				try sftpFileHandle.nioHandle.withUnsafeFileDescriptor { fd in
					try syscall {
						fchown(fd, statResult.st_uid, groupId)
					}
				}
			}

			if let permissions = packet.fileAttributes.permissions {
				try sftpFileHandle.nioHandle.withUnsafeFileDescriptor { fd in
					try syscall {
						fchmod(fd, mode_t(fromPermissions: permissions))
					}
				}
			}

			var dates = [
				// 0: Access Time
				statResult.st_atimespec,
				// 1: Modify Time
				statResult.st_mtimespec
			]
			if let accessDate = packet.fileAttributes.accessDate {
				dates[0] = accessDate.timespec
			}
			if let modifyDate = packet.fileAttributes.modifyDate {
				dates[1] = modifyDate.timespec
			}

			try dates.withUnsafeBufferPointer { datesPtr in
				try sftpFileHandle.nioHandle.withUnsafeFileDescriptor { fd in
					try syscall {
						futimens(fd, datesPtr.baseAddress)
					}
				}
			}
		} catch {
			self.logger.warning("[\(packet.id)] Setting status of handle '\(packet.handle)' resulted in an error: \(error)")
			let errorReply: Packet = .statusReply(StatusReplyPacket(id: packet.id, statusCode: .failure, errorMessage: "There was an error setting status of the handle '\(packet.handle)': \(error)", languageTag: "en-US"))
			return replyHandler(SftpMessage(packet: errorReply, dataLength: 0, shouldReadHandler: { _ in }))
		}

		let successReply: Packet = .statusReply(.init(id: packet.id, statusCode: .ok, errorMessage: "", languageTag: "en-US"))
		return replyHandler(SftpMessage(packet: successReply, dataLength: 0, shouldReadHandler: { _ in }))
	}
}