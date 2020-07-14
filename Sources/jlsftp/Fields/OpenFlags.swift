import Foundation

public enum OpenFlag {

	/**
	 Open the file for reading.

	 - Since: sftp v3
	 - Remark: sftp reference: `SSH_FXF_READ`
	 */
	case read

	/**
	 Open the file for writing. If both this and `.read` are specified, the file
	 is opened for both reading and writing.

	 - Since: sftp v3
	 - Remark: sftp reference: `SSH_FXF_WRITE`
	 */
	case write

	/**
	 Force all writes to append data at the end of the file.

	 - Since: sftp v3
	 - Remark: sftp reference: `SSH_FXF_APPEND`
	 */
	case append

	/**
	 If this flag is specified, then a new file will be created if one does not
	 already exist (if `.truncate` is specified, the new file will be truncated
	 to zero length if it previously exists).

	 - Since: sftp v3
	 - Remark: sftp reference: `SSH_FXF_CREAT`
	 */
	case create

	/**
	 Forces an existing file with the same name to be truncated to zero length
	 when creating a file by specifying `.create`. `.create` MUST also be
	 specified if this flag is used.

	 - Since: sftp v3
	 - Remark: sftp reference: `SSH_FXF_TRUNC`
	 */
	case truncate

	/**
	 Causes the request to fail if the named file already exists. `.create` MUST
	 also be specified if this flag is used.

	 - Since: sftp v3
	 - Remark: sftp reference: `SSH_FXF_EXCL`
	 */
	case exclusive
}

public typealias OpenFlags = Set<OpenFlag>
