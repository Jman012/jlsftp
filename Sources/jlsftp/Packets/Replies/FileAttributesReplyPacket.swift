import Foundation

/**
 Returns the file attributes of the requested resource.

 - Tag: FileAttributesReplyPacket
 - Since: sftp v3
 */
public struct FileAttributesReplyPacket: BasePacket, Equatable {

	/**
	  Request identifier.

	  - Since: sftp v3
	 */
	public let id: PacketId
	/**
	  The file attributes of the file or folder.

	  - Since: sftp v3
	 */
	public let fileAttributes: FileAttributes

	public init(id: PacketId, fileAttributes: FileAttributes) {
		self.id = id
		self.fileAttributes = fileAttributes
	}
}
