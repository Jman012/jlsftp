import Foundation

extension FixedWidthInteger {
	/// The number of bytes in the current binary representation of this value.
	static var byteWidth: Int {
		return self.bitWidth / 8 // 8 bits per byte
	}
}
