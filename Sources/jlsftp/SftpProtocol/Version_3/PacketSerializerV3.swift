import Foundation

extension jlsftp.SftpProtocol.Version_3 {

	public class PacketSerializerV3: BasePacketSerializer {

		public init() {
			super.init(handlers: [
				.initialize: jlsftp.SftpProtocol.Version_3.InitializePacketSerializationHandler(),
				.version: jlsftp.SftpProtocol.Version_3.VersionPacketSerializationHandler(),
				.open: jlsftp.SftpProtocol.Version_3.OpenPacketSerializationHandler(),
				.close: jlsftp.SftpProtocol.Version_3.ClosePacketSerializationHandler(),
				.read: jlsftp.SftpProtocol.Version_3.ReadPacketSerializationHandler(),
				.write: jlsftp.SftpProtocol.Version_3.WritePacketSerializationHandler(),
				.linkStatus: jlsftp.SftpProtocol.Version_3.LinkStatusPacketSerializationHandler(),
				.handleStatus: jlsftp.SftpProtocol.Version_3.HandleStatusPacketSerializationHandler(),
				.setStatus: jlsftp.SftpProtocol.Version_3.SetStatusPacketSerializationHandler(),
				.setHandleStatus: jlsftp.SftpProtocol.Version_3.SetHandleStatusPacketSerializationHandler(),
				.openDirectory: jlsftp.SftpProtocol.Version_3.OpenDirectoryPacketSerializationHandler(),
				.readDirectory: jlsftp.SftpProtocol.Version_3.ReadDirectoryPacketSerializationHandler(),
				.remove: jlsftp.SftpProtocol.Version_3.RemovePacketSerializationHandler(),
				.makeDirectory: jlsftp.SftpProtocol.Version_3.MakeDirectoryPacketSerializationHandler(),
				.realPath: jlsftp.SftpProtocol.Version_3.RealPathPacketSerializationHandler(),
				.status: jlsftp.SftpProtocol.Version_3.StatusPacketSerializationHandler(),
				.rename: jlsftp.SftpProtocol.Version_3.RenamePacketSerializationHandler(),
				.readLink: jlsftp.SftpProtocol.Version_3.ReadLinkPacketSerializationHandler(),
				.createSymbolicLink: jlsftp.SftpProtocol.Version_3.CreateSymbolicLinkPacketSerializationHandler(),
				.statusReply: jlsftp.SftpProtocol.Version_3.StatusReplyPacketSerializationHandler(),
				.handleReply: jlsftp.SftpProtocol.Version_3.HandleReplyPacketSerializationHandler(),
				.dataReply: jlsftp.SftpProtocol.Version_3.DataReplyPacketSerializationHandler(),
				.nameReply: jlsftp.SftpProtocol.Version_3.NameReplyPacketSerializationHandler(),
				.attributesReply: jlsftp.SftpProtocol.Version_3.FileAttributesReplyPacketSerializationHandler(),
				.extended: jlsftp.SftpProtocol.Version_3.ExtendedPacketSerializationHandler(),
				.extendedReply: jlsftp.SftpProtocol.Version_3.ExtendedReplyPacketSerializationHandler(),
			], unhandledTypeHandler: NotSupportedPacketSerializationHandler())
		}
	}
}
