import Foundation

extension jlsftp.SftpProtocol {

	public enum SftpVersion: UInt32, Comparable {

		case v3 = 3
		case v4 = 4
		case v5 = 5
		case v6 = 6

		public static func < (lhs: Self, rhs: Self) -> Bool {
			return lhs.rawValue < rhs.rawValue
		}

		public static let min: SftpVersion = .v3
		public static let max: SftpVersion = .v6
	}
}
