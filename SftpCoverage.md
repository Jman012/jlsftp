
# SFTP Coverage

This document is to cover the implementation progress of `jlsftp` over versions 3, 4, 5, and 
6 of SFTP.

## Serialization

### Request

Deserialization, then Serialization

| Packet Type      | V3   | V4   | V5   | V6   |
|------------------|------|------|-------|------|
| SSH_FXP_INIT     | ✅ ❌ | ❌ ❌ | ❌ ❌ | ❌ ❌ |
| SSH_FXP_OPEN     | ✅ ❌ | ❌ ❌ | ❌ ❌ | ❌ ❌ |
| SSH_FXP_CLOSE    | ❌ ❌ | ❌ ❌ | ❌ ❌ | ❌ ❌ |
| SSH_FXP_READ     | ❌ ❌ | ❌ ❌ | ❌ ❌ | ❌ ❌ |
| SSH_FXP_WRITE    | ❌ ❌ | ❌ ❌ | ❌ ❌ | ❌ ❌ |
| SSH_FXP_LSTAT    | ❌ ❌ | ❌ ❌ | ❌ ❌ | ❌ ❌ |
| SSH_FXP_FSTAT    | ❌ ❌ | ❌ ❌ | ❌ ❌ | ❌ ❌ |
| SSH_FXP_SETSTAT  | ❌ ❌ | ❌ ❌ | ❌ ❌ | ❌ ❌ |
| SSH_FXP_FSETSTAT | ❌ ❌ | ❌ ❌ | ❌ ❌ | ❌ ❌ |
| SSH_FXP_OPENDIR  | ❌ ❌ | ❌ ❌ | ❌ ❌ | ❌ ❌ |
| SSH_FXP_READDIR  | ❌ ❌ | ❌ ❌ | ❌ ❌ | ❌ ❌ |
| SSH_FXP_REMOVE   | ❌ ❌ | ❌ ❌ | ❌ ❌ | ❌ ❌ |
| SSH_FXP_MKDIR    | ❌ ❌ | ❌ ❌ | ❌ ❌ | ❌ ❌ |
| SSH_FXP_RMDIR    | ❌ ❌ | ❌ ❌ | ❌ ❌ | ❌ ❌ |
| SSH_FXP_REALPATH | ❌ ❌ | ❌ ❌ | ❌ ❌ | ❌ ❌ |
| SSH_FXP_STAT     | ❌ ❌ | ❌ ❌ | ❌ ❌ | ❌ ❌ |
| SSH_FXP_RENAME   | ❌ ❌ | ❌ ❌ | ❌ ❌ | ❌ ❌ |
| SSH_FXP_READLINK | ❌ ❌ | ❌ ❌ | ❌ ❌ | ❌ ❌ |
| SSH_FXP_SYMLINK  | ❌ ❌ | ❌ ❌ | ❌ ❌ | ❌ ❌ |
| SSH_FXP_EXTENDED | ❌ ❌ | ❌ ❌ | ❌ ❌ | ❌ ❌ |

### Reply

| Packet Type      | V3   | V4   | V5   | V6   |
|------------------|------|------|-------|------|
| SSH_FXP_VERSION | ✅ ❌ | ❌ ❌ | ❌ ❌ | ❌ ❌ |
| SSH_FXP_STATUS | ✅ ❌ | ❌ ❌ | ❌ ❌ | ❌ ❌ |
| SSH_FXP_HANDLE | ✅ ❌ | ❌ ❌ | ❌ ❌ | ❌ ❌ |
| SSH_FXP_DATA | ✅ ❌ | ❌ ❌ | ❌ ❌ | ❌ ❌ |
| SSH_FXP_NAME | ✅ ❌ | ❌ ❌ | ❌ ❌ | ❌ ❌ |
| SSH_FXP_ATTRS | ✅ ❌ | ❌ ❌ | ❌ ❌ | ❌ ❌ |
| SSH_FXP_EXTENDED_REPLY | ✅ ❌ | ❌ ❌ | ❌ ❌ | ❌ ❌ |

## Handlers

### Server

| Packet Type      | V3 | V4 | V5 | V6 |
|------------------|----|---|----|---|
| SSH_FXP_INIT     | ❌ | ❌ | ❌ | ❌ |
| SSH_FXP_OPEN     | ❌ | ❌ | ❌ | ❌ |
| SSH_FXP_CLOSE    | ❌ | ❌ | ❌ | ❌ |
| SSH_FXP_READ     | ❌ | ❌ | ❌ | ❌ |
| SSH_FXP_WRITE    | ❌ | ❌ | ❌ | ❌ |
| SSH_FXP_LSTAT    | ❌ | ❌ | ❌ | ❌ |
| SSH_FXP_FSTAT    | ❌ | ❌ | ❌ | ❌ |
| SSH_FXP_SETSTAT  | ❌ | ❌ | ❌ | ❌ |
| SSH_FXP_FSETSTAT | ❌ | ❌ | ❌ | ❌ |
| SSH_FXP_OPENDIR  | ❌ | ❌ | ❌ | ❌ |
| SSH_FXP_READDIR  | ❌ | ❌ | ❌ | ❌ |
| SSH_FXP_REMOVE   | ❌ | ❌ | ❌ | ❌ |
| SSH_FXP_MKDIR    | ❌ | ❌ | ❌ | ❌ |
| SSH_FXP_RMDIR    | ❌ | ❌ | ❌ | ❌ |
| SSH_FXP_REALPATH | ❌ | ❌ | ❌ | ❌ |
| SSH_FXP_STAT     | ❌ | ❌ | ❌ | ❌ |
| SSH_FXP_RENAME   | ❌ | ❌ | ❌ | ❌ |
| SSH_FXP_READLINK | ❌ | ❌ | ❌ | ❌ |
| SSH_FXP_SYMLINK  | ❌ | ❌ | ❌ | ❌ |
| SSH_FXP_EXTENDED | ❌ | ❌ | ❌ | ❌ |

### Client

| Packet Type      | V3 | V4 | V5 | V6 |
|------------------|----|---|----|---|
| SSH_FXP_VERSION | ❌ | ❌ | ❌ | ❌ |
| SSH_FXP_STATUS | ❌ | ❌ | ❌ | ❌ |
| SSH_FXP_HANDLE | ❌ | ❌ | ❌ | ❌ |
| SSH_FXP_DATA | ❌ | ❌ | ❌ | ❌ |
| SSH_FXP_NAME | ❌ | ❌ | ❌ | ❌ |
| SSH_FXP_ATTRS | ❌ | ❌ | ❌ | ❌ |
| SSH_FXP_EXTENDED_REPLY | ❌ | ❌ | ❌ | ❌ |