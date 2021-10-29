import Foundation
import NIO
import NIOSSH
import Logging
import jlsftp

enum SSHClientError: Error {
	case passwordAuthenticationNotSupported
}

final class InteractivePasswordPromptDelegate: NIOSSHClientUserAuthenticationDelegate {
	private let queue: DispatchQueue

	private var username: String?

	private var password: String?

	init(username: String?, password: String?) {
		self.queue = DispatchQueue(label: "io.swiftnio.ssh.InteractivePasswordPromptDelegate")
		self.username = username
		self.password = password
	}

	func nextAuthenticationType(availableMethods: NIOSSHAvailableUserAuthenticationMethods, nextChallengePromise: EventLoopPromise<NIOSSHUserAuthenticationOffer?>) {
		guard availableMethods.contains(.password) else {
			print("Error: password auth not supported")
			nextChallengePromise.fail(SSHClientError.passwordAuthenticationNotSupported)
			return
		}

		self.queue.async {
			if self.username == nil {
				print("Username: ", terminator: "")
				self.username = readLine() ?? ""
			}

			if self.password == nil {
				#if os(Windows)
				print("Password: ", terminator: "")
				self.password = readLine() ?? ""
				#else
				self.password = String(cString: getpass("Password: "))
				#endif
			}

			nextChallengePromise.succeed(NIOSSHUserAuthenticationOffer(username: self.username!, serviceName: "", offer: .password(.init(password: self.password!))))
		}
	}
}

final class AcceptAllHostKeysDelegate: NIOSSHClientServerAuthenticationDelegate {
	func validateHostKey(hostKey _: NIOSSHPublicKey, validationCompletePromise: EventLoopPromise<Void>) {
		// Do not replicate this in your own code: validate host keys! This is a
		// choice made for expedience, not for any other reason.
		validationCompletePromise.succeed(())
	}
}

let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
defer {
	try! group.syncShutdownGracefully()
}

var logger = Logger(label: "jlsftpSimpleSSHClient")
logger.logLevel = .debug

let bootstrap = SftpClientBootstrapper(userAuthDelegate: InteractivePasswordPromptDelegate(username: nil, password: nil),
									   serverAuthDelegate: AcceptAllHostKeysDelegate(),
									   clientInitialization: SftpClientInitialization(logger: logger, versions: [.v3])!,
									   eventLoopGroup: group,
									   logger: logger)

let connection: SftpClientConnection
do {
	let channel = try bootstrap.connect(host: "127.0.0.1", port: 22).wait()
	connection = try bootstrap.clientInitialization.initialize(channel: channel).wait()
} catch {
	logger.error("Error: \(error)")
	logger.error("Localized error: \(error.localizedDescription)")
	exit(-1)
}

_ = try connection.status(remotePath: "/").always {
	switch $0 {
	case let .failure(error):
		logger.error("Error: \(error)")
	case let .success(s):
		logger.info("Success: \(s)")
	}
}.wait()

try! connection.disconnect().wait()

// Wait for the connection to close
//try childChannel.closeFuture.wait()
//let exitStatus = try! exitStatusPromise.futureResult.wait()
//try! channel.close().wait()
