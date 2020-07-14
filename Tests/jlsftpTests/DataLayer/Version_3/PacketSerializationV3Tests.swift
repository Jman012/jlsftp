import XCTest
@testable import jlsftp

final class PacketSerializationV3Tests: XCTestCase {

	class MockSerializationHandler: SftpVersion3PacketSerializationHandler {
		var timesCalled = 0
		func deserialize(fromPayload _: Data) -> Result<Packet, DeserializationError> {
			timesCalled += 1
			return .failure(.invalidDataPayload(reason: "test"))
		}
	}

	func testInvalidTypeZero() {
		let mockOther = MockSerializationHandler()
		let packetSerialization = jlsftp.DataLayer.Version_3.PacketSerializationV3(
			initializePacketSerialization: mockOther,
			versionPacketSerialization: mockOther
		)

		let result = packetSerialization.deserialize(
			rawPacket: RawPacket(length: 0, type: 0, dataPayload: Data())
		)

		guard case .failure(.invalidType) = result else {
			XCTFail("Expected invalidType failure. Got '\(result)'")
			return
		}

		XCTAssertEqual(0, mockOther.timesCalled)
	}

	func testInvalidTypeUnhandled() {
		let mockOther = MockSerializationHandler()
		let packetSerialization = jlsftp.DataLayer.Version_3.PacketSerializationV3(
			initializePacketSerialization: mockOther,
			versionPacketSerialization: mockOther
		)

		let result = packetSerialization.deserialize(
			rawPacket: RawPacket(
				length: 0,
				type: jlsftp.DataLayer.Version_3.PacketType.extended.rawValue,
				dataPayload: Data()
			)
		)

		guard case .failure(.invalidType) = result else {
			XCTFail("Expected invalidType failure. Got '\(result)'")
			return
		}

		XCTAssertEqual(0, mockOther.timesCalled)
	}

	func testInitialize() {

		let mockInitialize = MockSerializationHandler()
		let mockOther = MockSerializationHandler()
		let packetSerialization = jlsftp.DataLayer.Version_3.PacketSerializationV3(
			initializePacketSerialization: mockInitialize,
			versionPacketSerialization: mockOther
		)

		let result = packetSerialization.deserialize(
			rawPacket: RawPacket(
				length: 0,
				type: jlsftp.DataLayer.Version_3.PacketType.initialize.rawValue,
				dataPayload: Data([0x03])
			)
		)

		guard case .failure(.invalidDataPayload(reason: "test")) = result else {
			XCTFail("Expected failure. Got '\(result)'")
			return
		}

		XCTAssertEqual(1, mockInitialize.timesCalled)
		XCTAssertEqual(0, mockOther.timesCalled)
	}

	func testVersion() {

		let mockVersion = MockSerializationHandler()
		let mockOther = MockSerializationHandler()
		let packetSerialization = jlsftp.DataLayer.Version_3.PacketSerializationV3(
			initializePacketSerialization: mockOther,
			versionPacketSerialization: mockVersion
		)

		let result = packetSerialization.deserialize(
			rawPacket: RawPacket(
				length: 0,
				type: jlsftp.DataLayer.Version_3.PacketType.version.rawValue,
				dataPayload: Data([0x03])
			)
		)

		guard case .failure(.invalidDataPayload(reason: "test")) = result else {
			XCTFail("Expected failure. Got '\(result)'")
			return
		}

		XCTAssertEqual(1, mockVersion.timesCalled)
		XCTAssertEqual(0, mockOther.timesCalled)
	}

	static var allTests = [
		("testInvalidTypeZero", testInvalidTypeZero),
		("testInvalidTypeUnhandled", testInvalidTypeUnhandled),
		("testInitialize", testInitialize),
		("testVersion", testVersion),
	]
}
