import Foundation

/**
 Returns the requested file or folder name(s).

 - Tag: NameReplyPacket
 - Since: sftp v3
 */
public class NameReplyPacket: BasePacket {

	public struct Name {
		/**
		 The relative or absolute name of a file or folder within the requested
		 directory, depending on the request.

		 - Since: sftp v3
		 */
		public let filename: String
		/**
		 An undefined string representation of the file or folder, for display
		 purposes.

		 - Since: sftp v3
		 - Note: This should not be attempted to be parsed. The recommended
		 format of this string is:
		 ```
		 -rwxr-xr-x   1 mjos     staff      348911 Mar 25 14:29 t-filexfer
		 1234567890 123 12345678 12345678 12345678 123456789012
		 ```
		 */
		public let longName: String
		/**
		 The file attributes of the file or folder.

		 - Since: sftp v3
		 */
		public let fileAttributes: FileAttributes
	}

	/**
	 Request identifier.

	 - Since: sftp v3
	 */
	public let id: PacketId
	/**
	 The list of requested names.

	 - Since: sftp v3
	 */
	public let names: [Name]

	public init(id: PacketId, names: [Name]) {
		self.id = id
		self.names = names
	}
}
