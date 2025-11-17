//
//  SysEx Object Codec.swift
//  4 Pole for the Win
//
//  Created by James Majors on 11/8/25.
//

import Foundation

/// Used to encode and decode Sys Ex to Programs or Cofigurations
final class MiniworksSysExCodec {
    
    static private var currentDeviceID: UInt8 {
        UInt8(UserDefaults.standard.integer(forKey: "deviceID"))
    }
    
    /// Returns a synchronous snapshot of the current device ID by reading on the main actor.
    static func currentDeviceIDSnapshot() -> UInt8 {
        @MainActor @inline(__always) func read() -> UInt8 { currentDeviceID }
        return read()
    }
    
        /// Provides the type of (validated) message and the data
        /// - Object creation is done elsewhere
    static func parseDataType(from bytes: [UInt8]) throws -> SysExMessageType {
            // Allows checking for each type of MiniWorks Error
        
            // Not just a header
        guard bytes.count > 6
        else { throw SysExError.invalidLength(length: bytes.count) }
        
            // SysEx Data & Format are Valid
        try validate(sysEx: bytes)
        
        let messageType = SysExMessageType.type(from: bytes[4], bytes: bytes)
        
            // Checksum is Valid
        try validateChecksum(for: messageType)
        
        return messageType
    }
    
        // MARK: - Data Validation
        // MARK: - Header
    
        /// Check beginning, end, manufacturer ID, and Device ID
    static func validate(sysEx: [UInt8]) throws {
        let firstByte = sysEx.first ?? 0xFF
        let manufacturerID = sysEx[1]
        let machineID = sysEx[2]
        let deviceID = sysEx[3]
        let command = sysEx[4]
        let lastByte = sysEx.last ?? 0xFF
        
        let messageStartConst = SysExConstant.messageStart.hexString
        let manufacturerIDConst = SysExConstant.manufacturerID.hexString
        let machineIDConst = SysExConstant.machineID.hexString

        let messageEndConst = SysExConstant.endOfMessage.hexString

        debugPrint(icon: "🔍", message: """
                   Validating SysEx Header:
                     start: \(firstByte.hexString) --> \(messageEndConst)
                     manufacturerID: \(manufacturerID.hexString) --> \(manufacturerIDConst)
                     machineID: \(machineID.hexString) --> \(machineIDConst)
                     deviceID: \(deviceID.hexString)
                     ......
                     end: \(lastByte.hexString) --> \(messageEndConst)
                   
                   
                   """)
        
            // Errors broken out to help identify issue
        guard firstByte == SysExConstant.messageStart
        else { throw SysExError.sysExStartInvalid(byte: firstByte) }
        print("✅ Message Start Valid")
        
        guard manufacturerID == SysExConstant.manufacturerID
        else { throw SysExError.invalidManufacturerID(byte: manufacturerID) }
        print("✅ Manufacturer ID Valid")

        guard machineID == SysExConstant.machineID
        else { throw SysExError.invalidMachineID(byte: machineID) }
        print("✅ Machine ID Valid")

        guard (0...126).contains(deviceID)
        else { throw SysExError.invalidDeviceID(byte: deviceID) }
        print("✅ Device ID Valid (0-126)")

        try validate(command: command)
        print("✅ Command Valid")

        guard lastByte == SysExConstant.endOfMessage
        else { throw SysExError.sysExEndInvalid(byte: lastByte) }
        print("✅ End of Message Valid")

        debugPrint(icon: "🔍", message: "SysEx Header Valid")
    }
    
    
    static func validate(command: UInt8) throws {
        let isDump = command == SysExConstant.programDumpMessage
        let isBulkDump = command == SysExConstant.programBulkDumpMessage
        let isAllDump = command == SysExConstant.allDumpMessage
        let isDumpRequest = command == SysExConstant.programDumpRequest
        let isBulkRequest = command == SysExConstant.programBulkDumpRequest
        let isAllRequest = command == SysExConstant.allDumpRequest
        
        
        if !(isDump || isBulkDump || isAllDump || isDumpRequest || isBulkRequest || isAllRequest) {
            throw SysExError.invalidCommand(byte: command)
        }
    }
    

        // MARK: - Checksums
    
        /// Determines validity of checksum by Message type
        /// - Convenience Method
//    static func validateChecksum(for type: SysExMessageType, bytes: [UInt8]) throws {
    static func validateChecksum(for type: SysExMessageType) throws {
        var bytes: [UInt8] = []
        switch type {
            case .allDumpMessage(let theBytes): bytes = theBytes
            case .programBulkDumpMessage(let theBytes): bytes = theBytes
            case .programDumpMessage(let theBytes): bytes = theBytes
                
            default: return
        }
        
        let expectedChecksum = bytes[type.checksumIndex]
        let calculatedChecksum = checksum(for: type, bytes: bytes)
        
        if calculatedChecksum != expectedChecksum {
            throw SysExError.invalidChecksum(byte: calculatedChecksum)
        }
    }
    
    
    // Used for testing
    static func isValidChecksum(for type: SysExMessageType) -> Bool {
        do {
            try validateChecksum(for: type)
            return true
        } catch {
            return false
        }
    }
    
    
        // MARK: Generate
    
        /// Extracts the correct bytes depending on message type
        /// - Convenience Method
    static func checksum(for type: SysExMessageType, bytes: [UInt8]) -> UInt8 {
            //        let start = type.checksumStartIndex
            //        let end = type.checksumEndIndex
        let checksumBytes = Array(bytes[type.checksumStartIndex...type.checksumEndIndex])
        return checksum(from: checksumBytes)
    }
    
    
        /// Calculates the checksum from the provided bytes
        /// - Takes only bytes needed to calculate value
        /// - Combines all values then removes 7th bit (MSB)
    static func checksum(from bytes: [UInt8]) -> UInt8 {
        bytes.reduce(0, { $0 &+ $1 }) & 0x7F
    }


    // MARK: - Program (Patch)
    
    // MARK: Encode
    
    /// Produce Byte stream of all properties of a Program or Dump Sys Ex message
    /// - Provides complete message
    /// - Containing header, data, checksum, EOD
    static func encodeToSysExMessage(program: MiniWorksProgram) -> [UInt8] {
        let programData: [UInt8] = program.encodeToBytes()
        let programChecksum: UInt8 = checksum(from: programData)
        
        return SysExConstant.header
//        + [MiniWorksUserDefaults.shared.deviceID, SysExConstant.programDumpMessage]
        + [currentDeviceIDSnapshot(), SysExConstant.programDumpMessage]
        + programData
        + [programChecksum, SysExConstant.endOfMessage]
    }
    
    
    // MARK: Decode
    
    /// Takes Program/Bulk Dump
    static func decodeProgram(from data: [UInt8]) throws -> MiniWorksProgram {
        debugPrint(message: "Size of Data: \(data.count)\ndata: \(data.hexString)")
        
        if let program = try? MiniWorksProgram(bytes: data) {
            return program
        }
        else {
            throw SysExError.invalidData(data)
        }
    }
    
    
    // MARK: - All Dump (Configuration)
    
    // MARK: Encode
    
    /// Produce Byte stream of all programs and global data for All Dump Sys Ex Message
    /// - Provides complete message
    /// - Containing header, data, checksum, EOD
    static func encodeSysExMessage(allDump configuration: MiniworksDeviceProfile) -> [UInt8] {
        let configurationBytes = configuration.encodeToBytes()
        let checksumData = checksum(from: configurationBytes)
        
        return SysExConstant.header
        + [currentDeviceIDSnapshot(), SysExConstant.allDumpMessage]
        + configurationBytes
        + [checksumData, SysExConstant.endOfMessage]
    }
    
    
    // MARK: Decode
    
    /// Takes complete 'All Dump' byte stream
    /// - Header and program # inserted into program to use existng initializers
    static func decodeAllDump(bytes: [UInt8]) throws -> MiniworksDeviceProfile {
        // Parse (20) Individual Programs (0-19)
        var programs: [MiniWorksProgram] = []
        let header = Array(bytes[0..<5])
        
        var startingIndex: Int = 5
        
        for programNumber in 0..<20 {
            let parameters = Array(bytes[startingIndex..<(startingIndex + 29)])
            let program = MiniWorksProgram(bytes: header + [UInt8(programNumber)] + parameters,
                                           number: UInt8(programNumber))
            
            programs.append(program)
            
            startingIndex += 29
        }
        
        // Create Global Data
        let glodalBytes: [UInt8] = Array(bytes[585...590])
        let globals = MiniWorksGlobalData(globalbytes: glodalBytes)
        
        return MiniworksDeviceProfile(programs: programs, globals: globals)
    }
    
}
