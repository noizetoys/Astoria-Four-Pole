//
//  MiniworksFileError.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/25/25.
//

import Foundation


// MARK: - Error Handling

enum MiniworksFileError: LocalizedError {
    case invalidPath
    case fileNotFound(String)
    case invalidJSON
    case invalidSysEx
    case encodingFailed
    case decodingFailed
    case writePermissionDenied
    case checksumMismatch
    case directoryCreationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidPath:
            return "The specified file path is invalid"
        case .fileNotFound(let name):
            return "File not found: \(name)"
        case .invalidJSON:
            return "The JSON data is malformed or incompatible"
        case .invalidSysEx:
            return "The SysEx data is invalid or corrupted"
        case .encodingFailed:
            return "Failed to encode data for writing"
        case .decodingFailed:
            return "Failed to decode data from file"
        case .writePermissionDenied:
            return "Permission denied when writing to file"
        case .checksumMismatch:
            return "SysEx checksum validation failed"
        case .directoryCreationFailed:
            return "Failed to create required directories"
        }
    }
}
