import Foundation

extension jlsftp.DataLayer.Version_3 {

	public class PacketSerializerV3: BasePacketSerializer {

		public init() {
			super.init(handlers: [
				.initialize: jlsftp.DataLayer.Version_3.InitializePacketSerializationHandler(),
				.version: jlsftp.DataLayer.Version_3.VersionPacketSerializationHandler(),
				.open: jlsftp.DataLayer.Version_3.OpenPacketSerializationHandler(),
				.close: jlsftp.DataLayer.Version_3.ClosePacketSerializationHandler(),
				.read: jlsftp.DataLayer.Version_3.ReadPacketSerializationHandler(),
				.write: jlsftp.DataLayer.Version_3.WritePacketSerializationHandler(),
				.linkStatus: jlsftp.DataLayer.Version_3.LinkStatusPacketSerializationHandler(),
				.handleStatus: jlsftp.DataLayer.Version_3.HandleStatusPacketSerializationHandler(),
				.setStatus: jlsftp.DataLayer.Version_3.SetStatusPacketSerializationHandler(),
				.setHandleStatus: jlsftp.DataLayer.Version_3.SetHandleStatusPacketSerializationHandler(),
				.openDirectory: jlsftp.DataLayer.Version_3.OpenDirectoryPacketSerializationHandler(),
				.readDirectory: jlsftp.DataLayer.Version_3.ReadDirectoryPacketSerializationHandler(),
				.remove: jlsftp.DataLayer.Version_3.RemovePacketSerializationHandler(),
				.makeDirectory: jlsftp.DataLayer.Version_3.MakeDirectoryPacketSerializationHandler(),
				.realPath: jlsftp.DataLayer.Version_3.RealPathPacketSerializationHandler(),
				.status: jlsftp.DataLayer.Version_3.StatusPacketSerializationHandler(),
				.rename: jlsftp.DataLayer.Version_3.RenamePacketSerializationHandler(),
				.readLink: jlsftp.DataLayer.Version_3.ReadLinkPacketSerializationHandler(),
				.createSymbolicLink: jlsftp.DataLayer.Version_3.CreateSymbolicLinkPacketSerializationHandler(),
				.statusReply: jlsftp.DataLayer.Version_3.StatusReplyPacketSerializationHandler(),
				.handleReply: jlsftp.DataLayer.Version_3.HandleReplyPacketSerializationHandler(),
				.dataReply: jlsftp.DataLayer.Version_3.DataReplyPacketSerializationHandler(),
				.nameReply: jlsftp.DataLayer.Version_3.NameReplyPacketSerializationHandler(),
				.attributesReply: jlsftp.DataLayer.Version_3.FileAttributesReplyPacketSerializationHandler(),
				.extended: jlsftp.DataLayer.Version_3.ExtendedPacketSerializationHandler(),
				.extendedReply: jlsftp.DataLayer.Version_3.ExtendedReplyPacketSerializationHandler(),
			], unhandledTypeHandler: NotSupportedPacketSerializationHandler())
		}
	}
}
