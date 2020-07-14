import Foundation

public enum Endian {
	case networkOrder
	case hostOrder
}

extension Data {

	// MARK: - Data to Integer Conversion

	func to<T>(_: T.Type, from endian: Endian) -> T? where T: FixedWidthInteger {
		var value: T = 0
		guard self.count == MemoryLayout.size(ofValue: value) else { return nil }

		// Assume self data is Little Endian, or Host Byte Order.
		_ = Swift.withUnsafeMutableBytes(of: &value, { self.copyBytes(to: $0) })

		// If the endianness of the data is actually Big Endian, or Network
		// Byte Order, then swap the bytes.
		if endian == .networkOrder {
			return value.byteSwapped
		}

		return value
	}

	/**
	 Splits the Data sequences into a prefix and suffix based on the maxLength.
	 */
	func split(maxLength: Int) -> (prefix: Data.SubSequence, suffix: Data.SubSequence) {
		let prefix = self.prefix(maxLength)
		let suffix = self.suffix(Swift.max(0, self.count - maxLength))

		return (prefix, suffix)
	}
}
