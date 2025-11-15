//
//  SysEx Object Codec.swift
//  4 Pole for the Win
//
//  Created by James Majors on 11/8/25.
//

import Foundation

/// Used to encode and decode Sys Ex to Programs or Cofigurations
enum SysExObjectCodec {
    
    // MARK: - Program (Patch)
    
    // Encode
    
    /// Produce Byte stream of all properties of a Program or Dump Sys Ex message
    /// - Provides complete message
    /// - Containing header, data, checksum, EOD
    static func encodeToSysEx(program: MiniWorksProgram) -> [UInt8] {
        let programData: [UInt8] = program.encodeToBytes()
        let programChecksum: UInt8 = SysExMessage.checksum(from: programData)
        
        return SysExConstant.header
        + [SysExMessageType.programDumpMessage.rawValue]
        + programData
        + [programChecksum, SysExConstant.endOfMessage]
    }
    
    
    // Decode
    /// Takes Program/Bulk Dump
    static func decodeProgram(data: Data) throws -> MiniWorksProgram {
        if let program = try? MiniWorksProgram(data: data) {
            return program
        }
        else {
            throw MiniWorksError.malformedMessage(data)
        }
    }
    
    
    // MARK: - All Dump (Configuration)
    
    // Encode
    
    /// Produce Byte stream of all programs and global data for All Dump Sys Ex Message
    /// - Provides complete message
    /// - Containing header, data, checksum, EOD
    static func encodeSysEx(allDump configuration: MachineConfiguration) -> [UInt8] {
        let configurationBytes = configuration.encodeToBytes()
        let checksumData = SysExMessage.checksum(from: configurationBytes)
        
        return SysExConstant.header
        + [SysExMessageType.allDumpMessage.rawValue]
        + configurationBytes
        + [checksumData, SysExConstant.endOfMessage]
    }
    
    
    // Decode
    /// Takes complete 'All Dump' data
    static func decodeAllDump(data: Data) throws -> MachineConfiguration {
        let bytes = [UInt8](data)
        
        do {
            let dump = try decodeAllDump(bytes: bytes)
            return dump
        }
        catch {
            throw error
        }
    }
    
    
    /// Takes complete 'All Dump' byte stream
    static func decodeAllDump(bytes: [UInt8]) throws -> MachineConfiguration {
        // Parse (20) Individual Programs (0-19)
        var programs: [MiniWorksProgram] = []
        
        var startingIndex: Int = 5
        
        for programNumber in 0..<20 {
            let parameters = Array(bytes[startingIndex..<(startingIndex + 29)])
            let program = MiniWorksProgram(bytes: parameters, number: programNumber)
            
            programs.append(program)
            
            startingIndex += 29
        }
        
        let glodalBytes: [UInt8] = Array(bytes[585...590])
        let globals = MiniWorksGlobalData(bytes: glodalBytes)
        
        return MachineConfiguration(programs: programs, globals: globals)
    }
    
    
    // MARK: - Validation
    
    private func validateSysEx(_ data: [UInt8]) throws {
        guard !data.isEmpty
        else { throw MiniWorksError.malformedMessage(Data()) }
    }
}
