import Foundation

extension jlsftp.SftpProtocol {

	public enum SftpVersion: UInt32 {
		case v3 = 3
		case v4 = 4
		case v5 = 5
		case v6 = 6
	}
}
