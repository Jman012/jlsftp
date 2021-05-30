import Foundation
import Logging

class CustomLogHandler: LogHandler {

	let handler: (() -> Void)?

	subscript(metadataKey _: String) -> Logger.Metadata.Value? {
		get {
			return .none
		}
		set(newValue) {

		}
	}

	var metadata: Logger.Metadata

	var logLevel: Logger.Level

	init(handler: @escaping () -> Void) {
		self.handler = handler
		metadata = .init()
		logLevel = .trace
	}

	init() {
		self.handler = nil
		metadata = .init()
		logLevel = .trace
	}

	func log(level: Logger.Level,
			 message: Logger.Message,
			 metadata: Logger.Metadata?,
			 source: String,
			 file: String,
			 function: String,
			 line: UInt) {
//		print(message)
		handler?()
	}
}
