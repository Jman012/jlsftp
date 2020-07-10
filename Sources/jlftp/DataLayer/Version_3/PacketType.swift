import Foundation

extension jlftp.DataLayer.Version_3 {

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

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXP_LSTAT`
		  */
		case lState = 7

		/**

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXP_FSTAT`
		  */
		case fStat = 8

		/**
		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXP_SETSTAT`
		  */
		case setStat = 9

		/**

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXP_FSETSTAT`
		  */
		case fSetStat = 10

		/**

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXP_OPENDIR`
		  */
		case openDirectory = 11

		/**

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

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXP_MKDIR`
		  */
		case makeDirectory = 14

		/**

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXP_RMDIR`
		  */
		case removeDirectory = 15

		/**

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXP_REALPATH`
		  */
		case realPath = 16

		/**

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXP_STAT`
		  */
		case stat = 17

		/**

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXP_RENAME`
		  */
		case rename = 18

		/**

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXP_READLINK`
		  */
		case readLink = 19

		/**

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXP_SYMLINK`
		  */
		case symbolicLink = 20

		/**

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXP_STATUS`
		  */
		case status = 101

		/**

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXP_HANDLE`
		  */
		case handle = 102

		/**

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXP_DATA`
		  */
		case data = 103

		/**

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXP_NAME`
		  */
		case name = 104

		/**

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXP_ATTRS`
		  */
		case attributes = 105

		/**

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXP_EXTENDED`
		  */
		case extended = 200

		/**

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXP_EXTENDED_REPLY`
		  */
		case extendedApply = 201
	}
}
