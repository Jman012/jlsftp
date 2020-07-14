import Foundation

public enum ErrorStatusCode: Error {

	/**
	 Indicates successful completion of the operation.

	 - Since: sftp v3
	 - Remark: sftp reference: `SSH_FX_OK`
	 */
	case ok

	/**
	 Indicates end-of-file condition; for `SSH_FX_READ` it means that no more
	 data is available in the file, and for `SSH_FX_READDIR` it indicates that
	 no more files are contained in the directory.

	 - Since: sftp v3
	 - Remark: sftp reference: `SSH_FX_EOF`
	 */
	case endOfFile

	/**
	 Is returned when a reference is made to a file which should exist but
	 doesn't.

	 - Since: sftp v3
	 - Remark: sftp reference: `SSH_FX_NO_SUCH_FILE`
	 */
	case noSuchFile

	/**
	 Is returned when the authenticated user does not have sufficient
	 permissions to perform the operation.

	 - Since: sftp v3
	 - Remark: sftp reference: `SSH_FX_PERMISSION_DENIED`
	 */
	case permissionDenied

	/**
	 Is a generic catch-all error message; it should be returned if an error
	 occurs for which there is no more specific error code defined.

	 - Since: sftp v3
	 - Remark: sftp reference: `SSH_FX_FAILURE`
	 */
	case failure

	/**
	 May be returned if a badly formatted packet or protocol incompatibility is
	 detected.

	 - Since: sftp v3
	 - Remark: sftp reference: `SSH_FX_BAD_MESSAGE`
	 */
	case badMessage

	/**
	 Is a pseudo-error which indicates that the client has no connection to the
	 server (it can only be generated locally by the client, and MUST NOT be
	 returned by servers).

	 - Since: sftp v3
	 - Remark: sftp reference: `SSH_FX_NO_CONNECTION`
	 */
	case noConnection

	/**
	 Is a pseudo-error which indicates that the connection to the server has
	 been lost (it can only be generated locally by the client, and MUST NOT be
	 returned by servers).

	 - Since: sftp v3
	 - Remark: sftp reference: `SSH_FX_CONNECTION_LOST`
	 */
	case connectionLost

	/**
	 Indicates that an attempt was made to perform an operation which is not
	 supported for the server (it may be generated locally by the client if e.g.
	 the version number exchange indicates that a required feature is not
	 supported by the server, or it may be returned by the server if the server
	 does not implement an operation).

	 - Since: sftp v3
	 - Remark: sftp reference: `SSH_FX_OP_UNSUPPORTED`
	 */
	case operationUnsupported
}
