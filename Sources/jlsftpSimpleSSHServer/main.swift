import Foundation
import NIO
import NIOSSH
import Logging
import jlsftp

class ServerUserAuth: NIOSSHServerUserAuthenticationDelegate {
	var supportedAuthenticationMethods: NIOSSHAvailableUserAuthenticationMethods = [.all]

	func requestReceived(request _: NIOSSHUserAuthenticationRequest, responsePromise: EventLoopPromise<NIOSSHUserAuthenticationOutcome>) {
		responsePromise.succeed(.success)
	}
}

let hostKey = NIOSSHPrivateKey(ed25519Key: .init()) // Random
let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
defer {
	try! eventLoopGroup.syncShutdownGracefully()
}

let threadPool = NIOThreadPool(numberOfThreads: 1)
threadPool.start()
defer {
	try! threadPool.syncShutdownGracefully()
}

let logger = Logger(label: "jlsftpSimpleSSHServer", factory: { name in
	var logHandler = StreamLogHandler.standardOutput(label: name)
	logHandler.logLevel = .debug
	return logHandler
})
let bootstrapper = SftpServerBootstrapper(
	host: "0.0.0.0",
	port: 22,
	privateKey: hostKey,
	serverUserAuthDelegate: ServerUserAuth(),
	eventLoopGroup: eventLoopGroup,
	threadPool: threadPool,
	logger: logger)

let channel = try bootstrapper.bootstrap().wait()
try channel.closeFuture.wait()
