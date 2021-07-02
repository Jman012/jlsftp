import Foundation
import Combine
import NIO

public class BaseSftpServer: SftpServer {

	public enum HandleError: Error {
		case noReplyHandlerSetup
	}

	let version: jlsftp.SftpProtocol.SftpVersion
	let threadPool: NIOThreadPool
	let allocator = ByteBufferAllocator()

	var sftpFileHandles = SftpFileHandleCollection()
	var replyHandler: ReplyHandler?

	public init(forVersion version: jlsftp.SftpProtocol.SftpVersion, threadPool: NIOThreadPool) {
		self.threadPool = threadPool
		self.version = version
	}

	public func register(replyHandler: @escaping ReplyHandler) {
		self.replyHandler = replyHandler
	}

	public func handle(message: SftpMessage, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
		guard let replyHandler = replyHandler else {
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
			return operationNotSupported(packet.id)
		case let .makeDirectory(packet):
			return operationNotSupported(packet.id)
		case let .removeDirectory(packet):
			return operationNotSupported(packet.id)
		case let .realPath(packet):
			return operationNotSupported(packet.id)
		case let .status(packet):
			return operationNotSupported(packet.id)
		case let .rename(packet):
			return operationNotSupported(packet.id)
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
			let newSftpFileHandle = OpenFileHandle(path: packet.filename, nioHandle: nioFileHandle)
			let newSftpFileHandleId = self.sftpFileHandles.insertFileHandle(handle: newSftpFileHandle)
			let replyPacket: Packet = .handleReply(HandleReplyPacket(id: packet.id, handle: newSftpFileHandleId))
			return replyHandler(SftpMessage(packet: replyPacket, dataLength: 0, shouldReadHandler: { _ in }))
		}.flatMapError { error in
			let errorReply: Packet = .statusReply(StatusReplyPacket(id: packet.id, statusCode: .noSuchFile, errorMessage: "There was an error opening the file \(packet.filename): \(error)", languageTag: "en-US"))
			return replyHandler(SftpMessage(packet: errorReply, dataLength: 0, shouldReadHandler: { _ in }))
		}
	}

	public func handleClose(packet: ClosePacket, on _: EventLoop, using replyHandler: ReplyHandler) -> EventLoopFuture<Void> {
		guard let sftpFileHandle = self.sftpFileHandles.getHandle(handleIdentifier: packet.handle) else {
			let errorReply: Packet = .statusReply(.init(id: packet.id, statusCode: .noSuchFile, errorMessage: "The handle being closed is not tracked by the server. Was it already closed?", languageTag: "en-US"))
			return replyHandler(SftpMessage(packet: errorReply, dataLength: 0, shouldReadHandler: { _ in }))
		}

		do {
			try sftpFileHandle.nioHandle.close()
			_ = self.sftpFileHandles.removeHandle(handleIdentifier: packet.handle)
		} catch {
			let errorReply: Packet = .statusReply(.init(id: packet.id, statusCode: .failure, errorMessage: "Error encountered when closing file: \(error.localizedDescription)", languageTag: "en-US"))
			return replyHandler(SftpMessage(packet: errorReply, dataLength: 0, shouldReadHandler: { _ in }))
		}

		let successReply: Packet = .statusReply(.init(id: packet.id, statusCode: .ok, errorMessage: "", languageTag: "en-US"))
		return replyHandler(SftpMessage(packet: successReply, dataLength: 0, shouldReadHandler: { _ in }))
	}

	public func handleRead(packet: ReadPacket, on eventLoop: EventLoop, using replyHandler: @escaping ReplyHandler) -> EventLoopFuture<Void> {
		guard let sftpFileHandle = self.sftpFileHandles.getHandle(handleIdentifier: packet.handle) else {
			let errorReply: Packet = .statusReply(.init(id: packet.id, statusCode: .noSuchFile, errorMessage: "The handle being closed is not tracked by the server. Was it already closed?", languageTag: "en-US"))
			return replyHandler(SftpMessage(packet: errorReply, dataLength: 0, shouldReadHandler: { _ in }))
		}

		let nfio = NonBlockingFileIO(threadPool: threadPool)
		// First, we need the size of the file
		return nfio.readFileSize(fileHandle: sftpFileHandle.nioHandle, eventLoop: eventLoop).flatMap { size -> EventLoopFuture<Void> in
			// With the size of the file, determine if we can return a read length
			// of that which is requested, or a smaller size because we would get EOF.
			// Note: the downcast from UInt64 to UInt32 should be safe because the min
			// of UInt32.max and UInt64.max would be UInt32.max.
			let effectiveReplyLength = UInt32(min(UInt64(packet.length), UInt64(size) - packet.offset))
			var shouldWrite = false
			var lastPromise: EventLoopPromise<Void>?
			let shouldReadHandler = { (should: Bool) in
				shouldWrite = should
				// Complete the last promise so that
				// the NIO reading continues.
				if let promise = lastPromise, shouldWrite {
					promise.completeWith(.success(()))
				}
			}
			let successMessage = SftpMessage(packet: .dataReply(.init(id: packet.id)),
											 dataLength: effectiveReplyLength,
											 shouldReadHandler: shouldReadHandler)
			let overallSuccessPromise: EventLoopPromise<Void> = eventLoop.makePromise()

			var isFirstChunkRead = true
			// This will call the chunkHandler 0 or more times, and then complete
			// the future it returns. So, on the first chunkHandler call, we need
			// to start the replyHandler call, and start writing data to the message.
			// But, cascate the replyHandler future to the future that we need to
			// return now, to mark the end of the overall server handler call.
			return nfio.readChunked(fileHandle: sftpFileHandle.nioHandle,
									fromOffset: Int64(packet.offset), // TODO: Handle this cast better. Possible overflow.
									byteCount: Int(packet.length), // TODO: Handle this cast better. Possible overflow.
									allocator: self.allocator,
									eventLoop: eventLoop,
									chunkHandler: { buffer in
										// Begin sending the header on the first call.
										if isFirstChunkRead {
											isFirstChunkRead = false
											replyHandler(successMessage).cascade(to: overallSuccessPromise)
										}

										// Forward the data through the SftpMessage.
										_ = successMessage.sendData(buffer)
										// The shouldWrite variable should be changed
										// after the above call, if needed. If this gets
										// unset, then don't complete the promise just yet.
										if shouldWrite {
											return eventLoop.makeSucceededFuture(())
										} else {
											// Pause for now, and stop reading data until
											// this promise is succeeded by the backpressure.
											let promise: EventLoopPromise<Void> = eventLoop.makePromise()
											lastPromise = promise
											return promise.futureResult
										}
			})
				.flatMap { _ in
					// Finish the data and end when all the data gets written.
					successMessage.completeData()
					return overallSuccessPromise.futureResult
				}.flatMapError { _ in
					let errorReply: Packet = .statusReply(.init(id: packet.id, statusCode: .failure, errorMessage: "Could not read from file", languageTag: "en-US"))
					return replyHandler(SftpMessage(packet: errorReply, dataLength: 0, shouldReadHandler: { _ in }))
				}
		}.flatMapError { _ in
			let errorReply: Packet = .statusReply(.init(id: packet.id, statusCode: .failure, errorMessage: "Could not determine size of file", languageTag: "en-US"))
			return replyHandler(SftpMessage(packet: errorReply, dataLength: 0, shouldReadHandler: { _ in }))
		}
	}

	public func handleWrite(packet _: WritePacket, dataPublisher _: AnyPublisher<ByteBuffer, Never>, on eventLoop: EventLoop, using _: ReplyHandler) -> EventLoopFuture<Void> {
		return eventLoop.makeSucceededFuture(())
	}
}
