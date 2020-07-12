import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
	return [
		testCase(InitializePacketSerializationHandlerTests),
		testCase(VersionPacketSerializationHandlerTests),
		testCase(FileAttributesSerializationV3Tests),
		testCase(OpenFlagsV3Tests),
		testCase(PacketSerializationV3Tests),
		testCase(PermissionsV3Tests),
		testCase(RawPacketSerializationV3Tests.allTests),
		testCase(DataExtensions.allTests),
		testCase(SSHProtocolSerializationDraft9Tests),
		testCase(jlftpTests.allTests),
	]
}
#endif
