import Foundation

extension Data {

	// MARK: - Data to Integer Conversion

	func to<T>(type _: T.Type) -> T? where T: ExpressibleByIntegerLiteral {
		var value: T = 0
		guard count >= MemoryLayout.size(ofValue: value) else { return nil }
		_ = Swift.withUnsafeMutableBytes(of: &value, { copyBytes(to: $0) })
		return value
	}
}
