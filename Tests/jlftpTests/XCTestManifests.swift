import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
	return [
		testCase(InitializePacketParserHandlerTests),
		testCase(VersionPacketParserHandlerTests),
		testCase(PacketParserTests),
		testCase(RawPacketParserTests.allTests),
		testCase(DataExtensions.allTests),
		testCase(jlftpTests.allTests),
	]
}
#endif
