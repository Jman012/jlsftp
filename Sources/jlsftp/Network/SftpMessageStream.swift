import Foundation
import NIO
import Logging

public class SftpMessageStream {
	public typealias OnBackpressure = (Bool) -> Void
	public typealias Collector = (ByteBuffer) -> EventLoopFuture<Void>
	public typealias OnComplete = () -> Void

	private enum State {
		case awaitingCollector
		case collecting(collector: Collector, onComplete: () -> Void)
	}

	internal struct FutureWrapper {
		let id: Int
		let future: EventLoopFuture<Void>
	}

	public let outstandingFutureLimit: UInt
	private let onBackpressure: OnBackpressure
	private let logger: Logger

	private var state: State = .awaitingCollector
	private var nextFutureWrapperId: Int = 0
	private(set) var queuedData: CircularBuffer<ByteBuffer> = .init()
	private(set) var outstandingFutures: [FutureWrapper] = []
	private var isCompleted = false

	public init(outstandingFutureLimit: UInt, onBackpressure: @escaping OnBackpressure, logger: Logger) {
		self.outstandingFutureLimit = outstandingFutureLimit
		self.onBackpressure = onBackpressure
		self.logger = logger
	}

	public func send(buffer: ByteBuffer) {
		switch state {
		case .awaitingCollector:
			logger.trace("send(buffer:): state is awaiting, queue")
			queuedData.append(buffer)
		case let .collecting(collector: handler, onComplete: onComplete):
			logger.trace("send(buffer:): state is collecting, queue and process")
			queuedData.append(buffer)
			processQueue(handler: handler, onComplete: onComplete)
		}
	}

	public func collect(onComplete: @escaping OnComplete, handler: @escaping Collector) {
		switch state {
		case .awaitingCollector:
			logger.trace("collect(::): state is awaiting, begin collecting and processing")
			state = .collecting(collector: handler, onComplete: onComplete)
			processQueue(handler: handler, onComplete: onComplete)
		case .collecting:
			preconditionFailure("SftpMessageStream is already being handled")
		}
	}

	public func complete() {
		logger.trace("complete()")
		isCompleted = true
		if case let .collecting(collector: handler, onComplete: onComplete) = state {
			logger.trace("complete(): state is collecting, process queue")
			processQueue(handler: handler, onComplete: onComplete)
		}
	}

	private func processQueue(handler: @escaping Collector, onComplete: @escaping OnComplete) {
		logger.trace("processQueue(::)")
		while !queuedData.isEmpty && outstandingFutures.count < outstandingFutureLimit {
			let buffer = queuedData.removeFirst()
			let futureId = nextFutureWrapperId
			nextFutureWrapperId += 1
			logger.trace("processQueue(::): emptying one item from queue into futures")
			let future = handler(buffer)
			outstandingFutures.append(FutureWrapper(id: futureId, future: future))
			// This needs to be below the above append because if the future is immediately completed,
			// the future can get stuck in the queue improperly.
			_ = future.always { _ in
				self.logger.trace("processQueue(::): callback: future did complete")
				self.futureCompleted(futureId: futureId, handler: handler, onComplete: onComplete)
			}
		}

		let isFull = outstandingFutures.count == outstandingFutureLimit || !queuedData.isEmpty
		onBackpressure(!isFull)

		logger.trace("processQueue(::): isCompleted=\(isCompleted), queuedData.count=\(queuedData.count), outstandingFutures.count: \(outstandingFutures.count)")
		if isCompleted && queuedData.isEmpty && outstandingFutures.isEmpty {
			logger.trace("processQueue(::): is complete, no more queued items, no more outstanding futures. calling onComplete.")
			onComplete()
		}
	}

	private func futureCompleted(futureId: Int, handler: @escaping Collector, onComplete: @escaping OnComplete) {
		outstandingFutures.removeAll(where: { $0.id == futureId })
		processQueue(handler: handler, onComplete: onComplete)
	}
}
