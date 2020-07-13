import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
	return [
		// DataLayer > Version_3 > Handlers
		testCase(InitializePacketSerializationHandlerTests),
		// DataLayer > Version_3
		testCase(VersionPacketSerializationHandlerTests),
		testCase(FileAttributesSerializationV3Tests),
		testCase(OpenFlagsV3Tests),
		testCase(PacketSerializationV3Tests),
		testCase(PermissionsV3Tests),
		testCase(RawPacketSerializationV3Tests.allTests),
		// Fields
		// Packets
		// Utilities
		testCase(DataExtensions.allTests),
		testCase(SSHProtocolSerializationDraft9Tests),
		//
		testCase(jlftpTests.allTests),
	]
}
#endif
