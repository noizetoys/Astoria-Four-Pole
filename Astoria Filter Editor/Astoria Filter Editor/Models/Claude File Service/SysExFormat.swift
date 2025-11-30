//
//  SysExFormat.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/25/25.
//

import Foundation


// MARK: - SysEx Format Definitions

/**
 Defines SysEx message types for the Waldorf Miniworks.
 
 ## Customization Point
 Modify these values to match your specific hardware's SysEx specification.
 */
enum SysExFormat {
    /// SysEx message headers
    static let startByte: UInt8 = 0xF0
    static let endByte: UInt8 = 0xF7
    static let waldorfID: UInt8 = 0x3E
    static let miniworksID: UInt8 = 0x04
    
    /// Message type identifiers
    static let programDump: UInt8 = 0x00      // Single program dump
    static let programRequest: UInt8 = 0x01   // Request single program
    static let allDump: UInt8 = 0x08          // All programs + globals dump
    static let allRequest: UInt8 = 0x09       // Request all data
    
    /// Create SysEx header for different message types
    static func header(deviceID: UInt8, messageType: UInt8) -> [UInt8] {
        [startByte, waldorfID, miniworksID, deviceID, messageType]
    }
}
