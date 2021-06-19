import Foundation
import Combine
import NIO

/**
 A class that packages together an sftp packet header along with its optional
 data body, by providing a bridge between Swift NIO and Swift Combine. The
 paired SftpChannelHandler pipes the incoming data into the Subject this creates.
 */
public class SftpMessage {

	public enum SendDataError: Error, Equatable {
		case tooMuchData(String)
	}

	public let packet: Packet
	public let data: AnyPublisher<ByteBuffer, Never>
	public let totalBodyBytes: UInt32
	
	private var remainingBytes: UInt32
	private var subject: DemandBridgeSubject<ByteBuffer, Never>

	public init(packet: Packet, dataLength: UInt32, shouldReadHandler: @escaping DemandBridgeSubject<ByteBuffer, Never>.DemandHandler) {
		self.packet = packet
		self.totalBodyBytes = dataLength
		self.remainingBytes = dataLength
		self.subject = DemandBridgeSubject<ByteBuffer, Never>(handler: shouldReadHandler)
		self.data = subject
			.bufferedData(bufferSize: 10)
			.eraseToAnyPublisher()
	}

	public func sendData(_ buffer: ByteBuffer) -> Result<Bool, SendDataError> {
		if buffer.readableBytes > remainingBytes {
			subject.send(completion: .finished)
			return .failure(SendDataError.tooMuchData("Unexpected error: Too many bytes encountered in body of sftp packet"))
		}

		subject.send(buffer)

		remainingBytes -= UInt32(buffer.readableBytes)
		if remainingBytes == 0 {
			return .success(true)
		}

		return .success(false)
	}

	public func completeData() {
		subject.send(completion: .finished)
	}
}
