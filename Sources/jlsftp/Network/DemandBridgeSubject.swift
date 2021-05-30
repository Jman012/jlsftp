import Foundation
import Combine

public class DemandBridgeSubject<Output, Failure: Error>: Subject {

	/// Indicates to the external component whether or not to send values to th subject.
	public typealias DemandHandler = (Bool) -> Void
	private let handler: DemandHandler
	private var downstreamSubscription: Subscription<Output, Failure>?

	public init(handler: @escaping DemandHandler) {
		self.handler = handler
	}

	// MARK: Subject Implementation

	public func send(_ value: Output) {
		// Ensure we're only sending a value if there is demand for it.
		precondition(downstreamSubscription != nil)
		precondition(downstreamSubscription!.demand > .none)
		// Send the value and adjust the demand.
		downstreamSubscription!.demand -= 1
		downstreamSubscription!.demand += downstreamSubscription!.downstream?.receive(value) ?? .none

		// If demand has dropped to 0, alert the handler to stop sending values.
		if downstreamSubscription!.demand == .none {
			downstreamSubscription!.handler(false)
		}
	}

	public func send(completion: Subscribers.Completion<Failure>) {
		downstreamSubscription?.downstream?.receive(completion: completion)
	}

	public func send(subscription _: Combine.Subscription) {}

	// MARK: Publisher Implementation

	public func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
		let subscription = Subscription(downstream: AnySubscriber<Output, Failure>(subscriber), handler: handler)
		downstreamSubscription = subscription
		subscriber.receive(subscription: subscription)
	}
}

extension DemandBridgeSubject {
	public class Subscription<Input, Failure: Error> {

		fileprivate var downstream: AnySubscriber<Input, Failure>?
		fileprivate let handler: DemandHandler

		fileprivate var demand: Subscribers.Demand = .max(0)

		public init(downstream: AnySubscriber<Input, Failure>, handler: @escaping DemandHandler) {
			self.downstream = downstream
			self.handler = handler
		}
	}
}

extension DemandBridgeSubject.Subscription: Subscription {

	public func request(_ additionalDemand: Subscribers.Demand) {
		let previousDemand = demand
		demand += additionalDemand

		// Tell the handler to begin sending data.
		if previousDemand == .none && demand > .none {
			handler(true)
		}
	}

	public func cancel() {
		downstream = nil
		handler(false)
	}
}
