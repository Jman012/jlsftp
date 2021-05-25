import Foundation
import NIO

extension NIOFileHandle.Mode {
	init(fromOpenFlags openFlags: OpenFlags) {
		let mode = NIOFileHandle.Mode(openFlags.compactMap({ flag -> NIOFileHandle.Mode? in
			switch flag {
			case .read: return .read
			case .write: return .write
			default: return nil
			}
		}))
		self.init(rawValue: mode.rawValue)
	}
}

extension NIOFileHandle.Flags {
	static func jlsftp(fileAttributes: FileAttributes, openFlags: OpenFlags) -> NIOFileHandle.Flags {
		var flags: CInt = 0
		var mode: mode_t = 0
		if let permissions = fileAttributes.permissions {
			mode = mode_t(fromPermissions: permissions)
		}

		// Most systems do not equate (O_RDONLY | O_WRONLY) with (O_RDWR)
		if openFlags.contains(.read) && openFlags.contains(.write) {
			flags |= O_RDWR
		} else if openFlags.contains(.read) && !openFlags.contains(.write) {
			flags |= O_RDONLY
		} else if openFlags.contains(.read) && !openFlags.contains(.write) {
			flags |= O_WRONLY
		}

		flags |= openFlags.compactMap({ flag -> CInt? in
			switch flag {
			case .read: return nil
			case .write: return nil
			case .append: return O_APPEND
			case .create: return O_CREAT
			case .truncate: return O_TRUNC
			case .exclusive: return O_EXCL
			}
		}).reduce(0, |)

		flags |= O_NONBLOCK

		return NIOFileHandle.Flags.posix(flags: flags, mode: mode)
	}
}
