import Foundation

public enum Packet {
	case initializeV3(InitializePacketV3)
	case initializeV4(InitializePacketV4)
	case version(VersionPacket)
	case open(OpenPacket)
	case close(ClosePacket)
	case read(ReadPacket)
	case write(WritePacket)
	case linkStatus(LinkStatusPacket)
	case handleStatus(HandleStatusPacket)
	case setStatus(SetStatusPacket)
	case setHandleStatus(SetHandleStatusPacket)
	case openDirectory(OpenDirectoryPacket)
	case readDirectory(ReadDirectoryPacket)
	case remove(RemovePacket)
	case makeDirectory(MakeDirectoryPacket)
	case removeDirectory(RemoveDirectoryPacket)
	case realPath(RealPathPacket)
	case status(StatusPacket)
	case rename(RenamePacket)
	case readLink(ReadLinkPacket)
	case createSymbolicLink(CreateSymbolicLinkPacket)
	case statusReply(StatusReplyPacket)
	case handleReply(HandleReplyPacket)
	case dataReply(DataReplyPacket)
	case nameReply(NameReplyPacket)
	case attributesReply(FileAttributesReplyPacket)
	case extended(ExtendedPacket)
	case extendedReply(ExtendedReplyPacket)

	case serializationError(SerializationErrorPacket)
}
