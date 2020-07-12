import Foundation

extension jlftp.DataLayer.Version_3 {

	/// - Remark: See [https://tools.ietf.org/html/draft-ietf-secsh-filexfer-02#section-6.3]()
	public struct OpenFlagsV3: OptionSet {
		public let rawValue: UInt8

		public init(rawValue: UInt8) {
			self.rawValue = rawValue
		}

		/**
		 Open the file for reading.

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXF_READ`
		 */
		public static let read = OpenFlagsV3(rawValue: 0x0000_0001)
		/**
		 Open the file for writing. If both this and `.read` are specified, the file
		 is opened for both reading and writing.

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXF_WRITE`
		 */
		public static let write = OpenFlagsV3(rawValue: 0x0000_0002)
		/**
		 Force all writes to append data at the end of the file.

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXF_APPEND`
		 */
		public static let append = OpenFlagsV3(rawValue: 0x0000_0004)
		/**
		 If this flag is specified, then a new file will be created if one does not
		 already exist (if `.truncate` is specified, the new file will be truncated
		 to zero length if it previously exists).

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXF_CREAT`
		 */
		public static let create = OpenFlagsV3(rawValue: 0x0000_0008)
		/**
		 Forces an existing file with the same name to be truncated to zero length
		 when creating a file by specifying `.create`. `.create` MUST also be
		 specified if this flag is used.

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXF_TRUNC`
		 */
		public static let truncate = OpenFlagsV3(rawValue: 0x0000_0010)
		/**
		 Causes the request to fail if the named file already exists. `.create` MUST
		 also be specified if this flag is used.

		 - Since: sftp v3
		 - Remark: sftp reference: `SSH_FXF_EXCL`
		 */
		public static let exclusive = OpenFlagsV3(rawValue: 0x0000_0020)

		public static let all: OpenFlagsV3 = [.read, .write, .append, .create, .truncate, .exclusive]

		public var openFlags: OpenFlags {
			var openFlags = OpenFlags()

			if self.contains(.read) { openFlags.insert(.read) }
			if self.contains(.write) { openFlags.insert(.write) }
			if self.contains(.append) { openFlags.insert(.append) }
			if self.contains(.create) { openFlags.insert(.create) }
			if self.contains(.truncate) { openFlags.insert(.truncate) }

			return openFlags
		}

		public init(openFlags: OpenFlags) {
			var openFlagsV3 = OpenFlagsV3()

			// Converts standard flags to version-specific flags, in bitwise form.
			// Note that if OpenFlags gains more cases that don't map to this
			// version, this initializer should be transformed into an optional
			// initializer that fails on unknown options.
			for flag in openFlags {
				switch flag {
				case .read: openFlagsV3.insert(.read)
				case .write: openFlagsV3.insert(.write)
				case .append: openFlagsV3.insert(.append)
				case .create: openFlagsV3.insert(.create)
				case .truncate: openFlagsV3.insert(.truncate)
				case .exclusive: openFlagsV3.insert(.exclusive)
				}
			}

			self.rawValue = openFlagsV3.rawValue
		}
	}
}
