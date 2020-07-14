import Foundation

/**
 Requests from the client to the server represent the various file system
 operations. Each request begins with an `id' field, which is a 32-bit
 identifier identifying the request (selected by the client). The same
 identifier will be returned in the response to the request. One possible
 implementation of it is a monotonically increasing request sequence number
 (modulo 2^32).

 - Since: sftp v3
 */
public typealias PacketId = UInt32
