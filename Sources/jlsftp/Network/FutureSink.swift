import Foundation
import Combine
import NIO

extension Publisher {

	func futureSink(
		maxConcurrent: UInt,
		receiveCompletion: @escaping (Subscribers.Completion<Failure>) -> Void,
		receiveValue: @escaping FutureSink<Self.Output, Self.Failure>.Handler
	) -> FutureSink<Self.Output, Self.Failure> {
		let futureSink = FutureSink(maxConcurrent: maxConcurrent, receiveCompletion: receiveCompletion, receiveValue: receiveValue)
		subscribe(futureSink)
		return futureSink
	}
}

public class FutureSink<Input, Failure: Error> {

	public typealias Handler = (Input) -> EventLoopFuture<Void>

	private let maxConcurrent: UInt
	private let receiveValue: Handler
	private let receiveCompletion: (Subscribers.Completion<Failure>) -> Void

	private var currentConcurrent: UInt = 0
	private var subscription: Subscription?

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
		self.subscription = subscription
		self.subscription?.request(currentDemand)
	}

	public func receive(_ input: Input) -> Subscribers.Demand {
		currentConcurrent += 1
		receiveValue(input).whenComplete { _ in
			self.currentConcurrent -= 1
			self.subscription?.request(.max(1))
		}
		return .none
	}

	public func receive(completion: Subscribers.Completion<Failure>) {
		receiveCompletion(completion)
	}
}
