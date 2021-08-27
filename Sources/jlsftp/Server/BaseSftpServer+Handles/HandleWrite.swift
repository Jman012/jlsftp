import Foundation
import NIO
import Combine

extension BaseSftpServer {
	public func handleWrite(
		packet: WritePacket,
		dataPublisher: AnyPublisher<ByteBuffer, Error>,
		on eventLoop: EventLoop,
		using replyHandler: @escaping ReplyHandler
	) -> EventLoopFuture<Void> {
		guard let sftpHandle = self.sftpFileHandles.getHandle(handleIdentifier: packet.handle) else {
			logger.warning("[\(packet.id)] The handle identifier '\(packet.handle)' was not found")
			let errorReply: Packet = .statusReply(.init(id: packet.id, statusCode: .noSuchFile, errorMessage: "The handle being written to is not tracked by the server. Was it already closed?", languageTag: "en-US"))
			return replyHandler(SftpMessage(packet: errorReply, dataLength: 0, shouldReadHandler: { _ in }))
		}
		guard case let .file(sftpFileHandle) = sftpHandle else {
			logger.warning("[\(packet.id)] The handle identifier '\(packet.handle)' was not for a file")
			let errorReply: Packet = .statusReply(.init(id: packet.id, statusCode: .noSuchFile, errorMessage: "The handle being written to is not tracked by the server. Was it already closed?", languageTag: "en-US"))
			return replyHandler(SftpMessage(packet: errorReply, dataLength: 0, shouldReadHandler: { _ in }))
		}

		let overallPromise: EventLoopPromise<Void> = eventLoop.makePromise()

		let nfio = NonBlockingFileIO(threadPool: threadPool)
		var currentOffset = packet.offset
		self.cancellableWriteFuture = dataPublisher.futureSink(maxConcurrent: 10, eventLoop: eventLoop, receiveCompletion: { completion in
			switch completion {
			case .finished:
//				self.logger.trace("[\(packet.id)] Writing data has completed with \(outstandingFutures.count) oustanding write futures")
//				let successReply: Packet = .statusReply(.init(id: packet.id, statusCode: .ok, errorMessage: "", languageTag: "en-US"))
//				replyHandler(SftpMessage(packet: successReply, dataLength: 0, shouldReadHandler: { _ in }))
//					.cascade(to: overallPromise)
//				self.cancellableWriteFuture = nil
//						case let .failure(error):
//							self.logger.trace("[\(packet.id)] Writing data has failed with error: \(error)")
//							let errorReply: Packet = .statusReply(.init(id: packet.id, statusCode: .failure, errorMessage: "Error encountered writing to file: \(error)", languageTag: "en-US"))
//							replyHandler(SftpMessage(packet: errorReply, dataLength: 0, shouldReadHandler: { _ in }))
//								.cascade(to: overallPromise)
//							self.cancellableWriteFuture?.cancel()
//							self.cancellableWriteFuture = nil
//						}
//					}

				self.logger.trace("[\(packet.id)] Writing data has completed")
				let successReply: Packet = .statusReply(.init(id: packet.id, statusCode: .ok, errorMessage: "", languageTag: "en-US"))
				replyHandler(SftpMessage(packet: successReply, dataLength: 0, shouldReadHandler: { _ in }))
					.cascade(to: overallPromise)
				self.cancellableWriteFuture = nil
			case let .failure(error):
				self.logger.trace("[\(packet.id)] Writing data has failed with error: \(error)")
				let errorReply: Packet = .statusReply(.init(id: packet.id, statusCode: .failure, errorMessage: "Error encountered writing to file: \(error)", languageTag: "en-US"))
				replyHandler(SftpMessage(packet: errorReply, dataLength: 0, shouldReadHandler: { _ in }))
					.cascade(to: overallPromise)
				self.cancellableWriteFuture?.cancel()
				self.cancellableWriteFuture = nil
			}

		}, receiveValue: { buffer in
			let writeOffset = currentOffset
			currentOffset += UInt64(buffer.readableBytes)
			self.logger.trace("[\(packet.id)] Queueing write to offset \(writeOffset) with \(buffer.readableBytes) bytes")
			return nfio.write(fileHandle: sftpFileHandle.nioHandle,
							  toOffset: Int64(writeOffset), // TODO: Fix potential error
							  buffer: buffer,
							  eventLoop: eventLoop).always { _ in
				self.logger.trace("[\(packet.id)] Write to offset \(writeOffset) with \(buffer.readableBytes) bytes complete")
			}
		})

		return overallPromise.futureResult
	}
}
