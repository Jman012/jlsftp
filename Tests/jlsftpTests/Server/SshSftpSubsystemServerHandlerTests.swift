import XCTest
import Combine
import NIO
import NIOTestUtils
import NIOSSH
import Logging
@testable import jlsftp

final class SshSftpSubsystemServerHandlerTests: XCTestCase {

	let noopLogger = Logger(label: "test", factory: { _ in SwiftLogNoOpLogHandler() })

	func testSftpSubsystemEvent() {
		let channel = EmbeddedChannel()
		let eventCounterHandlerBegin = EventCounterHandler()
		let eventCounterHandlerEnd = EventCounterHandler()
		let handler = SshSftpSubsystemServerHandler(logger: noopLogger)
		XCTAssertNoThrow(channel.pipeline.addHandlers([eventCounterHandlerBegin, handler, eventCounterHandlerEnd]))

		// Starting point
		XCTAssertEqual(eventCounterHandlerBegin.triggerUserOutboundEventCalls, 0)
		XCTAssertEqual(eventCounterHandlerEnd.userInboundEventTriggeredCalls, 0)
		XCTAssertEqual(eventCounterHandlerEnd.channelReadCalls, 0)

		// Sftp subsystem request
		channel.pipeline.fireUserInboundEventTriggered(SSHChannelRequestEvent.SubsystemRequest(subsystem: "sftp", wantReply: false))
		// The response event is triggered back.
		XCTAssertEqual(eventCounterHandlerBegin.triggerUserOutboundEventCalls, 1)
		// Handler consumes the event and doesn't pass it up the chain. Doesn't increment.
		XCTAssertEqual(eventCounterHandlerEnd.userInboundEventTriggeredCalls, 0)

		// Channel data should go through correctly once sftp is activated. Otherwise an error would be thrown.
		let channelData = SSHChannelData(type: .channel, data: .byteBuffer(ByteBuffer(bytes: [0x01])))
		XCTAssertNoThrow(try channel.writeInbound(channelData))
		XCTAssertNoThrow(try channel.throwIfErrorCaught())
		XCTAssertEqual(eventCounterHandlerEnd.channelReadCalls, 1)
	}

	func testInputClosedEvent() {
		let channel = EmbeddedChannel()
		let eventCounterHandlerBegin = EventCounterHandler()
		let eventCounterHandlerEnd = EventCounterHandler()
		let handler = SshSftpSubsystemServerHandler(logger: noopLogger)
		XCTAssertNoThrow(channel.pipeline.addHandlers([eventCounterHandlerBegin, handler, eventCounterHandlerEnd]))

		channel.pipeline.fireUserInboundEventTriggered(ChannelEvent.inputClosed)
		// No response
		XCTAssertEqual(eventCounterHandlerBegin.triggerUserOutboundEventCalls, 0)
		// Handler consumes the event and doesn't pass it up the chain. Doesn't increment.
		XCTAssertEqual(eventCounterHandlerEnd.userInboundEventTriggeredCalls, 0)
	}

	func testInputOtherEvent() {
		let channel = EmbeddedChannel()
		let eventCounterHandlerBegin = EventCounterHandler()
		let eventCounterHandlerEnd = EventCounterHandler()
		let handler = SshSftpSubsystemServerHandler(logger: noopLogger)
		XCTAssertNoThrow(channel.pipeline.addHandlers([eventCounterHandlerBegin, handler, eventCounterHandlerEnd]))

		channel.pipeline.fireUserInboundEventTriggered("test")
		// No response
		XCTAssertEqual(eventCounterHandlerBegin.triggerUserOutboundEventCalls, 0)
		// Handler passes it up the chain.
		XCTAssertEqual(eventCounterHandlerEnd.userInboundEventTriggeredCalls, 1)
	}

	func testDataErrorBeforeSftpInit() {
		let channel = EmbeddedChannel()
		let eventCounterHandlerBegin = EventCounterHandler()
		let eventCounterHandlerEnd = EventCounterHandler()
		let handler = SshSftpSubsystemServerHandler(logger: noopLogger)
		XCTAssertNoThrow(channel.pipeline.addHandlers([eventCounterHandlerBegin, handler, eventCounterHandlerEnd]))

		// Send data before triggering sftp
		let channelData = SSHChannelData(type: .channel, data: .byteBuffer(ByteBuffer(bytes: [0x01])))
		XCTAssertThrowsError(try channel.writeInbound(channelData))
		XCTAssertEqual(eventCounterHandlerEnd.channelReadCalls, 0)
	}

	func testUnexpectedChannelData() {
		let channel = EmbeddedChannel()
		let eventCounterHandlerBegin = EventCounterHandler()
		let eventCounterHandlerEnd = EventCounterHandler()
		let handler = SshSftpSubsystemServerHandler(logger: noopLogger)
		XCTAssertNoThrow(channel.pipeline.addHandlers([eventCounterHandlerBegin, handler, eventCounterHandlerEnd]))

		channel.pipeline.fireUserInboundEventTriggered(SSHChannelRequestEvent.SubsystemRequest(subsystem: "sftp", wantReply: false))
		XCTAssertEqual(eventCounterHandlerBegin.triggerUserOutboundEventCalls, 1)
		XCTAssertEqual(eventCounterHandlerEnd.userInboundEventTriggeredCalls, 0)

		let unsafeHandle = NIOFileHandle(descriptor: 1)
		_ = try! unsafeHandle.takeDescriptorOwnership()
		let channelData = SSHChannelData(type: .channel, data: .fileRegion(FileRegion(fileHandle: unsafeHandle, readerIndex: 0, endIndex: 1)))
		XCTAssertThrowsError(try channel.writeInbound(channelData))
		XCTAssertEqual(eventCounterHandlerEnd.channelReadCalls, 0)
	}

	func testWrite() {
		let channel = EmbeddedChannel()
		let eventCounterHandlerBegin = EventCounterHandler()
		let eventCounterHandlerEnd = EventCounterHandler()
		let handler = SshSftpSubsystemServerHandler(logger: noopLogger)
		XCTAssertNoThrow(channel.pipeline.addHandlers([eventCounterHandlerBegin, handler, eventCounterHandlerEnd]))

		channel.pipeline.fireUserInboundEventTriggered(SSHChannelRequestEvent.SubsystemRequest(subsystem: "sftp", wantReply: false))
		XCTAssertEqual(eventCounterHandlerBegin.triggerUserOutboundEventCalls, 1)
		XCTAssertEqual(eventCounterHandlerEnd.userInboundEventTriggeredCalls, 0)

		XCTAssertEqual(eventCounterHandlerBegin.writeCalls, 0)
		XCTAssertNoThrow(try channel.writeOutbound(ByteBuffer(bytes: [0x01])))
		XCTAssertEqual(eventCounterHandlerBegin.writeCalls, 1)
	}

	func testWriteWithoutSftp() {
		let channel = EmbeddedChannel()
		let eventCounterHandlerBegin = EventCounterHandler()
		let eventCounterHandlerEnd = EventCounterHandler()
		let handler = SshSftpSubsystemServerHandler(logger: noopLogger)
		XCTAssertNoThrow(channel.pipeline.addHandlers([eventCounterHandlerBegin, handler, eventCounterHandlerEnd]))

		XCTAssertEqual(eventCounterHandlerBegin.writeCalls, 0)
		XCTAssertThrowsError(try channel.writeOutbound(ByteBuffer(bytes: [0x01])))
		XCTAssertEqual(eventCounterHandlerBegin.writeCalls, 0)
	}

	static var allTests = [
		("testSftpSubsystemEvent", testSftpSubsystemEvent),
		("testInputClosedEvent", testInputClosedEvent),
		("testInputOtherEvent", testInputOtherEvent),
		("testDataErrorBeforeSftpInit", testDataErrorBeforeSftpInit),
	]
}
