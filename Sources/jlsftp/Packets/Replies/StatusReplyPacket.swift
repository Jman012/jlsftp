import Foundation

/**
 A common reply packet for operations, usually returned for requests that do not
 need to return data, or upon error of any operation.

 - Tag: StatusReplyPacket
 - Since: sftp v3
 */
public struct StatusReplyPacket: BasePacket, Equatable {

	/**
	 Request identifier.

	 - Since: sftp v3
	 */
	public let id: PacketId
	/**
	 The success or error status code.

	 - Since: sftp v3
	 */
	public let statusCode: StatusCode
	/**
	 The error message for the error status code.

	 - Since: sftp v3
	 */
	public let errorMessage: String
	/**
	 The language tag for the error message.

	 - Since: sftp v3
	 - Note: This is in [RFC-1766](https://tools.ietf.org/html/rfc1766) format.
	 */
	public let languageTag: String

	public init(id: PacketId,
				statusCode: StatusCode,
				errorMessage: String,
				languageTag: String) {
		self.id = id
		self.statusCode = statusCode
		self.errorMessage = errorMessage
		self.languageTag = languageTag
	}
}
