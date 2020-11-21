import NIO
import XCTest
@testable import jlsftp

final class FileAttributesSerializationV3Tests: XCTestCase {

	// MARK: Test FileAttributesFlags.init

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

	// MARK: Test deserialize(from:)

	func testDeserializeMinimal() {
		var buffer = ByteBuffer(bytes: [
			// Flags (UInt32)
			0x00, 0x00, 0x00, 0x00,
		])

		let serialization = jlsftp.DataLayer.Version_3.FileAttributesSerializationV3()
		let result = serialization.deserialize(from: &buffer)

		XCTAssertNoThrow(try result.get())
		let fileAttrs = try! result.get()

		let expectedFileAttrs = FileAttributes(sizeBytes: nil,
											   userId: nil,
											   groupId: nil,
											   permissions: nil,
											   accessDate: nil,
											   modifyDate: nil,
											   extensionData: [])
		XCTAssertEqual(expectedFileAttrs, fileAttrs)
	}

	func testDeserializeSize() {
		var buffer = ByteBuffer(bytes: [
			// Flags (UInt32 Network Byte Order: SSH_FILEXFER_ATTR_SIZE)
			0x00, 0x00, 0x00, 0x01,
			// Size (UInt64 Network Byte Order: 2)
			0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02,
		])

		let serialization = jlsftp.DataLayer.Version_3.FileAttributesSerializationV3()
		let result = serialization.deserialize(from: &buffer)

		XCTAssertNoThrow(try result.get())
		let fileAttrs = try! result.get()

		let expectedFileAttrs = FileAttributes(sizeBytes: 2,
											   userId: nil,
											   groupId: nil,
											   permissions: nil,
											   accessDate: nil,
											   modifyDate: nil,
											   extensionData: [])
		XCTAssertEqual(expectedFileAttrs, fileAttrs)
	}

	func testDeserializeUserGroupIds() {
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

		XCTAssertNoThrow(try result.get())
		let fileAttrs = try! result.get()

		let expectedFileAttrs = FileAttributes(sizeBytes: nil,
											   userId: 2,
											   groupId: 3,
											   permissions: nil,
											   accessDate: nil,
											   modifyDate: nil,
											   extensionData: [])
		XCTAssertEqual(expectedFileAttrs, fileAttrs)
	}

	func testDeserializePermissions() {
		var buffer = ByteBuffer(bytes: [
			// Flags (UInt32 Network Byte Order: SSH_FILEXFER_ATTR_PERMISSIONS)
			0x00, 0x00, 0x00, 0x04,
			// uid (UInt32 Network Byte Order: 0o752)
			0b0000_0000, 0b0000_0000, 0b0000_0001, 0b1110_1010,
		])

		let serialization = jlsftp.DataLayer.Version_3.FileAttributesSerializationV3()
		let result = serialization.deserialize(from: &buffer)

		XCTAssertNoThrow(try result.get())
		let fileAttrs = try! result.get()

		let expectedFileAttrs = FileAttributes(sizeBytes: nil,
											   userId: nil,
											   groupId: nil,
											   permissions: Permissions(user: [.read, .write, .execute], group: [.read, .execute], other: [.write]),
											   accessDate: nil,
											   modifyDate: nil,
											   extensionData: [])
		XCTAssertEqual(expectedFileAttrs, fileAttrs)
	}

	func testDeserializePermissionExtraBitsIgnored() {
		var buffer = ByteBuffer(bytes: [
			// Flags (UInt32 Network Byte Order: SSH_FILEXFER_ATTR_PERMISSIONS)
			0x00, 0x00, 0x00, 0x04,
			// uid (UInt32 Network Byte Order: 0o752)
			0b1111_1111, 0b1111_1111, 0b0000_0001, 0b1110_1010,
		])

		let serialization = jlsftp.DataLayer.Version_3.FileAttributesSerializationV3()
		let result = serialization.deserialize(from: &buffer)

		XCTAssertNoThrow(try result.get())
		let fileAttrs = try! result.get()

		let expectedFileAttrs = FileAttributes(sizeBytes: nil,
											   userId: nil,
											   groupId: nil,
											   permissions: Permissions(user: [.read, .write, .execute], group: [.read, .execute], other: [.write]),
											   accessDate: nil,
											   modifyDate: nil,
											   extensionData: [])
		XCTAssertEqual(expectedFileAttrs, fileAttrs)
	}

	func testDeserializeACModTime() {
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

		XCTAssertNoThrow(try result.get())
		let fileAttrs = try! result.get()

		let expectedFileAttrs = FileAttributes(sizeBytes: nil,
											   userId: nil,
											   groupId: nil,
											   permissions: nil,
											   accessDate: Date(timeIntervalSince1970: 1),
											   modifyDate: Date(timeIntervalSince1970: 2),
											   extensionData: [])
		XCTAssertEqual(expectedFileAttrs, fileAttrs)
	}

	func testDeserializeExtended() {
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

		XCTAssertNoThrow(try result.get())
		let fileAttrs = try! result.get()

		let expectedFileAttrs = FileAttributes(sizeBytes: nil,
											   userId: nil,
											   groupId: nil,
											   permissions: nil,
											   accessDate: nil,
											   modifyDate: nil,
											   extensionData: [ExtensionData(name: "Ab", data: "cDe")])
		XCTAssertEqual(expectedFileAttrs, fileAttrs)
	}

	func testDeserializeNeedMoreData() {
		let serialization = jlsftp.DataLayer.Version_3.FileAttributesSerializationV3()
		let buffers = [
			// No Flags
			ByteBuffer(bytes: []),
			// Partial Flags
			ByteBuffer(bytes: [0xFF]),
			ByteBuffer(bytes: [0xFF, 0xFF]),
			ByteBuffer(bytes: [0xFF, 0xFF, 0xFF]),
			// Flags, partial size
			ByteBuffer(bytes: [0xFF, 0xFF, 0xFF, 0xFF]),
			ByteBuffer(bytes: [0xFF, 0xFF, 0xFF, 0xFF,
							   0x00]), // size
			// Flags, size, partial userId
			ByteBuffer(bytes: [0xFF, 0xFF, 0xFF, 0xFF]),
			ByteBuffer(bytes: [0xFF, 0xFF, 0xFF, 0xFF,
							   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]), // size
			ByteBuffer(bytes: [0xFF, 0xFF, 0xFF, 0xFF,
							   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // size
							   0x00]), // userId
			// Flags, size, userId, partial groupId
			ByteBuffer(bytes: [0xFF, 0xFF, 0xFF, 0xFF,
							   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // size
							   0x00, 0x00, 0x00, 0x00]), // userId
			ByteBuffer(bytes: [0xFF, 0xFF, 0xFF, 0xFF,
							   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // size
							   0x00, 0x00, 0x00, 0x00, // userId
							   0x00]), // groupId
			// Flags, size, userId, groupId, partial permissions
			ByteBuffer(bytes: [0xFF, 0xFF, 0xFF, 0xFF,
							   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // size
							   0x00, 0x00, 0x00, 0x00, // userId
							   0x00, 0x00, 0x00, 0x00]), // groupId
			ByteBuffer(bytes: [0xFF, 0xFF, 0xFF, 0xFF,
							   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // size
							   0x00, 0x00, 0x00, 0x00, // userId
							   0x00, 0x00, 0x00, 0x00, // groupId
							   0x00]), // permissions
			// Flags, size, userId, groupId, permissions, partial accessTime
			ByteBuffer(bytes: [0xFF, 0xFF, 0xFF, 0xFF,
							   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // size
							   0x00, 0x00, 0x00, 0x00, // userId
							   0x00, 0x00, 0x00, 0x00, // groupId
							   0x00, 0x00, 0x00, 0x00]), // permissions
			ByteBuffer(bytes: [0xFF, 0xFF, 0xFF, 0xFF,
							   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // size
							   0x00, 0x00, 0x00, 0x00, // userId
							   0x00, 0x00, 0x00, 0x00, // groupId
							   0x00, 0x00, 0x00, 0x00, // permissions
							   0x00]), // accessTime
			// Flags, size, userId, groupId, permissions, accessTime, partial modifyTime
			ByteBuffer(bytes: [0xFF, 0xFF, 0xFF, 0xFF,
							   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // size
							   0x00, 0x00, 0x00, 0x00, // userId
							   0x00, 0x00, 0x00, 0x00, // groupId
							   0x00, 0x00, 0x00, 0x00, // permissions
							   0x00, 0x00, 0x00, 0x00]), // accessTime
			ByteBuffer(bytes: [0xFF, 0xFF, 0xFF, 0xFF,
							   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // size
							   0x00, 0x00, 0x00, 0x00, // userId
							   0x00, 0x00, 0x00, 0x00, // groupId
							   0x00, 0x00, 0x00, 0x00, // permissions
							   0x00, 0x00, 0x00, 0x00, // accessTime
							   0x00]), // modifyTime
			// Flags, size, userId, groupId, permissions, accessTime, modifyTime, partial extension count
			ByteBuffer(bytes: [0xFF, 0xFF, 0xFF, 0xFF,
							   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // size
							   0x00, 0x00, 0x00, 0x00, // userId
							   0x00, 0x00, 0x00, 0x00, // groupId
							   0x00, 0x00, 0x00, 0x00, // permissions
							   0x00, 0x00, 0x00, 0x00, // accessTime
							   0x00, 0x00, 0x00, 0x00]), // modifyTime
			ByteBuffer(bytes: [0xFF, 0xFF, 0xFF, 0xFF,
							   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // size
							   0x00, 0x00, 0x00, 0x00, // userId
							   0x00, 0x00, 0x00, 0x00, // groupId
							   0x00, 0x00, 0x00, 0x00, // permissions
							   0x00, 0x00, 0x00, 0x00, // accessTime
							   0x00, 0x00, 0x00, 0x00, // modifyTime
							   0x00]), // extension count
			// Flags, size, userId, groupId, permissions, accessTime, modifyTime, extension count, partial extension name
			ByteBuffer(bytes: [0xFF, 0xFF, 0xFF, 0xFF,
							   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // size
							   0x00, 0x00, 0x00, 0x00, // userId
							   0x00, 0x00, 0x00, 0x00, // groupId
							   0x00, 0x00, 0x00, 0x00, // permissions
							   0x00, 0x00, 0x00, 0x00, // accessTime
							   0x00, 0x00, 0x00, 0x00, // modifyTime
							   0x00, 0x00, 0x00, 0x01]), // extension count
			ByteBuffer(bytes: [0xFF, 0xFF, 0xFF, 0xFF,
							   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // size
							   0x00, 0x00, 0x00, 0x00, // userId
							   0x00, 0x00, 0x00, 0x00, // groupId
							   0x00, 0x00, 0x00, 0x00, // permissions
							   0x00, 0x00, 0x00, 0x00, // accessTime
							   0x00, 0x00, 0x00, 0x00, // modifyTime
							   0x00, 0x00, 0x00, 0x01, // extension count
							   0x00]), // extension name length+data
			// Flags, size, userId, groupId, permissions, accessTime, modifyTime, extension count, extension name, partial extension data
			ByteBuffer(bytes: [0xFF, 0xFF, 0xFF, 0xFF,
							   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // size
							   0x00, 0x00, 0x00, 0x00, // userId
							   0x00, 0x00, 0x00, 0x00, // groupId
							   0x00, 0x00, 0x00, 0x00, // permissions
							   0x00, 0x00, 0x00, 0x00, // accessTime
							   0x00, 0x00, 0x00, 0x00, // modifyTime
							   0x00, 0x00, 0x00, 0x01, // extension count
							   0x00, 0x00, 0x00, 0x01, 0x61]), // extension name length+data
			ByteBuffer(bytes: [0xFF, 0xFF, 0xFF, 0xFF,
							   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // size
							   0x00, 0x00, 0x00, 0x00, // userId
							   0x00, 0x00, 0x00, 0x00, // groupId
							   0x00, 0x00, 0x00, 0x00, // permissions
							   0x00, 0x00, 0x00, 0x00, // accessTime
							   0x00, 0x00, 0x00, 0x00, // modifyTime
							   0x00, 0x00, 0x00, 0x01, // extension count
							   0x00, 0x00, 0x00, 0x01, 0x61, // extension name length+data
							   0x00]), // extension data length+data
		]

		for var buffer in buffers {
			let result = serialization.deserialize(from: &buffer)

			XCTAssertEqual(.needMoreData, result.error)
		}
	}

	// MARK: Test serialize(fileAttrs:to:)

	func testSerializeValidMinimal() {
		let serialization = jlsftp.DataLayer.Version_3.FileAttributesSerializationV3()
		let fileAttrs = FileAttributes(sizeBytes: nil,
									   userId: nil,
									   groupId: nil,
									   permissions: nil,
									   accessDate: nil,
									   modifyDate: nil,
									   extensionData: [])
		var buffer = ByteBuffer()

		XCTAssertTrue(serialization.serialize(fileAttrs: fileAttrs, to: &buffer))

		let expectedBuffer = ByteBuffer(bytes: [
			// Flags (UInt32: Nothing)
			0x00, 0x00, 0x00, 0x00,
		])
		XCTAssertEqual(expectedBuffer, buffer)
	}

	func testSerializeSize() {
		let serialization = jlsftp.DataLayer.Version_3.FileAttributesSerializationV3()
		let fileAttrs = FileAttributes(sizeBytes: 1,
									   userId: nil,
									   groupId: nil,
									   permissions: nil,
									   accessDate: nil,
									   modifyDate: nil,
									   extensionData: [])
		var buffer = ByteBuffer()

		XCTAssertTrue(serialization.serialize(fileAttrs: fileAttrs, to: &buffer))

		let expectedBuffer = ByteBuffer(bytes: [
			// Flags (UInt32: SSH_FILEXFER_ATTR_SIZE)
			0x00, 0x00, 0x00, 0x01,
			// Size (UInt64 Network Order: 1)
			0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01,
		])
		XCTAssertEqual(expectedBuffer, buffer)
	}

	func testSerializeUserGroupdIds() {
		let serialization = jlsftp.DataLayer.Version_3.FileAttributesSerializationV3()
		let fileAttrs = FileAttributes(sizeBytes: nil,
									   userId: 2,
									   groupId: 3,
									   permissions: nil,
									   accessDate: nil,
									   modifyDate: nil,
									   extensionData: [])
		var buffer = ByteBuffer()

		XCTAssertTrue(serialization.serialize(fileAttrs: fileAttrs, to: &buffer))

		let expectedBuffer = ByteBuffer(bytes: [
			// Flags (UInt32: SSH_FILEXFER_ATTR_UIDGID)
			0x00, 0x00, 0x00, 0x02,
			// UserId (UInt32 Network Order: 2)
			0x00, 0x00, 0x00, 0x02,
			// GroupId (UInt32 Network Order: 3)
			0x00, 0x00, 0x00, 0x03,
		])
		XCTAssertEqual(expectedBuffer, buffer)
	}

	func testSerializeUserGroupdIdsNoUser() {
		let serialization = jlsftp.DataLayer.Version_3.FileAttributesSerializationV3()
		let fileAttrs = FileAttributes(sizeBytes: nil,
									   userId: nil,
									   groupId: 3,
									   permissions: nil,
									   accessDate: nil,
									   modifyDate: nil,
									   extensionData: [])
		var buffer = ByteBuffer()

		XCTAssertTrue(serialization.serialize(fileAttrs: fileAttrs, to: &buffer))

		let expectedBuffer = ByteBuffer(bytes: [
			// Flags (UInt32: SSH_FILEXFER_ATTR_UIDGID)
			0x00, 0x00, 0x00, 0x02,
			// UserId (UInt32 Network Order: 0)
			0x00, 0x00, 0x00, 0x00,
			// GroupId (UInt32 Network Order: 3)
			0x00, 0x00, 0x00, 0x03,
		])
		XCTAssertEqual(expectedBuffer, buffer)
	}

	func testSerializeUserGroupdIdsNoGroup() {
		let serialization = jlsftp.DataLayer.Version_3.FileAttributesSerializationV3()
		let fileAttrs = FileAttributes(sizeBytes: nil,
									   userId: 2,
									   groupId: nil,
									   permissions: nil,
									   accessDate: nil,
									   modifyDate: nil,
									   extensionData: [])
		var buffer = ByteBuffer()

		XCTAssertTrue(serialization.serialize(fileAttrs: fileAttrs, to: &buffer))

		let expectedBuffer = ByteBuffer(bytes: [
			// Flags (UInt32: SSH_FILEXFER_ATTR_UIDGID)
			0x00, 0x00, 0x00, 0x02,
			// UserId (UInt32 Network Order: 2)
			0x00, 0x00, 0x00, 0x02,
			// GroupId (UInt32 Network Order: 0)
			0x00, 0x00, 0x00, 0x00,
		])
		XCTAssertEqual(expectedBuffer, buffer)
	}

	func testSerializePermissions() {
		let serialization = jlsftp.DataLayer.Version_3.FileAttributesSerializationV3()
		let fileAttrs = FileAttributes(sizeBytes: nil,
									   userId: nil,
									   groupId: nil,
									   permissions: Permissions(user: Set([.read]), group: Set([.write]), other: Set([.execute])),
									   accessDate: nil,
									   modifyDate: nil,
									   extensionData: [])
		var buffer = ByteBuffer()

		XCTAssertTrue(serialization.serialize(fileAttrs: fileAttrs, to: &buffer))

		let expectedBuffer = ByteBuffer(bytes: [
			// Flags (UInt32: SSH_FILEXFER_ATTR_PERMISSIONS)
			0x00, 0x00, 0x00, 0x04,
			// Permissions (UInt32: U+R G+W O+E)
			0x00, 0x00, 0b0000_0001, 0b0001_0001,
		])
		XCTAssertEqual(expectedBuffer, buffer)
	}

	func testSerializeACModTime() {
		let serialization = jlsftp.DataLayer.Version_3.FileAttributesSerializationV3()
		let fileAttrs = FileAttributes(sizeBytes: nil,
									   userId: nil,
									   groupId: nil,
									   permissions: nil,
									   accessDate: Date(timeIntervalSince1970: 4),
									   modifyDate: Date(timeIntervalSince1970: 5),
									   extensionData: [])
		var buffer = ByteBuffer()

		XCTAssertTrue(serialization.serialize(fileAttrs: fileAttrs, to: &buffer))

		let expectedBuffer = ByteBuffer(bytes: [
			// Flags (UInt32: SSH_FILEXFER_ATTR_ACMODTIME)
			0x00, 0x00, 0x00, 0x08,
			// Access Time (UInt32 Network Order: 4)
			0x00, 0x00, 0x00, 0x04,
			// Modify Time (UInt32 Network Order: 5)
			0x00, 0x00, 0x00, 0x05,
		])
		XCTAssertEqual(expectedBuffer, buffer)
	}

	func testSerializeACModTimeNoAccess() {
		let serialization = jlsftp.DataLayer.Version_3.FileAttributesSerializationV3()
		let fileAttrs = FileAttributes(sizeBytes: nil,
									   userId: nil,
									   groupId: nil,
									   permissions: nil,
									   accessDate: nil,
									   modifyDate: Date(timeIntervalSince1970: 5),
									   extensionData: [])
		var buffer = ByteBuffer()

		XCTAssertTrue(serialization.serialize(fileAttrs: fileAttrs, to: &buffer))

		let expectedBuffer = ByteBuffer(bytes: [
			// Flags (UInt32: SSH_FILEXFER_ATTR_ACMODTIME)
			0x00, 0x00, 0x00, 0x08,
			// Access Time (UInt32 Network Order: 0)
			0x00, 0x00, 0x00, 0x00,
			// Modify Time (UInt32 Network Order: 5)
			0x00, 0x00, 0x00, 0x05,
		])
		XCTAssertEqual(expectedBuffer, buffer)
	}

	func testSerializeACModTimeNoModify() {
		let serialization = jlsftp.DataLayer.Version_3.FileAttributesSerializationV3()
		let fileAttrs = FileAttributes(sizeBytes: nil,
									   userId: nil,
									   groupId: nil,
									   permissions: nil,
									   accessDate: Date(timeIntervalSince1970: 4),
									   modifyDate: nil,
									   extensionData: [])
		var buffer = ByteBuffer()

		XCTAssertTrue(serialization.serialize(fileAttrs: fileAttrs, to: &buffer))

		let expectedBuffer = ByteBuffer(bytes: [
			// Flags (UInt32: SSH_FILEXFER_ATTR_ACMODTIME)
			0x00, 0x00, 0x00, 0x08,
			// Access Time (UInt32 Network Order: 4)
			0x00, 0x00, 0x00, 0x04,
			// Modify Time (UInt32 Network Order: 0)
			0x00, 0x00, 0x00, 0x00,
		])
		XCTAssertEqual(expectedBuffer, buffer)
	}

	func testSerializeExtensions() {
		let serialization = jlsftp.DataLayer.Version_3.FileAttributesSerializationV3()
		let fileAttrs = FileAttributes(sizeBytes: nil,
									   userId: nil,
									   groupId: nil,
									   permissions: nil,
									   accessDate: nil,
									   modifyDate: nil,
									   extensionData: [ExtensionData(name: "a", data: "bc"), ExtensionData(name: "de", data: "f")])
		var buffer = ByteBuffer()

		XCTAssertTrue(serialization.serialize(fileAttrs: fileAttrs, to: &buffer))

		let expectedBuffer = ByteBuffer(bytes: [
			// Flags (UInt32: SSH_FILEXFER_ATTR_EXTENDED)
			0x80, 0x00, 0x00, 0x00,
			// Extended Datum 1 Name string length (UInt32 Network Order: 1)
			0x00, 0x00, 0x00, 0x01,
			// Extended Datum 1 Name string data ("a")
			0x61,
			// Extended Datum 1 Data string length (UInt32 Network Order: 2)
			0x00, 0x00, 0x00, 0x02,
			// Extended Datum 1 Data string data ("bc")
			0x62, 0x63,
			// Extended Datum 2 Name string length (UInt32 Network Order: 2)
			0x00, 0x00, 0x00, 0x02,
			// Extended Datum 2 Name string data ("de")
			0x64, 0x65,
			// Extended Datum 2 Data string length (UInt32 Network Order: 1)
			0x00, 0x00, 0x00, 0x01,
			// Extended Datum 2 Data string data ("f")
			0x66,
		])
		XCTAssertEqual(expectedBuffer, buffer)
	}

//	func testSerializeExtensionsLargeName() {
//		let serialization = jlsftp.DataLayer.Version_3.FileAttributesSerializationV3()
//		let fileAttrs = FileAttributes(sizeBytes: nil,
//									   userId: nil,
//									   groupId: nil,
//									   permissions: nil,
//									   accessDate: nil,
//									   modifyDate: nil,
//									   extensionData: [ExtensionData(name: jlsftpTests.stringOverUInt32Length, data: "bc")])
//		var buffer = ByteBuffer()
//
//		XCTAssertFalse(serialization.serialize(fileAttrs: fileAttrs, to: &buffer))
//	}
//
//	func testSerializeExtensionsLargeData() {
//		let serialization = jlsftp.DataLayer.Version_3.FileAttributesSerializationV3()
//		let fileAttrs = FileAttributes(sizeBytes: nil,
//									   userId: nil,
//									   groupId: nil,
//									   permissions: nil,
//									   accessDate: nil,
//									   modifyDate: nil,
//									   extensionData: [ExtensionData(name: "a", data: jlsftpTests.stringOverUInt32Length)])
//		var buffer = ByteBuffer()
//
//		XCTAssertFalse(serialization.serialize(fileAttrs: fileAttrs, to: &buffer))
//	}

	static var allTests = [
		// Test FileAttributesFlags.init
		("testFlags", testFlags),
		// Test deserialize(from:)
		("testDeserializeMinimal", testDeserializeMinimal),
		("testDeserializeSize", testDeserializeSize),
		("testDeserializeUserGroupIds", testDeserializeUserGroupIds),
		("testDeserializePermissions", testDeserializePermissions),
		("testDeserializePermissionExtraBitsIgnored", testDeserializePermissionExtraBitsIgnored),
		("testDeserializeACModTime", testDeserializeACModTime),
		("testDeserializeExtended", testDeserializeExtended),
		("testDeserializeNeedMoreData", testDeserializeNeedMoreData),
		// Test serialize(fileAttrs:to:)
		("testSerializeValidMinimal", testSerializeValidMinimal),
		("testSerializeSize", testSerializeSize),
		("testSerializeUserGroupdIds", testSerializeUserGroupdIds),
		("testSerializeUserGroupdIdsNoUser", testSerializeUserGroupdIdsNoUser),
		("testSerializeUserGroupdIdsNoGroup", testSerializeUserGroupdIdsNoGroup),
		("testSerializePermissions", testSerializePermissions),
		("testSerializeACModTime", testSerializeACModTime),
		("testSerializeACModTimeNoAccess", testSerializeACModTimeNoAccess),
		("testSerializeACModTimeNoModify", testSerializeACModTimeNoModify),
		("testSerializeExtensions", testSerializeExtensions),
//		("testSerializeExtensionsLargeName", testSerializeExtensionsLargeName),
//		("testSerializeExtensionsLargeData", testSerializeExtensionsLargeData),
	]
}
