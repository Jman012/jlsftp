import Foundation

extension jlsftp.DataLayer {

	public enum PacketType: UInt8 {

		/**
		 Initializes an sftp session with the server, indicating the highest
		 version that the client can handle.

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXP_INIT`
		 */
		case initialize = 1

		/**
		 The response to `.initialize`, indicating the highest common version
		 shared between the client and server.

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXP_VERSION`
		 */
		case version = 2

		/**
		 Opens and/or creates a file on the server.

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXP_OPEN`
		 */
		case open = 3

		/**
		 Closes a file on the server. The handle becomes invalid immediately
		 after this request has been sent.

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXP_CLOSE`
		 */
		case close = 4

		/**
		 Reads contents of a file handle on the server.

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXP_READ`
		  */
		case read = 5

		/**
		 Writes data to a file handle on the server.

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXP_WRITE`
		  */
		case write = 6

		/**
		 Retrieves the file attribute status of a path on the server. This is
		 similar to `.status`, except that for symbolically linked paths, this
		 returns the file attributes of the link itself.

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXP_LSTAT`
		  */
		case linkStatus = 7

		/**
		 Retrieves the file attribute status of a handle on the server,
		 previously opened via `.openDirectory` or `.open`.

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXP_FSTAT`
		  */
		case handleStatus = 8

		/**
		 Sets file attributes on a path on the server. This is used for
		 operations such as changing the ownership, permissions or access times,
		 as well as for truncating a file.

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXP_SETSTAT`
		  */
		case setStatus = 9

		/**
		 Sets file attributes on an opened handle on the server. This is used
		 for operations such as changing the ownership, permissions or access
		 times, as well as for truncating a file.

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXP_FSETSTAT`
		  */
		case setHandleStatus = 10

		/**
		 Opens a directory on the server for reading. See `.readDirectory`.

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXP_OPENDIR`
		  */
		case openDirectory = 11

		/**
		 Reads the contents of the directory. May be called multiple times to
		 get a complete listing. Directory should be closed after client is done
		 reading, using `.close`.

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXP_READDIR`
		  */
		case readDirectory = 12

		/**
		 Removes a file from the server.

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXP_REMOVE`
		 - Note: This can not remove directories.
		  */
		case remove = 13

		/**
		 Creates new a directory on the server.

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXP_MKDIR`
		  */
		case makeDirectory = 14

		/**
		 Removes a directory on the server.

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXP_RMDIR`
		  */
		case removeDirectory = 15

		/**
		 Retrieves the canonical path of a remote resource.

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXP_REALPATH`
		  */
		case realPath = 16

		/**
		 Retrieves the file attribute status of a path on the server. This is
		 similar to `.linkStatus`, except that for symbolically linked paths,
		 this returns the file attributes of the linked file, and not the link
		 itself.

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXP_STAT`
		  */
		case status = 17

		/**
		 Renames a path on the server.

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXP_RENAME`
		  */
		case rename = 18

		/**
		 Reads the target of a symbolic link on the server.

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXP_READLINK`
		  */
		case readLink = 19

		/**
		 Creates a symbolic link to a target on the server.

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXP_SYMLINK`
		  */
		case createSymbolicLink = 20

		/**

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXP_STATUS`
		  */
		case statusReply = 101

		/**

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXP_HANDLE`
		  */
		case handleReply = 102

		/**

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXP_DATA`
		  */
		case dataReply = 103

		/**

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXP_NAME`
		  */
		case nameReply = 104

		/**

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXP_ATTRS`
		  */
		case attributesReply = 105

		/**

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXP_EXTENDED`
		  */
		case extended = 200

		/**

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXP_EXTENDED_REPLY`
		  */
		case extendedReply = 201

		public static func allPacketTypes(for sftpVersion: SftpVersion) -> Set<PacketType> {
			switch sftpVersion {
			case .v3:
				return [
					.initialize,
					.version,
					.open,
					.close,
					.read,
					.write,
					.linkStatus,
					.handleStatus,
					.setStatus,
					.setHandleStatus,
					.openDirectory,
					.readDirectory,
					.remove,
					.makeDirectory,
					.removeDirectory,
					.realPath,
					.status,
					.rename,
					.readLink,
					.createSymbolicLink,
					.statusReply,
					.handleReply,
					.dataReply,
					.nameReply,
					.attributesReply,
					.extended,
					.extendedReply,
				]
			case .v4:
				return PacketType.allPacketTypes(for: .v3).union([])
			case .v5:
				return PacketType.allPacketTypes(for: .v4).union([])
			case .v6:
				return PacketType.allPacketTypes(for: .v5).union([])
			}
		}

		var hasBody: Bool {
			switch self {
			case .write,
				 .dataReply,
				 .extended,
				 .extendedReply:
				return true
			default:
				return false
			}
		}
	}
}
