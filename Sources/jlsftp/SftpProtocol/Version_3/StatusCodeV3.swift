import Foundation

extension jlsftp.SftpProtocol.Version_3 {

	public enum StatusCodeV3: UInt32 {

		/**
		  Indicates successful completion of the operation.

		  - Since: sftp v3
		  - Remark: sftp reference: `SSH_FX_OK`
		 */
		case ok = 0

		/**
		  Indicates end-of-file condition; for `SSH_FX_READ` it means that no more
		  data is available in the file, and for `SSH_FX_READDIR` it indicates that
		  no more files are contained in the directory.

		  - Since: sftp v3
		  - Remark: sftp reference: `SSH_FX_EOF`
		 */
		case endOfFile = 1

		/**
		  Is returned when a reference is made to a file which should exist but
		  doesn't.

		  - Since: sftp v3
		  - Remark: sftp reference: `SSH_FX_NO_SUCH_FILE`
		 */
		case noSuchFile = 2

		/**
		  Is returned when the authenticated user does not have sufficient
		  permissions to perform the operation.

		  - Since: sftp v3
		  - Remark: sftp reference: `SSH_FX_PERMISSION_DENIED`
		 */
		case permissionDenied = 3

		/**
		  Is a generic catch-all error message; it should be returned if an error
		  occurs for which there is no more specific error code defined.

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FX_FAILURE`
		 */
		case failure = 4

		/**
		  May be returned if a badly formatted packet or protocol incompatibility is
		  detected.

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FX_BAD_MESSAGE`
		 */
		case badMessage = 5

		/**
		  Is a pseudo-error which indicates that the client has no connection to the
		  server (it can only be generated locally by the client, and MUST NOT be
		  returned by servers).

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FX_NO_CONNECTION`
		 */
		case noConnection = 6

		/**
		  Is a pseudo-error which indicates that the connection to the server has
		  been lost (it can only be generated locally by the client, and MUST NOT be
		  returned by servers).

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FX_CONNECTION_LOST`
		 */
		case connectionLost = 7

		/**
		  Indicates that an attempt was made to perform an operation which is not
		  supported for the server (it may be generated locally by the client if e.g.
		  the version number exchange indicates that a required feature is not
		  supported by the server, or it may be returned by the server if the server
		  does not implement an operation).

		  - Since: sftp v3
		  - Remark: sftp reference: `SSH_FX_OP_UNSUPPORTED`
		 */
		case operationUnsupported = 8

		public init(from statusCode: StatusCode) {
			self = StatusCodeV3.createFrom(statusCode: statusCode)
		}

		public static func createFrom(statusCode: StatusCode) -> StatusCodeV3 {
			switch statusCode {
			case .ok: return .ok
			case .endOfFile: return .endOfFile
			case .noSuchFile: return .noSuchFile
			case .permissionDenied: return .permissionDenied
			case .failure: return .failure
			case .badMessage: return .badMessage
			case .noConnection: return .noConnection
			case .connectionLost: return .connectionLost
			case .operationUnsupported: return .operationUnsupported
			}
		}

		var statusCode: StatusCode {
			switch self {
			case .ok: return .ok
			case .endOfFile: return .endOfFile
			case .noSuchFile: return .noSuchFile
			case .permissionDenied: return .permissionDenied
			case .failure: return .failure
			case .badMessage: return .badMessage
			case .noConnection: return .noConnection
			case .connectionLost: return .connectionLost
			case .operationUnsupported: return .operationUnsupported
			}
		}
	}
}
