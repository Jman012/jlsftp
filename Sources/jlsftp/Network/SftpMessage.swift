import Foundation
import Combine
import NIO
import Logging

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
	public let stream: SftpMessageStream
	public let totalBodyBytes: UInt32

	private var remainingBytes: UInt32

	public init(packet: Packet, dataLength: UInt32, shouldReadHandler: @escaping SftpMessageStream.OnBackpressure, logger: Logger? = nil, outstandingFutureLimit: UInt = 10) {
		self.packet = packet
		self.totalBodyBytes = dataLength
		self.remainingBytes = dataLength
		self.stream = SftpMessageStream(outstandingFutureLimit: outstandingFutureLimit, onBackpressure: shouldReadHandler, logger: logger ?? Logger(label: "noop", factory: { _ in SwiftLogNoOpLogHandler() }))
	}

	public func sendData(_ buffer: ByteBuffer) -> Result<Bool, SendDataError> {
		if buffer.readableBytes > remainingBytes {
			stream.complete()
			return .failure(SendDataError.tooMuchData("Unexpected error: Too many bytes encountered in body of sftp packet"))
		}

		stream.send(buffer: buffer)

		remainingBytes -= UInt32(buffer.readableBytes)
		if remainingBytes == 0 {
			return .success(true)
		}

		return .success(false)
	}

	public func completeData() {
		stream.complete()
	}
}
