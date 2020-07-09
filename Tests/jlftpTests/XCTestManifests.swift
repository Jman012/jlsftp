import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
	return [
		testCase(InitializePacketSerializationHandlerTests),
		testCase(VersionPacketSerializationHandlerTests),
		testCase(PacketSerializationV3Tests),
		testCase(RawPacketSerializationV3Tests.allTests),
		testCase(FileAttributesTests),
		testCase(DataExtensions.allTests),
		testCase(SSHProtocolSerializationDraft9Tests),
		testCase(jlftpTests.allTests),
	]
}
#endif
