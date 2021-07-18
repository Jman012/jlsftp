import Foundation
import Combine
import NIO
import NIOConcurrencyHelpers

extension Publisher {

	/**
	 A custom Combine sink that creates SwiftNIO Futures when processing inputs.
	 As Futures are created, they are stored in the sink until they are completed.
	 As Futures are completed, they are cleared from the store. If the store of
	 Futures is full, the sink uses backpressure to tell the upstream that no
	 more input values can be processed. This is handled by a non-infinite demand.
	 */
	func futureSink(
		maxConcurrent: UInt,
		eventLoop: EventLoop,
		receiveCompletion: @escaping (Subscribers.Completion<Failure>) -> Void,
		receiveValue: @escaping FutureSink<Self.Output, Self.Failure>.Handler
	) -> AnyCancellable {
		let futureSink = FutureSink(maxConcurrent: maxConcurrent,
									eventLoop: eventLoop,
									receiveCompletion: receiveCompletion,
									receiveValue: receiveValue)
		// Immediately subscribe the futureSink to this publisher.
		subscribe(futureSink)
		return AnyCancellable(futureSink)
	}
}

public class FutureSink<Input, Failure: Error>: Cancellable {

	public typealias Handler = (Input) -> EventLoopFuture<Void>

	/// The maximum number of oustanding Futures this sink can hold.
	private let maxConcurrent: UInt
	private let eventLoop: EventLoop
	/// The sink input value handler that returns a Future.
	private let receiveValue: Handler
	/// The sink completion handler.
	private let receiveCompletion: (Subscribers.Completion<Failure>) -> Void

	/// Internal tracker for outstanding Futures.
	private var currentFutures: [EventLoopFutureWrapper<Void>] = []
	private var nextFutureId: UInt = 0
	/// The subscription to the upstream publisher.
	private var subscription: Subscription?
	private var lock = NIOConcurrencyHelpers.Lock()

	/**
	 The current amount of demand for the upstream publisher, based on
	 max and current Futures.
	 */
	private var currentDemand: Subscribers.Demand {
		.max(Int(maxConcurrent) - currentFutures.count)
	}

	public init(
		maxConcurrent: UInt,
		eventLoop: EventLoop,
		receiveCompletion: @escaping (Subscribers.Completion<Failure>) -> Void,
		receiveValue: @escaping Handler
	) {
		self.maxConcurrent = maxConcurrent
		self.eventLoop = eventLoop
		self.receiveCompletion = receiveCompletion
		self.receiveValue = receiveValue
	}

	public func cancel() {
		subscription?.cancel()
	}
}

extension FutureSink: Subscriber {
	public func receive(subscription: Subscription) {
		// We've been subscribed to an upstream. Store the subscription, then
		// request the initial demand.
		self.subscription = subscription
		self.subscription?.request(currentDemand)
	}

	public func receive(_ input: Input) -> Subscribers.Demand {
		// If so, then send the input to the handler and track
		// the returned Future.
		let future = receiveValue(input)
		var wrapper: EventLoopFutureWrapper<Void>!
		lock.withLock {
			let futureId = nextFutureId
			nextFutureId &+= 1 // Ignore overflow.
			wrapper = EventLoopFutureWrapper(future: future, id: futureId)
			currentFutures.append(wrapper)
		}
		future.whenComplete { result in
			self.lock.withLock {
				// When a Future is resolved, stop tracking it
				let index = self.currentFutures.firstIndex(of: wrapper)
				self.currentFutures.remove(at: index!) // TODO
			}

			// And ask for the additional demand from upstream
			self.subscription?.request(.max(1))

			// Upon error, cancel sink
			switch result {
			case let .failure(error):
				self.receive(completion: .failure(error as! Failure)) // TODO: fix force cast somehow.
				self.cancel()
			default:
				break
			}
		}
		// No additional demand.
		return .none
	}

	public func receive(completion: Subscribers.Completion<Failure>) {
		lock.withLock {
			switch completion {
			case .finished:
				EventLoopFuture.andAllSucceed(self.currentFutures.map { $0.future }, on: self.eventLoop)
					.whenComplete { result in
						switch result {
						case .success:
							self.receiveCompletion(.finished)
						case let .failure(error):
							self.receiveCompletion(.failure(error as! Failure)) // TODO: fix force cast somehow.
						}
					}
			case let .failure(error):
				self.receiveCompletion(.failure(error))
			}
		}
	}
}

fileprivate struct EventLoopFutureWrapper<T>: Equatable {
	public let future: EventLoopFuture<T>
	public let id: UInt

	static func == (lhs: Self, rhs: Self) -> Bool {
		return lhs.id == rhs.id
	}
}
