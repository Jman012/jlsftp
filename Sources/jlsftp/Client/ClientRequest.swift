import Foundation
import NIO

struct ClientRequest {
	let message: SftpMessage
	let promise: EventLoopPromise<SftpMessage>
	let removeOn: jlsftp.SftpProtocol.PacketType?

	init(message: SftpMessage, eventLoop: EventLoop, removeOn: jlsftp.SftpProtocol.PacketType? = nil) {
		self.init(message: message, promise: eventLoop.makePromise(), removeOn: removeOn)
	}

	init(message: SftpMessage, promise: EventLoopPromise<SftpMessage>, removeOn: jlsftp.SftpProtocol.PacketType? = nil) {
		self.message = message
		self.removeOn = removeOn
		self.promise = promise
	}

	func shouldRemove(responseMessage: SftpMessage) -> Bool {
		guard let removeOn = self.removeOn else {
			return true
		}

		return removeOn == responseMessage.packet.packetType
	}
}
