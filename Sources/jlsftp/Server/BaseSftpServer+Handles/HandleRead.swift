import Foundation
import NIO

extension BaseSftpServer {
	public func handleRead(
		packet: ReadPacket,
		on eventLoop: EventLoop,
		using replyHandler: @escaping ReplyHandler
	) -> EventLoopFuture<Void> {
		guard let sftpHandle = self.sftpFileHandles.getHandle(handleIdentifier: packet.handle) else {
			logger.warning("[\(packet.id)] The handle identifier '\(packet.handle)' was not found")
			let errorReply: Packet = .statusReply(.init(id: packet.id, statusCode: .noSuchFile, errorMessage: "The handle being read is not tracked by the server. Was it already closed?", languageTag: "en-US"))
			return replyHandler(SftpMessage(packet: errorReply, dataLength: 0, shouldReadHandler: { _ in }))
		}
		guard case let .file(sftpFileHandle) = sftpHandle else {
			logger.warning("[\(packet.id)] The handle identifier '\(packet.handle)' was not for a file")
			let errorReply: Packet = .statusReply(.init(id: packet.id, statusCode: .noSuchFile, errorMessage: "The handle being read is not tracked by the server. Was it already closed?", languageTag: "en-US"))
			return replyHandler(SftpMessage(packet: errorReply, dataLength: 0, shouldReadHandler: { _ in }))
		}

		let nfio = NonBlockingFileIO(threadPool: threadPool)
		// First, we need the size of the file
		return nfio.readFileSize(fileHandle: sftpFileHandle.nioHandle, eventLoop: eventLoop).flatMap { size -> EventLoopFuture<Void> in
			// With the size of the file, determine if we can return a read length
			// of that which is requested, or a smaller size because we would get EOF.
			// Note: the downcast from UInt64 to UInt32 should be safe because the min
			// of UInt32.max and UInt64.max would be UInt32.max.
			var offset = packet.offset
			if packet.offset > size {
				offset = UInt64(size)
			}
			let effectiveReplyLength = UInt32(min(UInt64(packet.length), UInt64(size) - offset))
			if effectiveReplyLength < packet.length {
				self.logger.notice("[\(packet.id)] Read packet indicated read length of \(packet.length) at offset \(packet.offset), but the file only has \(size) bytes. Read operation will read only \(effectiveReplyLength) bytes instead.")
			}

			if effectiveReplyLength == 0 {
				self.logger.debug("[\(packet.id)] Read effective length is 0 bytes. Sending EOF.")
				let eof: Packet = .statusReply(.init(id: packet.id, statusCode: .endOfFile, errorMessage: "", languageTag: "en-US"))
				return replyHandler(SftpMessage(packet: eof, dataLength: 0, shouldReadHandler: { _ in }))
			}

			var shouldWrite = false
			var lastPromise: EventLoopPromise<Void>?
			let shouldReadHandler = { (should: Bool) in
				self.logger.trace("[\(packet.id)] Changed shouldWrite to \(should)")
				shouldWrite = should
				// Complete the last promise so that
				// the NIO reading continues.
				if let promise = lastPromise, shouldWrite {
					self.logger.trace("[\(packet.id)] Completing last promise to continue reading data")
					promise.completeWith(.success(()))
				}
			}
			let successMessage = SftpMessage(packet: .dataReply(.init(id: packet.id, dataLength: effectiveReplyLength)),
											 dataLength: effectiveReplyLength,
											 shouldReadHandler: shouldReadHandler)
			var overallSuccessPromise: EventLoopPromise<Void>!

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
											self.logger.trace("[\(packet.id)] This is the first chunk. Sending reply to client.")
											isFirstChunkRead = false
											overallSuccessPromise = eventLoop.makePromise()
											replyHandler(successMessage).cascade(to: overallSuccessPromise)
										}

										// Forward the data through the SftpMessage.
										_ = successMessage.sendData(buffer)
										// The shouldWrite variable should be changed
										// after the above call, if needed. If this gets
										// unset, then don't complete the promise just yet.
										if shouldWrite {
											self.logger.trace("[\(packet.id)] Shouldwrite is still true, proceeding with next read operation")
											return eventLoop.makeSucceededFuture(())
										} else {
											self.logger.trace("[\(packet.id)] Shouldwrite is now false, waiting until reading next chunk")
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
					let errorReply: Packet = .statusReply(.init(id: packet.id, statusCode: .failure, errorMessage: "Could not read from file: \(error)", languageTag: "en-US"))
					return replyHandler(SftpMessage(packet: errorReply, dataLength: 0, shouldReadHandler: { _ in }))
				}
		}.flatMapError { error in
			self.logger.warning("[\(packet.id)] Encountered error attempting to read file size of handle '\(packet.handle)' ('\(sftpFileHandle.path)'): \(error)")
			let errorReply: Packet = .statusReply(.init(id: packet.id, statusCode: .failure, errorMessage: "Could not determine size of file", languageTag: "en-US"))
			return replyHandler(SftpMessage(packet: errorReply, dataLength: 0, shouldReadHandler: { _ in }))
		}
	}
}
