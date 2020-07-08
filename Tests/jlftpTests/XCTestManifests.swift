import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
	return [
		testCase(InitializePacketParserHandlerTests),
		testCase(VersionPacketParserHandlerTests),
		testCase(PacketParserTests),
		testCase(RawPacketParserTests.allTests),
		testCase(FileAttributesTests),
		testCase(DataExtensions.allTests),
		testCase(SSHProtocolParserDraft9Tests),
		testCase(jlftpTests.allTests),
	]
}
#endif
