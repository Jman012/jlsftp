import Foundation
import NIO

extension BaseSftpServer {
	public func handleRead(packet: ReadPacket, on eventLoop: EventLoop, using replyHandler: @escaping ReplyHandler) -> EventLoopFuture<Void> {
		logger.debug("[\(packet.id)] Handling read packet: \(packet)")

		guard let sftpFileHandle = self.sftpFileHandles.getHandle(handleIdentifier: packet.handle) else {
			logger.warning("[\(packet.id)] The handle identifier '\(packet.handle)' was not found")
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
			if effectiveReplyLength < packet.length {
				self.logger.notice("[\(packet.id)] Read packet indicated read length of \(packet.length) at offset \(packet.offset), but the file only has \(size) bytes. Read operation will read only \(effectiveReplyLength) bytes instead.")
			}
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
			// But, cascade the replyHandler future to the future that we need to
			// return now, to mark the end of the overall server handler call.
			return nfio.readChunked(fileHandle: sftpFileHandle.nioHandle,
									fromOffset: Int64(packet.offset), // TODO: Handle this cast better. Possible overflow.
									byteCount: Int(packet.length), // TODO: Handle this cast better. Possible overflow.
									allocator: self.allocator,
									eventLoop: eventLoop,
									chunkHandler: { buffer in
										self.logger.trace("[\(packet.id)] Obtained chunk of \(buffer.readableBytes) bytes")

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
					self.logger.trace("[\(packet.id)] Finished reading contents of file")
					// Finish the data and end when all the data gets written.
					successMessage.completeData()
					return overallSuccessPromise.futureResult
				}.flatMapError { error in
					self.logger.warning("[\(packet.id)] Encountered error attempting to read file contents of handle '\(packet.handle)' ('\(sftpFileHandle.path)'): \(error)")
					let errorReply: Packet = .statusReply(.init(id: packet.id, statusCode: .failure, errorMessage: "Could not read from file", languageTag: "en-US"))
					return replyHandler(SftpMessage(packet: errorReply, dataLength: 0, shouldReadHandler: { _ in }))
				}
		}.flatMapError { error in
			self.logger.warning("[\(packet.id)] Encountered error attempting to read file size of handle '\(packet.handle)' ('\(sftpFileHandle.path)'): \(error)")
			let errorReply: Packet = .statusReply(.init(id: packet.id, statusCode: .failure, errorMessage: "Could not determine size of file", languageTag: "en-US"))
			return replyHandler(SftpMessage(packet: errorReply, dataLength: 0, shouldReadHandler: { _ in }))
		}
	}
}
