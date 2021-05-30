import Foundation
import Combine
import NIO

extension Publisher {

	/**
	 Allows incoming data to be buffered in memory in the Combine chain upon
	 backpressure. Stores up to a set amount of inputs when downstream demand
	 is zero. When the buffer is full, it exerts back pressure further up
	 the chain.
	 */
	func bufferedData(bufferSize: UInt) -> BufferedDataPublisher<Self.Output, Self.Failure, Self> {
		return BufferedDataPublisher(upstream: self, bufferSize: bufferSize)
	}
}

public class BufferedDataPublisher<Output, Failure, Upstream: Publisher>: Publisher
	where Output == Upstream.Output, Failure == Upstream.Failure {

	/// The number of buffered items to store
	private let bufferSize: UInt
	private let upstream: Upstream

	public init(upstream: Upstream, bufferSize: UInt) {
		self.upstream = upstream
		self.bufferSize = bufferSize
	}

	public func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
		// First subscribe ourself to the upstream, then initiate demand.
		let op = Operator(downstream: subscriber, bufferSize: bufferSize)
		upstream.subscribe(op)
		subscriber.receive(subscription: op)
	}
}

extension BufferedDataPublisher {
	public class Operator<Input, Failure, Downstream: Subscriber>
		where Input == Downstream.Input, Failure == Downstream.Failure {

		private var downstream: Downstream?
		private var buffer: CircularBuffer<Input>
		/// CircularBuffer grows and uses power of 2 for capacity, not the original.
		private var bufferCapacity: Int

		private var downstreamDemand: Subscribers.Demand = .max(0)
		private var upstream: Subscription?

		private var upstreamDemand: Subscribers.Demand {
			return downstreamDemand + (bufferCapacity - buffer.count)
		}

		public init(downstream: Downstream, bufferSize: UInt) {
			self.downstream = downstream
			self.buffer = CircularBuffer<Input>(initialCapacity: Int(bufferSize))
			self.bufferCapacity = Int(bufferSize)
		}
	}
}

extension BufferedDataPublisher.Operator: Subscription {

	public func request(_ additionalDemand: Subscribers.Demand) {

		// Our downstream is requesting more demand.
		downstreamDemand += additionalDemand

		// Immediately fulfill the demand that we can from the buffer, if
		// there is any buffer.
		var bufferItemsPopped = 0
		while let downstream = downstream, let input = buffer.first, downstreamDemand > .none && !buffer.isEmpty {
			downstreamDemand += downstream.receive(input)
			_ = buffer.popFirst()
			downstreamDemand -= 1
			bufferItemsPopped += 1
		}

		// At the end, let upstream know of more demand
		upstream?.request(additionalDemand)
	}

	public func cancel() {
		downstream = nil
	}
}

extension BufferedDataPublisher.Operator: Subscriber {

	public func receive(subscription: Subscription) {
		// After we've subscribed to upstream, request demand.
		upstream = subscription
		subscription.request(upstreamDemand)
	}

	public func receive(_ input: Input) -> Subscribers.Demand {
		// We should only be receiving input if we have demand.
		let bufferOpenCapacity = bufferCapacity - buffer.count
		precondition(bufferOpenCapacity > 0, "A value was sent when there was no demand.")

		if let downstream = downstream, downstreamDemand > .none {
			// Pass through to downstream if it has demand
			downstreamDemand -= 1
			return downstream.receive(input)
		} else {
			// Store in buffer until we have a downstream,
			// or the downstream has demand
			buffer.append(input)
			return .none
		}
	}

	public func receive(completion: Subscribers.Completion<Failure>) {
		downstream?.receive(completion: completion)
	}
}
