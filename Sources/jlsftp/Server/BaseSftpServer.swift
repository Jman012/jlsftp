import Foundation
import Combine
import NIO

class OpenFileHandle {
	let path: String
	let handle: NIOFileHandle
	init(path: String, handle: NIOFileHandle) {
		self.path = path
		self.handle = handle
	}
}

public class BaseSftpServer: SftpServer {

	let threadPool: NIOThreadPool

	var fileHandles: [String: OpenFileHandle] = [:]
	var replyHandler: ReplyHandler?
	let version: jlsftp.SftpProtocol.SftpVersion

	public init(forVersion version: jlsftp.SftpProtocol.SftpVersion, threadPool: NIOThreadPool) {
		self.threadPool = threadPool
		self.version = version
	}

	public func register(replyHandler: @escaping ReplyHandler) {
		self.replyHandler = replyHandler
	}

	public func handle(message: SftpMessage, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
		guard let replyHandler = replyHandler else {
			preconditionFailure("In order to handle incoming sftp messages, a reply handler must be setup first, or else the server can not reply to the client.")
		}

		switch message.packet {
		case let .open(packet):
			return handleOpen(packet: packet, on: eventLoop, using: replyHandler)
		case let .close(packet):
			return handleClose(packet: packet, on: eventLoop, using: replyHandler)
		case let .write(packet):
			return handleWrite(packet: packet, dataPublisher: message.data, on: eventLoop, using: replyHandler)
		default:
			preconditionFailure() // TODO: Complete all packet handlers above, and remove default case.
		}
	}
}

// MARK: Request Handlers

extension BaseSftpServer {

	public func handleOpen(packet: OpenPacket, on eventLoop: EventLoop, using replyHandler: @escaping ReplyHandler) -> EventLoopFuture<Void> {
		// Prepare data
		let nfio = NonBlockingFileIO(threadPool: threadPool)
		let nioMode = NIOFileHandle.Mode(fromOpenFlags: packet.pflags)
		let nioFlags = NIOFileHandle.Flags.jlsftp(permissions: packet.fileAttributes.permissions, openFlags: packet.pflags)

		// Open the file
		let openFileFuture = nfio.openFile(path: packet.filename,
										   mode: nioMode,
										   flags: nioFlags,
										   eventLoop: eventLoop)

		return openFileFuture.flatMap { nioFileHandle in
			// Create a file handle and reply to the client
			let sftpHandle = "test"
			self.fileHandles[sftpHandle] = OpenFileHandle(path: packet.filename, handle: nioFileHandle)
			let replyPacket: Packet = .handleReply(HandleReplyPacket(id: packet.id, handle: sftpHandle))
			return replyHandler(SftpMessage(packet: replyPacket, dataLength: 0, shouldReadHandler: { _ in }))
		}.flatMapError { _ in
			let errorReply: Packet = .statusReply(StatusReplyPacket(id: packet.id, statusCode: .noSuchFile, errorMessage: "test", languageTag: "en-US"))
			return replyHandler(SftpMessage(packet: errorReply, dataLength: 0, shouldReadHandler: { _ in }))
		}

//		openFileFuture.whenSuccess({ nioFileHandle in
//			let sftpHandle = "test"
//			self.fileHandles[sftpHandle] = OpenFileHandle(path: packet.filename, handle: nioFileHandle)
//			let replyPacket: Packet = .handleReply(HandleReplyPacket(id: packet.id, handle: sftpHandle))
//			_ = self.replyHandler?(SftpMessage(packet: replyPacket, dataLength: 0, shouldReadHandler: { _ in }))
//		})
//		openFileFuture.whenFailure({ _ in
//			_ = self.replyHandler?(SftpMessage(packet: .statusReply(StatusReplyPacket(id: packet.id, statusCode: .noSuchFile, errorMessage: "test", languageTag: "en-US")), dataLength: 0, shouldReadHandler: { _ in }))
//		})
	}

	public func handleClose(packet _: ClosePacket, on eventLoop: EventLoop, using _: ReplyHandler) -> EventLoopFuture<Void> {
		return eventLoop.makeSucceededFuture(())
	}

	public func handleWrite(packet _: WritePacket, dataPublisher _: AnyPublisher<ByteBuffer, Never>, on eventLoop: EventLoop, using _: ReplyHandler) -> EventLoopFuture<Void> {
		return eventLoop.makeSucceededFuture(())
	}
}
