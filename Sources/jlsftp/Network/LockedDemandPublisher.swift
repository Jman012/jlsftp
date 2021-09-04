import Foundation
import Combine
import NIO

extension Publisher {
	func demandBridge() -> LockedDemandPublisher<Self.Output, Self.Failure, Self> {
		return LockedDemandPublisher(upstream: self)
	}
}

public class LockedDemandPublisher<Output, Failure, Upstream: Publisher>: Publisher
where Output == Upstream.Output, Failure == Upstream.Failure {

	private let upstream: Upstream

	public init(upstream: Upstream) {
		self.upstream = upstream
	}

	public func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
		// First subscribe ourself to the upstream, then initiate demand.
		Swift.print("LockedDemandPublisher receiving downstream subscriber. Making operator.")
		let op = Operator(downstream: subscriber)
		upstream.subscribe(op)
		subscriber.receive(subscription: op)
	}

	public func unlock() {

	}
}

extension LockedDemandPublisher {
	public class Operator<Input, Failure, Downstream: Subscriber>
	where Input == Downstream.Input, Failure == Downstream.Failure {

		private var downstream: Downstream?

		private var downstreamDemand: Subscribers.Demand = .max(0)
		private var upstream: Subscription?
		private var locked = true

		public init(downstream: Downstream) {
			Swift.print("LockedDemandPublisher.Operator initiated with a downstream subscriber")
			self.downstream = downstream
		}

		public func unlock() {
			guard locked == true else { return }
			locked = false
			upstream?.request(downstreamDemand)
		}
	}
}

extension LockedDemandPublisher.Operator: Subscription {

	public func request(_ additionalDemand: Subscribers.Demand) {
		Swift.print("LockedDemandPublisher.Operator downstream requested \(additionalDemand) demand. Current deman = \(downstreamDemand)")

		// Our downstream is requesting more demand.
		downstreamDemand += additionalDemand

		// At the end, let upstream know of more demand
		Swift.print("LockedDemandPublisher.Operator requesting \(additionalDemand) more demand from upstream")
		upstream?.request(additionalDemand)
	}

	public func cancel() {
		downstream = nil
	}
}

extension LockedDemandPublisher.Operator: Subscriber {

	public func receive(subscription: Subscription) {
		Swift.print("LockedDemandPublisher.Operator received subscription. Requesting \(downstreamDemand) more demand from upstream")
		// After we've subscribed to upstream, request demand.
		upstream = subscription
		if !locked {
			subscription.request(downstreamDemand)
		}
	}

	public func receive(_ input: Input) -> Subscribers.Demand {
		Swift.print("LockedDemandPublisher.Operator received input: \(input)")
		if let downstream = downstream, downstreamDemand > .none {
			// Pass through to downstream if it has demand
			downstreamDemand -= 1
			Swift.print("LockedDemandPublisher.Operator downstreamDemand decreased to \(downstreamDemand)")

			return downstream.receive(input)
		} else {
			preconditionFailure()
		}
	}

	public func receive(completion: Subscribers.Completion<Failure>) {
		Swift.print("LockedDemandPublisher.Operator has received completion.")
		downstream?.receive(completion: completion)
	}
}
