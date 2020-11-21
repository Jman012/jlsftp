import NIO
import XCTest
@testable import jlsftp

final class PacketTests: XCTestCase {

	func testPacketType() {
		let emptyFileAttrs = FileAttributes(sizeBytes: nil, userId: nil, groupId: nil, permissions: nil, accessDate: nil, modifyDate: nil, extensionData: [])
		let testcases: [(source: Packet, expected: jlsftp.DataLayer.PacketType?)] = [
			(source: .initializeV3(InitializePacketV3(version: .v3, extensionData: [])), .initialize),
			(source: .initializeV4(InitializePacketV4(version: .v3)), .initialize),
			(source: .version(VersionPacket(version: .v3, extensionData: [])), .version),
			(source: .open(OpenPacket(id: 0, filename: "", pflags: OpenFlags(), fileAttributes: emptyFileAttrs)), .open),
			(source: .close(ClosePacket(id: 0, handle: "")), .close),
			(source: .read(ReadPacket(id: 0, handle: "", offset: 0, length: 0)), .read),
			(source: .write(WritePacket(id: 0, handle: "", offset: 0)), .write),
			(source: .linkStatus(LinkStatusPacket(id: 0, path: "")), .linkStatus),
			(source: .handleStatus(HandleStatusPacket(id: 0, handle: "")), .handleStatus),
			(source: .setStatus(SetStatusPacket(id: 0, path: "", fileAttributes: emptyFileAttrs)), .setStatus),
			(source: .setHandleStatus(SetHandleStatusPacket(id: 0, handle: "", fileAttributes: emptyFileAttrs)), .setHandleStatus),
			(source: .openDirectory(OpenDirectoryPacket(id: 0, path: "")), .openDirectory),
			(source: .readDirectory(ReadDirectoryPacket(id: 0, handle: "")), .readDirectory),
			(source: .remove(RemovePacket(id: 0, filename: "")), .remove),
			(source: .makeDirectory(MakeDirectoryPacket(id: 0, path: "", fileAttributes: emptyFileAttrs)), .makeDirectory),
			(source: .removeDirectory(RemoveDirectoryPacket(id: 0, path: "")), .removeDirectory),
			(source: .realPath(RealPathPacket(id: 0, path: "")), .realPath),
			(source: .status(StatusPacket(id: 0, path: "")), .status),
			(source: .rename(RenamePacket(id: 0, oldPath: "", newPath: "")), .rename),
			(source: .readLink(ReadLinkPacket(id: 0, path: "")), .readLink),
			(source: .createSymbolicLink(CreateSymbolicLinkPacket(id: 0, linkPath: "", targetPath: "")), .createSymbolicLink),
			(source: .statusReply(StatusReplyPacket(id: 0, statusCode: .ok, errorMessage: "", languageTag: "")), .statusReply),
			(source: .handleReply(HandleReplyPacket(id: 0, handle: "")), .handleReply),
			(source: .dataReply(DataReplyPacket(id: 0)), .dataReply),
			(source: .nameReply(NameReplyPacket(id: 0, names: [])), .nameReply),
			(source: .attributesReply(FileAttributesReplyPacket(id: 0, fileAttributes: emptyFileAttrs)), .attributesReply),
			(source: .extended(ExtendedPacket(id: 0, extendedRequest: "")), .extended),
			(source: .extendedReply(ExtendedReplyPacket(id: 0)), .extendedReply),

			(source: .nopDebug(NOPDebugPacket(message: "")), nil),
		]

		for (source, expected) in testcases {
			XCTAssertEqual(expected, source.packetType)
		}
	}

	static var allTests = [
		("testPacketType", testPacketType),
	]
}
