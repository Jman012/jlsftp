import Foundation
import Combine
import NIO

public class SftpMessage {
	public let packet: Packet
	public let data: AnyPublisher<ByteBuffer, Never>

	private let totalBytes: UInt32
	private var subject: DemandBridgeSubject<ByteBuffer, Never>

	public init(packet: Packet, dataLength: UInt32, shouldReadHandler: @escaping DemandBridgeSubject<ByteBuffer, Never>.DemandHandler) {
		self.packet = packet
		self.totalBytes = dataLength
		self.subject = DemandBridgeSubject<ByteBuffer, Never>(handler: shouldReadHandler)
		self.data = subject
			.bufferedData(bufferSize: 10)
			.eraseToAnyPublisher()
	}
}
