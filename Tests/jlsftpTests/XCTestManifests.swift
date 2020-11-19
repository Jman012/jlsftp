import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
	return [
		// DataLayer > Version_3 > Reply Handlers
		testCase(DataReplyPacketSerializationHandlerTests),
		testCase(FileAttributesSerializationV3Tests),
		testCase(HandleReplyPacketSerializationHandlerTests),
		testCase(NameReplyPacketSerializationHandlerTests),
		testCase(StatusReplyPacketSerializationHandlerTests),
		testCase(VersionPacketSerializationHandlerTests),
		// DataLayer > Version_3 > Request Handlers
		testCase(ClosePacketSerializationHandlerTests),
		testCase(CreateSymbolicLinkSerializationHandlerTests),
		testCase(HandleStatusPacketSerializationHandlerTests),
		testCase(InitializePacketSerializationHandlerTests),
		testCase(LinkStatusPacketSerializationHandlerTests),
		testCase(MakeDirectoryPacketSerializationHandlerTests),
		testCase(OpenDirectoryPacketSerializationHandlerTests),
		testCase(OpenPacketSerializationHandlerTests),
		testCase(ReadDirectoryPacketSerializationHandlerTests),
		testCase(ReadLinkPacketSerializationHandlerTests),
		testCase(ReadPacketSerializationHandlerTests),
		testCase(RealPathPacketSerializationHandlerTests),
		testCase(RemoveDirectoryPacketSerializationHandlerTests),
		testCase(RemovePacketSerializationHandlerTests),
		testCase(RenamePacketSerializationHandlerTests),
		testCase(SetHandleStatusPacketSerializationHandlerTests),
		testCase(SetStatusPacketSerializationHandlerTests),
		testCase(StatusPacketSerializationHandlerTests),
		testcase(WritePacketSerializationHandlerTests),
		// DataLayer > Version_3
		testCase(FileAttributesSerializationV3Tests),
		testCase(OpenFlagsV3Tests),
		testCase(PacketSerializerV3Tests),
		testCase(PermissionsV3Tests),
		testCase(StatusCodeV3Tests),
		// DataLayer
		testCase(NotSupportedHandlerTests),
		testCase(PacketSerializerTests),
		testCase(PacketTypeTests),
		// Fields
		// Network
		testCase(SftpPacketDecoderTests),
		// Packets
		// Utilities
		testCase(DataExtensions.allTests),
		//
		testCase(jlsftpTests.allTests),
	]
}
#endif
