import Foundation
import Combine
import NIO

//public class SftpBridgingDataStream {
//	public enum BackpressureState {
//		case open
//		case closed
//	}
//
//	public typealias BackpressureHandler = (BackpressureState) -> ()
//	// this needs promises/futures so we only remove once promise is done, which keeps us from overloading the kernel
//	public typealias DataHandler = (ByteBuffer) -> (EventLoopFuture<()>)
//
//	let bufferSize: UInt32
//	let backpressureHandler: BackpressureHandler
//
//	var dataHandler: DataHandler?
//	var bufferedData: [ByteBuffer] = []
//	var bufferedSize: UInt32 = 0
//
//	var isFull: Bool {
//		bufferedSize >= bufferSize
//	}
//
//	public init(bufferSize: UInt32, backpressureHandler: @escaping BackpressureHandler) {
//		self.bufferSize = bufferSize
//		self.backpressureHandler = backpressureHandler
//	}
//
//	public func receive(_ byteBuffer: ByteBuffer) {
//		precondition(!isFull)
//		precondition(UInt32.max - bufferedSize > byteBuffer.readableBytes)
//
//		if let dataHandler = dataHandler {
//			// immediately push
//		} else {
//			// cache
//		}
//	}
//
//	public func attachHandler(_: DataHandler) {
//		// empty buffer and then do nothing
//	}
//}
