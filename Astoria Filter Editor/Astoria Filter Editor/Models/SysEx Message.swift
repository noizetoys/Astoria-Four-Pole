//
//  SysEx Message.swift
//  4 Pole for the Win
//
//  Created by James B. Majors on 11/6/25.
//

import Foundation


enum SysExMessage {
    /// Provides the type of (validated) message and the data
    /// - Object creation is done elsewhere
    static func parseType(data: Data) throws -> SysExDataType {
        // Allows checking for each type of MiniWorks Error
        
        // Not just a header
        guard data.count > 6
        else { throw SysExError.invalidLength(expected: 0, actual: data.count) }
            
        // Header is Valid
        guard
            try isValidHeader(data: data) == true
        else {
//            throw SysExError.sysExStartInvalid(expected: 0xF0, actual: <#T##UInt8#>)
        }
        
        guard
        let messageType = SysExMessageType(rawValue: data[4])
        else { throw MiniWorksError.unknownCommandByte(data[4])}

        
        // Checksum is Valid
        guard isValidChecksum(for: messageType, data: data)
        else {
            let index = messageType.checksumIndex
            throw MiniWorksError.invalidChecksum(data[index])
        }

        
        switch messageType {
            case .programDumpMessage: return .programDump(data)
            case .programBulkDumpMessage: return .programBulkDump(data)
            case .allDumpMessage: return .allDump(data)
        }
        
    }

    
    // MARK: - Header
    
    /// Check beginning, end, manufacturer ID, and Device ID
    static func isValidHeader(data: Data) throws -> Bool {
        guard
            data.first == SysExConstant.messageStart,
            data.last == SysExConstant.endOfMessage
        else { throw MiniWorksError.malformedMessage(data)}
        
        guard
            data[1] == SysExConstant.manufacturerID
        else { throw MiniWorksError.wrongManufacturerID(data[1])}
        
        guard data[2] == SysExConstant.machineID
        else { throw MiniWorksError.wrongMachineID(data[2]) }
        
        guard data[3] == SysExConstant.DEV
        else { throw MiniWorksError.wrongDeviceID(data[3])}

        return true
    }
    
    
    // MARK: - Checksums
    
    /// Determines validity of checksum by Message type
    static func isValidChecksum(for type: SysExMessageType, data: Data) -> Bool {
        let bytes = [UInt8](data)
        return isValidChecksum(for: type, bytes: bytes)
    }

    
    /// Determines validity of checksum by Message type
    /// - Convenience Method
    static func isValidChecksum(for type: SysExMessageType, bytes: [UInt8]) -> Bool {
        let expectedChecksum = bytes[type.checksumIndex]
        let calculatedChecksum = checksum(for: type, bytes: bytes)
        
        return calculatedChecksum == expectedChecksum
    }
    
    
    // Generate Checksums
    
    static func checksum(for type: SysExMessageType, data: Data) -> UInt8 {
        let bytes = [UInt8](data)
        return checksum(for: type, bytes: bytes)
    }
    
    
    /// Extracts the correct bytes depending on message type
    /// - Convenience Method
    static func checksum(for type: SysExMessageType, bytes: [UInt8]) -> UInt8 {
        let start = type.checksumStartIndex
        let end = type.checksumEndIndex
        let checksumBytes = Array(bytes[start...end])
        return checksum(from: checksumBytes)
    }
    
    
    /// Calculates the checksum from the provided bytes
    /// - Takes only bytes needed to calculate value
    /// - Combines all values then removes 7th bit (MSB) 
    static func checksum(from bytes: [UInt8]) -> UInt8 {
        bytes.reduce(0, { $0 &+ $1 }) & 0x7F
    }
}
