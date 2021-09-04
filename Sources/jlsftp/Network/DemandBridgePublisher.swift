import Foundation
import Combine
import NIO

extension Publisher {
	func demandBridge(handler: @escaping DemandBridgePublisherDemandHandler) -> DemandBridgePublisher<Self.Output, Self.Failure, Self> {
		return DemandBridgePublisher(upstream: self, handler: handler)
	}
}

public typealias DemandBridgePublisherDemandHandler = (Bool) -> Void

public class DemandBridgePublisher<Output, Failure, Upstream: Publisher>: Publisher
where Output == Upstream.Output, Failure == Upstream.Failure {

	private let upstream: Upstream
	private let handler: DemandBridgePublisherDemandHandler

	public init(upstream: Upstream, handler: @escaping DemandBridgePublisherDemandHandler) {
		self.upstream = upstream
		self.handler = handler
	}

	public func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
		// First subscribe ourself to the upstream, then initiate demand.
		Swift.print("DemandBridgePublisher receiving downstream subscriber. Making operator.")
		let op = Operator(downstream: subscriber, handler: handler)
		upstream.subscribe(op)
		subscriber.receive(subscription: op)
	}
}

extension DemandBridgePublisher {
	public class Operator<Input, Failure, Downstream: Subscriber>
	where Input == Downstream.Input, Failure == Downstream.Failure {

		private var downstream: Downstream?
		private let handler: DemandBridgePublisherDemandHandler

		private var downstreamDemand: Subscribers.Demand = .max(0)
		private var upstream: Subscription?
		private var upstreamDemand: Subscribers.Demand {
			downstreamDemand
		}

		public init(downstream: Downstream, handler: @escaping DemandBridgePublisherDemandHandler) {
			Swift.print("DemandBridgePublisher.Operator initiated with a downstream subscriber")
			self.downstream = downstream
			self.handler = handler
		}
	}
}

extension DemandBridgePublisher.Operator: Subscription {

	public func request(_ additionalDemand: Subscribers.Demand) {
		Swift.print("DemandBridgePublisher.Operator downstream requested \(additionalDemand) demand. Current deman = \(downstreamDemand)")
		let previousDownstreamDemand = downstreamDemand

		// Our downstream is requesting more demand.
		downstreamDemand += additionalDemand

		// At the end, let upstream know of more demand
		Swift.print("DemandBridgePublisher.Operator requesting \(additionalDemand) more demand from upstream")
		upstream?.request(additionalDemand)

		if previousDownstreamDemand == .none && downstreamDemand > .none {
			Swift.print("DemandBridgePublisher.Operator downstreamDemand increased from none to \(additionalDemand). Enabling bridge.")
			handler(true)
		}
	}

	public func cancel() {
		downstream = nil
	}
}

extension DemandBridgePublisher.Operator: Subscriber {

	public func receive(subscription: Subscription) {
		Swift.print("DemandBridgePublisher.Operator received subscription. Requesting \(upstreamDemand) more demand from upstream")
		// After we've subscribed to upstream, request demand.
		upstream = subscription
		subscription.request(upstreamDemand)
	}

	public func receive(_ input: Input) -> Subscribers.Demand {
		Swift.print("DemandBridgePublisher.Operator received input: \(input)")
		if let downstream = downstream, downstreamDemand > .none {
			// Pass through to downstream if it has demand
			downstreamDemand -= 1
			Swift.print("DemandBridgePublisher.Operator downstreamDemand decreased to \(downstreamDemand)")

			if downstreamDemand == .none {
				Swift.print("DemandBridgePublisher.Operator downStreamDemand has reached 0. Disabling bridge.")
				handler(false)
			}

			return downstream.receive(input)
		} else {
			preconditionFailure()
		}
	}

	public func receive(completion: Subscribers.Completion<Failure>) {
		Swift.print("DemandBridgePublisher.Operator has received completion.")
		downstream?.receive(completion: completion)
	}
}
