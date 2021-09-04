import Foundation
import Logging
@testable import jlsftp

extension SftpServerChannelHandler {
	convenience init(server: SftpServer) {
		self.init(server: server, logger: Logger(label: "test", factory: { _ in SwiftLogNoOpLogHandler() }))
	}
}
