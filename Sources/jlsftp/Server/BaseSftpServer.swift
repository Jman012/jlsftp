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

	public init(threadPool: NIOThreadPool) {
		self.threadPool = threadPool
	}

	public func register(replyHandler: @escaping ReplyHandler) {
		self.replyHandler = replyHandler
	}

	public func handle(message: SftpMessage, on eventLoop: EventLoop) {
		switch message.packet {
		case let .open(packet):
			handleOpen(packet: packet, on: eventLoop)
		case let .close(packet):
			handleClose(packet: packet)
		case let .write(packet):
			handleWrite(packet: packet, dataPublisher: message.data, on: eventLoop)
		default:
			break
		}
	}
}

// MARK: Request Handlers

extension BaseSftpServer {

	public func handleOpen(packet: OpenPacket, on eventLoop: EventLoop) {
		let nfio = NonBlockingFileIO(threadPool: threadPool)
		let future = nfio.openFile(path: packet.filename,
								   mode: NIOFileHandle.Mode(fromOpenFlags: packet.pflags),
								   flags: NIOFileHandle.Flags.jlsftp(fileAttributes: packet.fileAttributes, openFlags: packet.pflags),
								   eventLoop: eventLoop)
		future.whenSuccess({ nioFileHandle in
			let sftpHandle = "test"
			self.fileHandles[sftpHandle] = OpenFileHandle(path: packet.filename, handle: nioFileHandle)
			self.replyHandler?(.handleReply(HandleReplyPacket(id: packet.id, handle: sftpHandle)))
		})
		future.whenFailure({ _ in
			self.replyHandler?(.statusReply(StatusReplyPacket(id: packet.id, statusCode: .noSuchFile, errorMessage: "test", languageTag: "en-US")))
		})
	}

	public func handleClose(packet _: ClosePacket) {}

	public func handleWrite(packet _: WritePacket, dataPublisher _: AnyPublisher<ByteBuffer, Never>, on _: EventLoop) {}
}
