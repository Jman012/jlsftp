import Foundation

/**
 Many operations in the protocol operate on open files.  The
 SSH_FXP_OPEN request can return a file handle (which is an opaque
 variable-length string) which may be used to access the file later
 (e.g.  in a read operation).  The client MUST NOT send requests the
 server with bogus or closed handles.  However, the server MUST
 perform adequate checks on the handle in order to avoid security
 risks due to fabricated handles.

 This design allows either stateful and stateless server
 implementation, as well as an implementation which caches state
 between requests but may also flush it.  The contents of the file
 handle string are entirely up to the server and its design.  The
 client should not modify or attempt to interpret the file handle
 strings.

 The file handle strings MUST NOT be longer than 256 bytes.
 */
public typealias FileHandle = String
