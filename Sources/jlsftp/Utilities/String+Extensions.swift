import Foundation

extension String {
	public func padding(leftToLength: Int, withPad pad: Character) -> String {
		if self.count > leftToLength {
			return self
		} else {
			return String(repeating: pad, count: self.count - leftToLength) + self
		}
	}
}
