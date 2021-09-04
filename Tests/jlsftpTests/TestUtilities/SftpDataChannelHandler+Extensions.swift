import Foundation
import Logging
@testable import jlsftp

extension SftpDataChannelHandler {
	convenience init() {
		self.init(logger: Logger(label: "test", factory: { _ in SwiftLogNoOpLogHandler() }))
	}
}
