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
		testCase(InitializePacketSerializationHandlerTests),
		testCase(OpenPacketSerializationHandlerTests),
		testCase(ReadPacketSerializationHandlerTests),
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
		// Packets
		// Utilities
		testCase(DataExtensions.allTests),
		//
		testCase(jlsftpTests.allTests),
	]
}
#endif
