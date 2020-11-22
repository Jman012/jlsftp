import Foundation

public enum Packet: Equatable {
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

	case nopDebug(NOPDebugPacket)

	var packetType: jlsftp.SftpProtocol.PacketType? {
		switch self {
		case .initializeV3: return .initialize
		case .initializeV4: return .initialize
		case .version: return .version
		case .open: return .open
		case .close: return .close
		case .read: return .read
		case .write: return .write
		case .linkStatus: return .linkStatus
		case .handleStatus: return .handleStatus
		case .setStatus: return .setStatus
		case .setHandleStatus: return .setHandleStatus
		case .openDirectory: return .openDirectory
		case .readDirectory: return .readDirectory
		case .remove: return .remove
		case .makeDirectory: return .makeDirectory
		case .removeDirectory: return .removeDirectory
		case .realPath: return .realPath
		case .status: return .status
		case .rename: return .rename
		case .readLink: return .readLink
		case .createSymbolicLink: return .createSymbolicLink
		case .statusReply: return .statusReply
		case .handleReply: return .handleReply
		case .dataReply: return .dataReply
		case .nameReply: return .nameReply
		case .attributesReply: return .attributesReply
		case .extended: return .extended
		case .extendedReply: return .extendedReply

		case .nopDebug: return nil
		}
	}
}
