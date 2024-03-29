import Foundation
import NIO

extension BaseSftpServer {
	public func handleReadDirectory(
		packet: ReadDirectoryPacket,
		on _: EventLoop,
		using replyHandler: @escaping ReplyHandler
	) -> EventLoopFuture<Void> {
		guard let sftpHandle = self.sftpFileHandles.getHandle(handleIdentifier: packet.handle) else {
			logger.warning("[\(packet.id)] The handle identifier '\(packet.handle)' was not found")
			let errorReply: Packet = .statusReply(.init(id: packet.id, statusCode: .noSuchFile, errorMessage: "The handle being read is not tracked by the server. Was it already closed?", languageTag: "en-US"))
			return replyHandler(SftpMessage(packet: errorReply, dataLength: 0, shouldReadHandler: { _ in }))
		}
		guard case let .dir(sftpDirHandle) = sftpHandle else {
			logger.warning("[\(packet.id)] The handle identifier '\(packet.handle)' was not for a file")
			let errorReply: Packet = .statusReply(.init(id: packet.id, statusCode: .noSuchFile, errorMessage: "The handle being read is not tracked by the server. Was it already closed?", languageTag: "en-US"))
			return replyHandler(SftpMessage(packet: errorReply, dataLength: 0, shouldReadHandler: { _ in }))
		}

		let dirEntity: UnsafeMutablePointer<dirent>?
		do {
			dirEntity = try syscallAcceptableNil {
				errno = 0
				return readdir(sftpDirHandle.dir)
			}
		} catch let error as IOError where error.errnoCode == EOF {
			let eofReply: Packet = .statusReply(StatusReplyPacket(id: packet.id, statusCode: .endOfFile, errorMessage: "", languageTag: "en-US"))
			return replyHandler(SftpMessage(packet: eofReply, dataLength: 0, shouldReadHandler: { _ in }))
		} catch {
			self.logger.warning("[\(packet.id)] Reading directory handle '\(packet.handle)' resulted in an error: \(error)")
			let errorReply: Packet = .statusReply(StatusReplyPacket(id: packet.id, statusCode: .failure, errorMessage: "There was an error reading the directory handle '\(packet.handle)': \(error)", languageTag: "en-US"))
			return replyHandler(SftpMessage(packet: errorReply, dataLength: 0, shouldReadHandler: { _ in }))
		}

		guard let dirEntity = dirEntity else {
			let eofReply: Packet = .statusReply(StatusReplyPacket(id: packet.id, statusCode: .endOfFile, errorMessage: "", languageTag: "en-US"))
			return replyHandler(SftpMessage(packet: eofReply, dataLength: 0, shouldReadHandler: { _ in }))
		}

		let nameString = withUnsafePointer(to: dirEntity.pointee.d_name) {
			$0.withMemoryRebound(to: UInt8.self, capacity: Int(dirEntity.pointee.d_namlen)) {
				String(cString: $0)
			}
		}

		var statResult: stat = stat()
		do {
			try withUnsafeMutablePointer(to: &statResult) { statResultPtr in
				try syscall {
					stat(sftpDirHandle.path + "/" + nameString, statResultPtr)
				}
			}
		} catch {
			self.logger.warning("[\(packet.id)] Getting file status for '\(nameString)' for directory handle '\(packet.handle)' resulted in an error: \(error)")
			let errorReply: Packet = .statusReply(StatusReplyPacket(id: packet.id, statusCode: .failure, errorMessage: "There was an error reading file status for the directory handle '\(packet.handle)': \(error)", languageTag: "en-US"))
			return replyHandler(SftpMessage(packet: errorReply, dataLength: 0, shouldReadHandler: { _ in }))
		}

		let fileAttributes = FileAttributes(stat: statResult, extensionData: [])
		let name = NameReplyPacket.Name(filename: nameString,
										longName: fileAttributes.longName(shortName: nameString),
										fileAttributes: fileAttributes)

		let successReply: Packet = .nameReply(.init(id: packet.id, names: [name]))
		return replyHandler(SftpMessage(packet: successReply, dataLength: 0, shouldReadHandler: { _ in }))
	}
}
