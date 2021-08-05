import Foundation

extension Date {
	var timespec: timespec {
		let delta = timeIntervalSince1970
		let seconds = delta.rounded(.down)
		let ns = (delta - seconds) * 1_000_000_000
		return Darwin.timespec(tv_sec: Int(seconds), tv_nsec: Int(ns))
	}
}
