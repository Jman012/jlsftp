import Foundation

public struct PFlags: OptionSet {
	public let rawValue: UInt8

	public init(rawValue: UInt8) {
		self.rawValue = rawValue
	}

	/**
	 Open the file for reading.

	 - Since: sftp v3
	 - Remark: sftp reference: `SSH_FXF_READ`
	 */
	public static let read = PFlags(rawValue: 1 << 0)
	/**
	 Open the file for writing. If both this and `.read` are specified, the file
	 is opened for both reading and writing.

	 - Since: sftp v3
	 - Remark: sftp reference: `SSH_FXF_WRITE`
	 */
	public static let write = PFlags(rawValue: 1 << 1)
	/**
	 Force all writes to append data at the end of the file.

	 - Since: sftp v3
	 - Remark: sftp reference: `SSH_FXF_APPEND`
	 */
	public static let append = PFlags(rawValue: 1 << 2)
	/**
	 If this flag is specified, then a new file will be created if one does not
	 already exist (if `.truncate` is specified, the new file will be truncated
	 to zero length if it previously exists).

	 - Since: sftp v3
	 - Remark: sftp reference: `SSH_FXF_CREAT`
	 */
	public static let create = PFlags(rawValue: 1 << 3)
	/**
	 Forces an existing file with the same name to be truncated to zero length
	 when creating a file by specifying `.create`. `.create` MUST also be
	 specified if this flag is used.

	 - Since: sftp v3
	 - Remark: sftp reference: `SSH_FXF_TRUNC`
	 */
	public static let truncate = PFlags(rawValue: 1 << 4)
	/**
	 Causes the request to fail if the named file already exists. `.create` MUST
	 also be specified if this flag is used.

	 - Since: sftp v3
	 - Remark: sftp reference: `SSH_FXF_EXCL`
	 */
	public static let exclusive = PFlags(rawValue: 1 << 5)
}
