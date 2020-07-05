import Foundation

extension jlftp.DataLayer.Version_3 {

	public enum PacketType: UInt8 {

		/**
		 `SSH_FXP_INIT` is a client-to-server packet that initializes an sftp
		 session, indicating the highest version that the client can handle.
		 */
		case initialize = 1

		/**
		 `SSH_FXP_VERSION` is a server-to-client packet, in response to
		 `SSH_FXP_INIT`, indicating the highest common version shared between the
		 client and server.
		 */
		case version = 2

		/**
		 `SSH_FXP_OPEN`
		 */
		case open = 3

		/**
		 `SSH_FXP_CLOSE`
		 */
		case close = 4

		/**
		 `SSH_FXP_READ`
		 */
		case read = 5

		/**
		 `SSH_FXP_WRITE`
		 */
		case write = 6

		/**
		 `SSH_FXP_LSTAT`
		 */
		case lState = 7

		/**
		 `SSH_FXP_FSTAT`
		 */
		case fStat = 8

		/**
		 `SSH_FXP_SETSTAT`
		 */
		case setStat = 9

		/**
		 `SSH_FXP_FSETSTAT`
		 */
		case fSetStat = 10

		/**
		 `SSH_FXP_OPENDIR`
		 */
		case openDirectory = 11

		/**
		 `SSH_FXP_READDIR`
		 */
		case readDirectory = 12

		/**
		 `SSH_FXP_REMOVE`
		 */
		case remove = 13

		/**
		 `SSH_FXP_MKDIR`
		 */
		case makeDirectory = 14

		/**
		 `SSH_FXP_RMDIR`
		 */
		case removeDirectory = 15

		/**
		 `SSH_FXP_REALPATH`
		 */
		case realPath = 16

		/**
		 `SSH_FXP_STAT`
		 */
		case stat = 17

		/**
		 `SSH_FXP_RENAME`
		 */
		case rename = 18

		/**
		 `SSH_FXP_READLINK`
		 */
		case readLink = 19

		/**
		 `SSH_FXP_SYMLINK`
		 */
		case symbolicLink = 20

		/**
		 `SSH_FXP_STATUS`
		 */
		case status = 101

		/**
		 `SSH_FXP_HANDLE`
		 */
		case handle = 102

		/**
		 `SSH_FXP_DATA`
		 */
		case data = 103

		/**
		 `SSH_FXP_NAME`
		 */
		case name = 104

		/**
		 `SSH_FXP_ATTRS`
		 */
		case attributes = 105

		/**
		 `SSH_FXP_EXTENDED`
		 */
		case extended = 200

		/**
		 `SSH_FXP_EXTENDED_REPLY`
		 */
		case extendedApply = 201
	}
}
