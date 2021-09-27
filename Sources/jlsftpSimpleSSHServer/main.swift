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

var logger = Logger(label: "jlsftpSimpleSSHServer")
logger.logLevel = .trace
let bootstrapper = SftpServerBootstrapper(
	host: "0.0.0.0",
	port: 22,
	privateKey: hostKey,
	serverUserAuthDelegate: ServerUserAuth(),
	eventLoopGroup: eventLoopGroup,
	threadPool: threadPool,
	logger: logger)

let channel = try bootstrapper.bootstrap().wait()
logger.info("Bootstrap complete. Waiting for client connections.")
try channel.closeFuture.wait()
