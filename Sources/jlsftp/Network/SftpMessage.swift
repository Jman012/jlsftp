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
//	public let data: AnyPublisher<ByteBuffer, Error>
	public let stream: SftpMessageStream
	public let totalBodyBytes: UInt32

	private var remainingBytes: UInt32
//	private var subject: PassthroughSubject<ByteBuffer, Error>

	public init(packet: Packet, dataLength: UInt32, shouldReadHandler: @escaping DemandBridgePublisherDemandHandler) {
		self.packet = packet
		self.totalBodyBytes = dataLength
		self.remainingBytes = dataLength
		self.stream = SftpMessageStream(outstandingFutureLimit: 10, onBackpressure: shouldReadHandler)
////		self.subject = DemandBridgeSubject<ByteBuffer, Error>(handler: shouldReadHandler)
//		self.subject = PassthroughSubject<ByteBuffer, Error>()
//		self.data = subject
////			.print()
//			.buffer2(size: 999, prefetch: .byRequest, whenFull: .customError({ preconditionFailure() }))
////			.flatMap(maxPublishers: .none, { $0 })
////			.bufferedData(bufferSize: 10)
//			.demandBridge(handler: shouldReadHandler)
//			.eraseToAnyPublisher()
	}

	public func sendData(_ buffer: ByteBuffer) -> Result<Bool, SendDataError> {
		if buffer.readableBytes > remainingBytes {
			stream.complete()
//			subject.send(completion: .finished)
			return .failure(SendDataError.tooMuchData("Unexpected error: Too many bytes encountered in body of sftp packet"))
		}

		stream.send(buffer: buffer)
//		subject.send(buffer)

		remainingBytes -= UInt32(buffer.readableBytes)
		if remainingBytes == 0 {
			return .success(true)
		}

		return .success(false)
	}

	public func completeData() {
		stream.complete()
//		subject.send(completion: .finished)
	}
}
