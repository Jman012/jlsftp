import XCTest
import Combine
import NIO
import Logging
@testable import jlsftp

final class SftpServerInitializationTests: XCTestCase {

	func testInvalidInit() {
		var initialization: SftpServerInitialization?
		let server = CustomSftpServer()

		var didLog = false
		let logger = Logger(label: "test", factory: { _ in CustomLogHandler(handler: { didLog = true }) })

		// Needs at least one versioned server
		didLog = false
		initialization = .init(logger: logger, versionedServers: [:])
		XCTAssert(initialization == nil)
		XCTAssertEqual(didLog, true)

		// Minimum server must be v3 for initialization
		didLog = false
		initialization = .init(logger: logger, versionedServers: [.v4: server])
		XCTAssert(initialization == nil)
		XCTAssertEqual(didLog, true)

		// Minimum server must be v3 for initialization
		didLog = false
		initialization = .init(logger: logger, versionedServers: [.v5: server])
		XCTAssert(initialization == nil)
		XCTAssertEqual(didLog, true)

		// Minimum server must be v3 for initialization
		didLog = false
		initialization = .init(logger: logger, versionedServers: [.v6: server])
		XCTAssert(initialization == nil)
		XCTAssertEqual(didLog, true)

		// Server versions must be contiguous
		didLog = false
		initialization = .init(logger: logger, versionedServers: [.v3: server, .v5: server])
		XCTAssert(initialization == nil)
		XCTAssertEqual(didLog, true)

		// Server versions must be contiguous
		didLog = false
		initialization = .init(logger: logger, versionedServers: [.v3: server, .v4: server, .v6: server])
		XCTAssert(initialization == nil)
		XCTAssertEqual(didLog, true)
	}

	func testValidInit() {
		var initialization: SftpServerInitialization?
		let server = CustomSftpServer()

		var didLog = false
		let logger = Logger(label: "test", factory: { _ in CustomLogHandler(handler: { didLog = true }) })

		// Just v3
		didLog = false
		initialization = .init(logger: logger, versionedServers: [.v3: server])
		XCTAssert(initialization != nil)
		XCTAssertEqual(didLog, false)

		// Just v3-v4
		didLog = false
		initialization = .init(logger: logger, versionedServers: [.v3: server, .v4: server])
		XCTAssert(initialization != nil)
		XCTAssertEqual(didLog, false)

		// Just v3-v5
		didLog = false
		initialization = .init(logger: logger, versionedServers: [.v3: server, .v4: server, .v5: server])
		XCTAssert(initialization != nil)
		XCTAssertEqual(didLog, false)

		// Just v3-v6
		didLog = false
		initialization = .init(logger: logger, versionedServers: [.v3: server, .v4: server, .v5: server, .v6: server])
		XCTAssert(initialization != nil)
		XCTAssertEqual(didLog, false)
	}

	func testMinimumVersion() {
		var initialization: SftpServerInitialization?
		let server = CustomSftpServer()

		let logger = Logger(label: "test", factory: { _ in CustomLogHandler() })

		initialization = .init(logger: logger, versionedServers: [.v3: server])
		XCTAssert(initialization != nil)
		XCTAssertEqual(initialization!.minimumSupportedVersion(), .v3)

		initialization = .init(logger: logger, versionedServers: [.v3: server, .v4: server])
		XCTAssert(initialization != nil)
		XCTAssertEqual(initialization!.minimumSupportedVersion(), .v3)

		initialization = .init(logger: logger, versionedServers: [.v3: server, .v4: server, .v5: server])
		XCTAssert(initialization != nil)
		XCTAssertEqual(initialization!.minimumSupportedVersion(), .v3)

		initialization = .init(logger: logger, versionedServers: [.v3: server, .v4: server, .v5: server, .v6: server])
		XCTAssert(initialization != nil)
		XCTAssertEqual(initialization!.minimumSupportedVersion(), .v3)
	}

	func testMaximumVersion() {
		var initialization: SftpServerInitialization?
		let server = CustomSftpServer()

		let logger = Logger(label: "test", factory: { _ in CustomLogHandler() })

		initialization = .init(logger: logger, versionedServers: [.v3: server])
		XCTAssert(initialization != nil)
		XCTAssertEqual(initialization!.maximumSupportedVersion(), .v3)

		initialization = .init(logger: logger, versionedServers: [.v3: server, .v4: server])
		XCTAssert(initialization != nil)
		XCTAssertEqual(initialization!.maximumSupportedVersion(), .v4)

		initialization = .init(logger: logger, versionedServers: [.v3: server, .v4: server, .v5: server])
		XCTAssert(initialization != nil)
		XCTAssertEqual(initialization!.maximumSupportedVersion(), .v5)

		initialization = .init(logger: logger, versionedServers: [.v3: server, .v4: server, .v5: server, .v6: server])
		XCTAssert(initialization != nil)
		XCTAssertEqual(initialization!.maximumSupportedVersion(), .v6)
	}

	func testRegisterReplyHandler() {
		var didRegisterReplyHandlerV3 = false, didRegisterReplyHandlerV4 = false
		let serverV3 = CustomSftpServer(registerReplyHandlerHandler: { didRegisterReplyHandlerV3 = true })
		let serverV4 = CustomSftpServer(registerReplyHandlerHandler: { didRegisterReplyHandlerV4 = true })
		let logger = Logger(label: "test", factory: { _ in CustomLogHandler() })
		let channel = EmbeddedChannel()

		let initialization = SftpServerInitialization(logger: logger, versionedServers: [.v3: serverV3, .v4: serverV4])
		XCTAssert(initialization != nil)

		initialization!.register(replyHandler: { _ in
			return channel.eventLoop.makeSucceededFuture(())
		})
		XCTAssertEqual(didRegisterReplyHandlerV3, true)
		XCTAssertEqual(didRegisterReplyHandlerV4, true)
	}

	func testInitializationVersion() {
		let channel = EmbeddedChannel()
		let completedFuture = channel.eventLoop.makeSucceededFuture(())
		let serverV3 = CustomSftpServer(handleMessageHandler: { _ in completedFuture })
		let serverV4 = CustomSftpServer(handleMessageHandler: { _ in completedFuture })
		let logger = Logger(label: "test", factory: { _ in CustomLogHandler() })
		let initV3Packet: Packet = .initializeV3(InitializePacketV3(version: .v3, extensionData: []))
		let initV4Packet: Packet = .initializeV3(InitializePacketV3(version: .v4, extensionData: []))
		let initV5Packet: Packet = .initializeV3(InitializePacketV3(version: .v5, extensionData: []))

		// V3-V4 with V3
		var initialization = SftpServerInitialization(logger: logger, versionedServers: [.v3: serverV3, .v4: serverV4])
		XCTAssert(initialization != nil)
		var lastReplyMessage: Packet?
		initialization!.register(replyHandler: {
			lastReplyMessage = $0.packet
			return channel.eventLoop.makeSucceededFuture(())
		})

		_ = initialization!.handle(message: .init(packet: initV3Packet, dataLength: 0, shouldReadHandler: { _ in }), on: channel.eventLoop)
		XCTAssertEqual(lastReplyMessage, .version(VersionPacket(version: .v3, extensionData: [])))

		// V3-V4 with V4
		lastReplyMessage = nil
		initialization = SftpServerInitialization(logger: logger, versionedServers: [.v3: serverV3, .v4: serverV4])
		initialization!.register(replyHandler: {
			lastReplyMessage = $0.packet
			return channel.eventLoop.makeSucceededFuture(())
		})

		_ = initialization!.handle(message: .init(packet: initV4Packet, dataLength: 0, shouldReadHandler: { _ in }), on: channel.eventLoop)
		XCTAssertEqual(lastReplyMessage, .version(VersionPacket(version: .v4, extensionData: [])))

		// V3-V4 with V5
		lastReplyMessage = nil
		initialization = SftpServerInitialization(logger: logger, versionedServers: [.v3: serverV3, .v4: serverV4])
		initialization!.register(replyHandler: {
			lastReplyMessage = $0.packet
			return channel.eventLoop.makeSucceededFuture(())
		})

		_ = initialization!.handle(message: .init(packet: initV5Packet, dataLength: 0, shouldReadHandler: { _ in }), on: channel.eventLoop)
		XCTAssertEqual(lastReplyMessage, .version(VersionPacket(version: .v4, extensionData: [])))
	}

	func testMultipleInitialization() {
		let channel = EmbeddedChannel()
		let completedFuture = channel.eventLoop.makeSucceededFuture(())
		let serverV3 = CustomSftpServer(handleMessageHandler: { _ in completedFuture })
		let serverV4 = CustomSftpServer(handleMessageHandler: { _ in completedFuture })
		let logger = Logger(label: "test", factory: { _ in CustomLogHandler() })
		let initV3Packet: Packet = .initializeV3(InitializePacketV3(version: .v3, extensionData: []))
		let initV4Packet: Packet = .initializeV3(InitializePacketV3(version: .v4, extensionData: []))

		// V3-V4 with V3 then V4
		let initialization = SftpServerInitialization(logger: logger, versionedServers: [.v3: serverV3, .v4: serverV4])
		XCTAssert(initialization != nil)
		var lastReplyMessage: Packet?
		initialization!.register(replyHandler: {
			lastReplyMessage = $0.packet
			return channel.eventLoop.makeSucceededFuture(())
		})

		_ = initialization!.handle(message: .init(packet: initV3Packet, dataLength: 0, shouldReadHandler: { _ in }), on: channel.eventLoop)
		XCTAssertEqual(lastReplyMessage, .version(VersionPacket(version: .v3, extensionData: [])))

		lastReplyMessage = nil
		_ = initialization!.handle(message: .init(packet: initV4Packet, dataLength: 0, shouldReadHandler: { _ in }), on: channel.eventLoop)
		XCTAssertEqual(lastReplyMessage, nil)
	}

	func testValid() {
		let channel = EmbeddedChannel()
		let completedFuture = channel.eventLoop.makeSucceededFuture(())
		var didHandleMessageV3 = false, didHandleMessageV4 = false
		var lastReplyMessage: Packet?
		let serverV3 = CustomSftpServer(handleMessageHandler: { _ in
			didHandleMessageV3 = true
			return completedFuture
		})
		let serverV4 = CustomSftpServer(handleMessageHandler: { _ in
			didHandleMessageV4 = true
			return completedFuture
		})
		let logger = Logger(label: "test", factory: { _ in CustomLogHandler() })
		let initV3Packet: Packet = .initializeV3(InitializePacketV3(version: .v3, extensionData: []))
		let initV4Packet: Packet = .initializeV3(InitializePacketV3(version: .v4, extensionData: []))
		let initV5Packet: Packet = .initializeV3(InitializePacketV3(version: .v5, extensionData: []))
		let regularPacket: Packet = .status(.init(id: 1, path: "test"))

		// V3-V4 with V3
		var initialization = SftpServerInitialization(logger: logger, versionedServers: [.v3: serverV3, .v4: serverV4])
		XCTAssert(initialization != nil)
		XCTAssertEqual(didHandleMessageV3, false)
		XCTAssertEqual(didHandleMessageV4, false)
		XCTAssert(lastReplyMessage == nil)

		initialization!.register(replyHandler: {
			lastReplyMessage = $0.packet
			return channel.eventLoop.makeSucceededFuture(())
		})
		_ = initialization!.handle(message: .init(packet: initV3Packet, dataLength: 0, shouldReadHandler: { _ in }), on: channel.eventLoop)
		XCTAssertEqual(didHandleMessageV3, false)
		XCTAssertEqual(didHandleMessageV4, false)
		XCTAssertEqual(lastReplyMessage, .version(.init(version: .v3, extensionData: [])))

		_ = initialization!.handle(message: .init(packet: regularPacket, dataLength: 0, shouldReadHandler: { _ in }), on: channel.eventLoop)
		XCTAssertEqual(didHandleMessageV3, true)
		XCTAssertEqual(didHandleMessageV4, false)

		// V3-V4 with V4
		didHandleMessageV3 = false
		didHandleMessageV4 = false
		lastReplyMessage = nil
		initialization = SftpServerInitialization(logger: logger, versionedServers: [.v3: serverV3, .v4: serverV4])
		XCTAssertEqual(didHandleMessageV3, false)
		XCTAssertEqual(didHandleMessageV4, false)
		XCTAssert(lastReplyMessage == nil)

		initialization!.register(replyHandler: {
			lastReplyMessage = $0.packet
			return channel.eventLoop.makeSucceededFuture(())
		})
		_ = initialization!.handle(message: .init(packet: initV4Packet, dataLength: 0, shouldReadHandler: { _ in }), on: channel.eventLoop)
		XCTAssertEqual(didHandleMessageV3, false)
		XCTAssertEqual(didHandleMessageV4, false)
		XCTAssertEqual(lastReplyMessage, .version(.init(version: .v4, extensionData: [])))

		_ = initialization!.handle(message: .init(packet: regularPacket, dataLength: 0, shouldReadHandler: { _ in }), on: channel.eventLoop)
		XCTAssertEqual(didHandleMessageV3, false)
		XCTAssertEqual(didHandleMessageV4, true)

		// V3-V4 with V5
		didHandleMessageV3 = false
		didHandleMessageV4 = false
		lastReplyMessage = nil
		initialization = SftpServerInitialization(logger: logger, versionedServers: [.v3: serverV3, .v4: serverV4])
		XCTAssertEqual(didHandleMessageV3, false)
		XCTAssertEqual(didHandleMessageV4, false)
		XCTAssert(lastReplyMessage == nil)

		initialization!.register(replyHandler: {
			lastReplyMessage = $0.packet
			return channel.eventLoop.makeSucceededFuture(())
		})
		_ = initialization!.handle(message: .init(packet: initV5Packet, dataLength: 0, shouldReadHandler: { _ in }), on: channel.eventLoop)
		XCTAssertEqual(didHandleMessageV3, false)
		XCTAssertEqual(didHandleMessageV4, false)
		XCTAssertEqual(lastReplyMessage, .version(.init(version: .v4, extensionData: [])))

		_ = initialization!.handle(message: .init(packet: regularPacket, dataLength: 0, shouldReadHandler: { _ in }), on: channel.eventLoop)
		XCTAssertEqual(didHandleMessageV3, false)
		XCTAssertEqual(didHandleMessageV4, true)
	}

	static var allTests = [
		("testInvalidInit", testInvalidInit),
		("testValidInit", testValidInit),
		("testMinimumVersion", testMinimumVersion),
		("testMaximumVersion", testMaximumVersion),
		("testRegisterReplyHandler", testRegisterReplyHandler),
		("testInitializationVersion", testInitializationVersion),
		("testMultipleInitialization", testMultipleInitialization),
		("testValid", testValid),
	]
}
