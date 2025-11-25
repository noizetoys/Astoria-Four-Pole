//
//  WaldorfFileError.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/25/25.
//
import Foundation


// MARK: - Errors

/// Errors specific to file operations in this module.
enum WaldorfFileError: Error, LocalizedError {
    /// The device is expected to hold exactly 20 programs, so we
    /// treat any mismatch as an error when loading/saving complete configs.
    case invalidProgramCount(expected: Int, actual: Int)
    
    /// The file we tried to read was not found on disk.
    case fileNotFound(URL)
    
    /// We could read the file, but decoding JSON into our models failed.
    case decodingFailed(URL)
    
    /// We could not encode JSON or write it to disk.
    case encodingFailed(URL)
    
    /// Human-readable descriptions are useful in SwiftUI Alerts.
    var errorDescription: String? {
        switch self {
            case let .invalidProgramCount(expected, actual):
                return "Expected \(expected) programs, found \(actual)."
            case let .fileNotFound(url):
                return "File not found at \(url.lastPathComponent)."
            case let .decodingFailed(url):
                return "Failed to decode \(url.lastPathComponent)."
            case let .encodingFailed(url):
                return "Failed to encode data for \(url.lastPathComponent)."
        }
    }
}
