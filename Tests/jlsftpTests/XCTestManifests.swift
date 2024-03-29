import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
	return [
		// Fields
		testCase(FileAttributesTests.allTests),
		// Network
		testCase(BufferedDataPublisherTests.allTests),
		testCase(DemandBridgeSubjectTests.allTests),
		testCase(FutureSinkTests.allTests),
		testCase(NetworkingPublisherChainTests.allTests),
		testCase(SftpMessageTests.allTests),
		testCase(SftpPacketDecoderTests.allTests),
		testCase(SftpPacketEncoderTests.allTests),
		// Server
		testCase(BaseSftpServerTests.allTests),
		testCase(SftpServerInitializationTests.allTests),
		// Server > BaseSftpServer+Handles
		testCase(HandleCloseTests.allTests),
		testCase(HandleCreateSymbolicLinkTests.allTests),
		testCase(HandleHandleStatusTests.allTests),
		testCase(HandleLinkStatusTests.allTests),
		testCase(HandleMakeDirectoryTests.allTests),
		testCase(HandleOpenDirectoryTests.allTests),
		testCase(HandleOpenTests.allTests),
		testCase(HandleReadLinkTests.allTests),
		testCase(HandleReadTests.allTests),
		testCase(HandleRealPathTests.allTests),
		testCase(HandleRemoveTests.allTests),
		testCase(HandleRemoveDirectoryTests.allTests),
		testCase(HandleRenameTests.allTests),
		testCase(HandleSetHandleStatusTests.allTests),
		testcase(HandleSetStatusTests.allTests),
		testCase(HandleStatusTests.allTests),
		testCase(HandleWriteTests.allTests),
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
		testCase(ByteBufferExtenstionsTests.allTests),
		testCase(DateExtensionsTests.allTests),
		testCase(DateFormatterExtensionsTests.allTests),
		testCase(mode_tExtensionsTests.allTests),
		testCase(NIOFileHandleExtensionsTests.allTests),
		testCase(ResultExtensionTests.allTests),
		testCase(SequenceExtensionTests.allTests),
		testCase(StringExtensionsTests.allTests),
		testCase(SyscallTests.allTests),
		testCase(TimeSpecExtensionsTests.allTests),
		//
		testCase(jlsftpTests.allTests),
	]
}
#endif
