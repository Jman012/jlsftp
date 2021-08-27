import Foundation
import Logging
@testable import jlsftp

extension SftpChannelHandler {
	convenience init() {
		self.init(logger: Logger(label: "test", factory: { _ in SwiftLogNoOpLogHandler() }))
	}
}
