import Foundation
import NIO

class ClientRequest {
	enum RequestSendState {
		case awaiting
		case sending
		case sent
	}

	let message: SftpMessage
	let requestMessageSentPromise: EventLoopPromise<Void>
	private let responsePromise: EventLoopPromise<SftpMessage>

	var requestSendState: RequestSendState = .awaiting
	private var response: SftpMessage?

	public var responseFuture: EventLoopFuture<SftpMessage> {
		responsePromise.futureResult
	}

	convenience init(message: SftpMessage, eventLoop: EventLoop) {
		self.init(message: message, requestMessageSentPromise: eventLoop.makePromise(), responsePromise: eventLoop.makePromise())
	}

	private init(message: SftpMessage, requestMessageSentPromise: EventLoopPromise<Void>, responsePromise: EventLoopPromise<SftpMessage>) {
		self.message = message
		self.requestMessageSentPromise = requestMessageSentPromise
		self.responsePromise = responsePromise
	}

	func respond(message: SftpMessage) {
		guard response == nil else {
			preconditionFailure("A ClientRequest can not have more than one response")
		}

		response = message
		responsePromise.succeed(message)
	}

	func writeResponseData(buffer: ByteBuffer) {
		guard let response = response else {
			preconditionFailure("No response to write to")
		}

		_ = response.sendData(buffer)
	}

	func endResponseData() {
		guard let response = response else {
			preconditionFailure("No response to end")
		}

		response.completeData()
	}
}
