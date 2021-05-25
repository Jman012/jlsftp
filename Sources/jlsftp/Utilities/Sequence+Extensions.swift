import Foundation

extension Sequence where Element: Strideable {
	var elementsAreContiguous: Bool {
		let elements = self.sorted()
		for (left, right) in zip(elements.dropLast(), elements.dropFirst()) {
			if left.distance(to: right) != 1 {
				return false
			}
		}
		return true
	}
}
