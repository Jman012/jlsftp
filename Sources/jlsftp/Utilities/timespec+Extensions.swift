import Foundation

extension timespec {
	var date: Date {
		return Date(timeIntervalSince1970: Double(self.tv_sec) + (Double(self.tv_nsec) / Double(1_000_000_000)))
	}
}
