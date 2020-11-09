import NIO
import XCTest
@testable import jlsftp

final class FileAttributesSerializationV3Tests: XCTestCase {

	func testFlags() {
		// Values take from https://tools.ietf.org/html/draft-ietf-secsh-filexfer-02#section-5
		XCTAssertEqual(
			jlsftp.DataLayer.Version_3.FileAttributesFlags(rawValue: 0x0000_0001),
			jlsftp.DataLayer.Version_3.FileAttributesFlags.size)
		XCTAssertEqual(
			jlsftp.DataLayer.Version_3.FileAttributesFlags(rawValue: 0x0000_0002),
			jlsftp.DataLayer.Version_3.FileAttributesFlags.userAndGroupIds)
		XCTAssertEqual(
			jlsftp.DataLayer.Version_3.FileAttributesFlags(rawValue: 0x0000_0004),
			jlsftp.DataLayer.Version_3.FileAttributesFlags.permissions)
		XCTAssertEqual(
			jlsftp.DataLayer.Version_3.FileAttributesFlags(rawValue: 0x0000_0008),
			jlsftp.DataLayer.Version_3.FileAttributesFlags.accessAndModificationTimes)
		XCTAssertEqual(
			jlsftp.DataLayer.Version_3.FileAttributesFlags(rawValue: 0x8000_0000),
			jlsftp.DataLayer.Version_3.FileAttributesFlags.extendedAttributes)
	}

	func testMinimal() {
		var buffer = ByteBuffer(bytes: [
			// Flags (UInt32)
			0x00, 0x00, 0x00, 0x00,
		])

		let serialization = jlsftp.DataLayer.Version_3.FileAttributesSerializationV3()
		let result = serialization.deserialize(from: &buffer)

		guard case let .success(fileAttrs) = result else {
			XCTFail("Expected success. Instead, got '\(result)'")
			return
		}

		let expectedFileAttrs = FileAttributes(sizeBytes: nil,
											   userId: nil,
											   groupId: nil,
											   permissions: nil,
											   accessDate: nil,
											   modifyDate: nil,
											   extensionData: [])
		XCTAssertEqual(expectedFileAttrs, fileAttrs)
	}

	func testSize() {
		var buffer = ByteBuffer(bytes: [
			// Flags (UInt32 Network Byte Order: SSH_FILEXFER_ATTR_SIZE)
			0x00, 0x00, 0x00, 0x01,
			// Size (UInt64 Network Byte Order: 2)
			0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02,
		])

		let serialization = jlsftp.DataLayer.Version_3.FileAttributesSerializationV3()
		let result = serialization.deserialize(from: &buffer)

		guard case let .success(fileAttrs) = result else {
			XCTFail("Expected success. Instead, got '\(result)'")
			return
		}

		let expectedFileAttrs = FileAttributes(sizeBytes: 2,
											   userId: nil,
											   groupId: nil,
											   permissions: nil,
											   accessDate: nil,
											   modifyDate: nil,
											   extensionData: [])
		XCTAssertEqual(expectedFileAttrs, fileAttrs)
	}

	func testUserGroupIds() {
		var buffer = ByteBuffer(bytes: [
			// Flags (UInt32 Network Byte Order: SSH_FILEXFER_ATTR_UIDGID)
			0x00, 0x00, 0x00, 0x02,
			// uid (UInt32 Network Byte Order: 2)
			0x00, 0x00, 0x00, 0x02,
			// gid (UInt32 Network Byte Order: 3)
			0x00, 0x00, 0x00, 0x03,
		])

		let serialization = jlsftp.DataLayer.Version_3.FileAttributesSerializationV3()
		let result = serialization.deserialize(from: &buffer)

		guard case let .success(fileAttrs) = result else {
			XCTFail("Expected success. Instead, got '\(result)'")
			return
		}

		let expectedFileAttrs = FileAttributes(sizeBytes: nil,
											   userId: 2,
											   groupId: 3,
											   permissions: nil,
											   accessDate: nil,
											   modifyDate: nil,
											   extensionData: [])
		XCTAssertEqual(expectedFileAttrs, fileAttrs)
	}

	func testPermissions() {
		var buffer = ByteBuffer(bytes: [
			// Flags (UInt32 Network Byte Order: SSH_FILEXFER_ATTR_PERMISSIONS)
			0x00, 0x00, 0x00, 0x04,
			// uid (UInt32 Network Byte Order: 0o752)
			0b0000_0000, 0b0000_0000, 0b0000_0001, 0b1110_1010,
		])

		let serialization = jlsftp.DataLayer.Version_3.FileAttributesSerializationV3()
		let result = serialization.deserialize(from: &buffer)

		guard case let .success(fileAttrs) = result else {
			XCTFail("Expected success. Instead, got '\(result)'")
			return
		}

		let expectedFileAttrs = FileAttributes(sizeBytes: nil,
											   userId: nil,
											   groupId: nil,
											   permissions: Permissions(user: [.read, .write, .execute], group: [.read, .execute], other: [.write]),
											   accessDate: nil,
											   modifyDate: nil,
											   extensionData: [])
		XCTAssertEqual(expectedFileAttrs, fileAttrs)
	}

	func testACModTime() {
		var buffer = ByteBuffer(bytes: [
			// Flags (UInt32 Network Byte Order: SSH_FILEXFER_ACMODTIME)
			0x00, 0x00, 0x00, 0x08,
			// atime (UInt32 Network Byte Order: 1)
			0x00, 0x00, 0x00, 0x01,
			// mtime (UInt32 Network Byte Order: 2)
			0x00, 0x00, 0x00, 0x02,
		])

		let serialization = jlsftp.DataLayer.Version_3.FileAttributesSerializationV3()
		let result = serialization.deserialize(from: &buffer)

		guard case let .success(fileAttrs) = result else {
			XCTFail("Expected success. Instead, got '\(result)'")
			return
		}

		let expectedFileAttrs = FileAttributes(sizeBytes: nil,
											   userId: nil,
											   groupId: nil,
											   permissions: nil,
											   accessDate: Date(timeIntervalSince1970: 1),
											   modifyDate: Date(timeIntervalSince1970: 2),
											   extensionData: [])
		XCTAssertEqual(expectedFileAttrs, fileAttrs)
	}

	func testExtended() {
		var buffer = ByteBuffer(bytes: [
			// Flags (UInt32 Network Byte Order: SSH_FILEXFER_ATTR_EXTENDED)
			0x80, 0x00, 0x00, 0x00,
			// Extended Count (UInt32 Network Byte Order: 1)
			0x00, 0x00, 0x00, 0x01,
			// Extended Name (String Size (UInt32 Network Byte Order: 2))
			0x00, 0x00, 0x00, 0x02,
			// Extended Name (String data, "Ab")
			65, 98,
			// Extended Data (String Size (UInt32 Network Byte Order: 3))
			0x00, 0x00, 0x00, 0x03,
			// Extended Data (String data, "cDe")
			99, 68, 101,
		])

		let serialization = jlsftp.DataLayer.Version_3.FileAttributesSerializationV3()
		let result = serialization.deserialize(from: &buffer)

		guard case let .success(fileAttrs) = result else {
			XCTFail("Expected success. Instead, got '\(result)'")
			return
		}

		let expectedFileAttrs = FileAttributes(sizeBytes: nil,
											   userId: nil,
											   groupId: nil,
											   permissions: nil,
											   accessDate: nil,
											   modifyDate: nil,
											   extensionData: [ExtensionData(name: "Ab", data: "cDe")])
		XCTAssertEqual(expectedFileAttrs, fileAttrs)
	}

	static var allTests = [
		("testFlags", testFlags),
		("testMinimal", testMinimal),
		("testSize", testSize),
		("testUserGroupIds", testUserGroupIds),
		("testPermissions", testPermissions),
		("testACModTime", testACModTime),
		("testExtended", testExtended),
	]
}
