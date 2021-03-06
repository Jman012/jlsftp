import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
	return [
		// Fields
		// Network
		testCase(SftpServerChannelHandlerTests.allTests),
		testCase(SftpPacketDecoderTests.allTests),
		testCase(SftpPacketEncoderTests.allTests),
		// Packets
		testCase(PacketTests.allTests),
		// Server
		testCase(BaseSftpServerTests.allTests),
		testCase(SftpServerInitializationTests.allTests),
		// SftpProtocol > Version_3 > Reply Handlers
		testCase(DataReplyPacketSerializationHandlerTests.allTests),
		testCase(ExtendedReplyPacketSerializationHandlerTests.allTests),
		testCase(FileAttributesSerializationV3Tests.allTests),
		testCase(HandleReplyPacketSerializationHandlerTests.allTests),
		testCase(NameReplyPacketSerializationHandlerTests.allTests),
		testCase(StatusReplyPacketSerializationHandlerTests.allTests),
		testCase(VersionPacketSerializationHandlerTests.allTests),
		// SftpProtocol > Version_3 > Request Handlers
		testCase(ClosePacketSerializationHandlerTests.allTests),
		testCase(CreateSymbolicLinkSerializationHandlerTests.allTests),
		testCase(ExtendedPacketSerializationHandlerTests.allTests),
		testCase(HandleStatusPacketSerializationHandlerTests.allTests),
		testCase(InitializePacketSerializationHandlerTests.allTests),
		testCase(LinkStatusPacketSerializationHandlerTests.allTests),
		testCase(MakeDirectoryPacketSerializationHandlerTests.allTests),
		testCase(OpenDirectoryPacketSerializationHandlerTests.allTests),
		testCase(OpenPacketSerializationHandlerTests.allTests),
		testCase(ReadDirectoryPacketSerializationHandlerTests.allTests),
		testCase(ReadLinkPacketSerializationHandlerTests.allTests),
		testCase(ReadPacketSerializationHandlerTests.allTests),
		testCase(RealPathPacketSerializationHandlerTests.allTests),
		testCase(RemoveDirectoryPacketSerializationHandlerTests.allTests),
		testCase(RemovePacketSerializationHandlerTests.allTests),
		testCase(RenamePacketSerializationHandlerTests.allTests),
		testCase(SetHandleStatusPacketSerializationHandlerTests.allTests),
		testCase(SetStatusPacketSerializationHandlerTests.allTests),
		testCase(StatusPacketSerializationHandlerTests.allTests),
		testcase(WritePacketSerializationHandlerTests.allTests),
		// SftpProtocol > Version_3
		testCase(FileAttributesSerializationV3Tests.allTests),
		testCase(OpenFlagsV3Tests.allTests),
		testCase(PacketSerializerV3Tests.allTests),
		testCase(PermissionsV3Tests.allTests),
		testCase(StatusCodeV3Tests.allTests),
		// SftpProtocol
		testCase(NotSupportedPacketSerializationHandlerTests.allTests),
		testCase(PacketSerializationHandlerTests.allTests),
		testCase(PacketSerializerTests.allTests),
		testCase(PacketTypeTests.allTests),
		testCase(SftpVersionTests.allTests),
		// Utilities
		testCase(mode_tExtensionsTests.allTests),
		testCase(NIOFileHandleExtensionsTests.allTests),
		testCase(ResultExtensionTests.allTests),
		testCase(SequenceExtensionTests.allTests),
		//
		testCase(jlsftpTests.allTests),
	]
}
#endif
