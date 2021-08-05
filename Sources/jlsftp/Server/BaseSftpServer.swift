import Foundation
import Combine
import NIO
import Logging

public class BaseSftpServer: SftpServer {

	public enum HandleError: Error {
		case noReplyHandlerSetup
	}

	let version: jlsftp.SftpProtocol.SftpVersion
	let threadPool: NIOThreadPool
	let logger: Logger
	let allocator = ByteBufferAllocator()

	var sftpFileHandles = SftpHandleCollection()
	var replyHandler: ReplyHandler?
	var cancellableWriteFuture: AnyCancellable?

	public init(forVersion version: jlsftp.SftpProtocol.SftpVersion, threadPool: NIOThreadPool, logger: Logger) {
		self.threadPool = threadPool
		self.version = version
		self.logger = logger
	}

	public func register(replyHandler: @escaping ReplyHandler) {
		self.replyHandler = replyHandler
	}

	public func handle(message: SftpMessage, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
		guard let replyHandler = replyHandler else {
			logger.error("Handle was called without a registered reply handler.")
			return eventLoop.makeFailedFuture(HandleError.noReplyHandlerSetup)
		}

		let operationNotSupported: (UInt32) -> EventLoopFuture<Void> = { id in
			let statusReply: Packet = .statusReply(.init(id: id, statusCode: .operationUnsupported, errorMessage: "The operation is not supported", languageTag: "en-US"))
			return replyHandler(SftpMessage(packet: statusReply, dataLength: 0, shouldReadHandler: { _ in }))
		}

		switch message.packet {
		case .initializeV3:
			return operationNotSupported(0)
		case .initializeV4:
			return operationNotSupported(0)
		case .version:
			return operationNotSupported(0)
		case let .open(packet):
			return handleOpen(packet: packet, on: eventLoop, using: replyHandler)
		case let .close(packet):
			return handleClose(packet: packet, on: eventLoop, using: replyHandler)
		case let .read(packet):
			return handleRead(packet: packet, on: eventLoop, using: replyHandler)
		case let .write(packet):
			return handleWrite(packet: packet, dataPublisher: message.data, on: eventLoop, using: replyHandler)
		case let .linkStatus(packet):
			return operationNotSupported(packet.id)
		case let .handleStatus(packet):
			return operationNotSupported(packet.id)
		case let .setStatus(packet):
			return operationNotSupported(packet.id)
		case let .setHandleStatus(packet):
			return operationNotSupported(packet.id)
		case let .openDirectory(packet):
			return operationNotSupported(packet.id)
		case let .readDirectory(packet):
			return operationNotSupported(packet.id)
		case let .remove(packet):
			return handleRemove(packet: packet, on: eventLoop, using: replyHandler)
		case let .makeDirectory(packet):
			return operationNotSupported(packet.id)
		case let .removeDirectory(packet):
			return operationNotSupported(packet.id)
		case let .realPath(packet):
			return operationNotSupported(packet.id)
		case let .status(packet):
			return operationNotSupported(packet.id)
		case let .rename(packet):
			return handleRename(packet: packet, on: eventLoop, using: replyHandler)
		case let .readLink(packet):
			return operationNotSupported(packet.id)
		case let .createSymbolicLink(packet):
			return operationNotSupported(packet.id)
		case let .statusReply(packet):
			return operationNotSupported(packet.id)
		case let .handleReply(packet):
			return operationNotSupported(packet.id)
		case let .dataReply(packet):
			return operationNotSupported(packet.id)
		case let .nameReply(packet):
			return operationNotSupported(packet.id)
		case let .attributesReply(packet):
			return operationNotSupported(packet.id)
		case let .extended(packet):
			return operationNotSupported(packet.id)
		case let .extendedReply(packet):
			return operationNotSupported(packet.id)
		case .nopDebug:
			return operationNotSupported(0)
		}
	}
}
