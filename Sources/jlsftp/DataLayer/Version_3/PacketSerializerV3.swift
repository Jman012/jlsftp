import Foundation

extension jlsftp.DataLayer.Version_3 {

	public class PacketSerializerV3: BasePacketSerializer {

		public init() {
			super.init(handlers: [
				.initialize: jlsftp.DataLayer.Version_3.InitializePacketSerializationHandler(),
				.version: jlsftp.DataLayer.Version_3.VersionPacketSerializationHandler(),
			], unhandledTypeHandler: NotSupportedHandler())
		}
	}
}
