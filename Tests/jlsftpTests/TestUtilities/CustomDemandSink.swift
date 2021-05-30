import Foundation
import Combine

class CustomDemandSink<Input, Failure: Error> {

	let initialDemand: Subscribers.Demand
	let rcvCompletion: (Subscribers.Completion<Failure>) -> ()
	let rcvValue: (Input) -> ()

	var subscription: Subscription?

	init(demand: Int, receiveCompletion: @escaping (Subscribers.Completion<Failure>) -> (), receiveValue: @escaping (Input) -> ()) {
		initialDemand = .max(demand)
		rcvCompletion = receiveCompletion
		rcvValue = receiveValue
	}

	func increaseDemand(_ demand: Int) {
		self.subscription?.request(.max(demand))
	}
}

extension CustomDemandSink: Subscriber {
	func receive(subscription: Subscription) {
		self.subscription = subscription
		subscription.request(initialDemand)
	}

	func receive(_ input: Input) -> Subscribers.Demand {
		rcvValue(input)
		return .none
	}

	func receive(completion: Subscribers.Completion<Failure>) {
		rcvCompletion(completion)
	}
}
