import Foundation
import Combine
import NIO

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
		receiveCompletion: @escaping (Subscribers.Completion<Failure>) -> Void,
		receiveValue: @escaping FutureSink<Self.Output, Self.Failure>.Handler
	) -> FutureSink<Self.Output, Self.Failure> {
		let futureSink = FutureSink(maxConcurrent: maxConcurrent, receiveCompletion: receiveCompletion, receiveValue: receiveValue)
		// Immediately subscribe the futureSink to this publisher.
		subscribe(futureSink)
		return futureSink
	}
}

public class FutureSink<Input, Failure: Error> {

	public typealias Handler = (Input) -> EventLoopFuture<Void>

	/// The maximum number of oustanding Futures this sink can hold.
	private let maxConcurrent: UInt
	/// The sink input value handler that returns a Future.
	private let receiveValue: Handler
	/// The sink completion handler.
	private let receiveCompletion: (Subscribers.Completion<Failure>) -> Void

	/// Internal tracker for how many Futures are current outstanding.
	private var currentConcurrent: UInt = 0
	/// The subscription to the upstream publisher.
	private var subscription: Subscription?

	/**
	 The current amount of demand for the upstream publisher, based on
	 max and current Futures.
	 */
	private var currentDemand: Subscribers.Demand {
		.max(Int(maxConcurrent - currentConcurrent))
	}

	public init(
		maxConcurrent: UInt,
		receiveCompletion: @escaping (Subscribers.Completion<Failure>) -> Void,
		receiveValue: @escaping Handler
	) {
		self.maxConcurrent = maxConcurrent
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
		currentConcurrent += 1
		receiveValue(input).whenComplete { _ in
			// When a Future is resolved, stop tracking it
			self.currentConcurrent -= 1
			// And ask for the additional demand from upstream
			self.subscription?.request(.max(1))
		}
		// No additional demand.
		return .none
	}

	public func receive(completion: Subscribers.Completion<Failure>) {
		receiveCompletion(completion)
	}
}
