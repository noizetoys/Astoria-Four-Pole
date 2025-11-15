//
//  Header & Footer.swift
//  Astoria Filter EditorTests
//
//  Created by James Majors on 11/8/25.
//

import Testing
import Foundation

@testable import Astoria_Filter_Editor


struct MiniWorksErrorTests {
    private static let programData: [UInt8] = singleProgramSampleData
    private static let allDumpData: [UInt8] = allDumpSampleData

    
    @Test("Start of Data Error", arguments: [programData, allDumpData])
    func malformedMessageError(_ theData: [UInt8]) async throws {
        // Less than 6 bytes
        var malformedMessageData = theData
        malformedMessageData[0] = 0xFF
        
        let malformedMessageError = #expect(throws: SysExError.self) {
            try MiniworksSysExCodec.parseDataType(from: malformedMessageData)
        }
        
        #expect({
            if case .sysExStartInvalid(_) = malformedMessageError { return true }
            else { return false }
        }())
        
    }

    
    @Test("Incomplete Message Error", arguments: [programData, allDumpData])
    func imcompleteMessageError(_ theData: [UInt8]) async throws {
        // Less than 6 bytes
        var incompleteMessageData = theData
        incompleteMessageData = Array(incompleteMessageData[0...4])
        
        let incompleteMessageError = #expect(throws: SysExError.self) {
            try MiniworksSysExCodec.parseDataType(from: incompleteMessageData)
        }
        
        #expect({
            if case .invalidLength(_) = incompleteMessageError { return true }
            else { return false }
        }())
        
    }
    
    
    @Test("End of Data Error", arguments: [programData, allDumpData])
    func endOfDataError(_ theData: [UInt8]) async throws {
        var badMessage = theData
        let lastIndex = badMessage.endIndex
        badMessage[lastIndex.advanced(by: -1)] = 0xFF
        
        let badMessageError = #expect(throws: SysExError.self) {
            try MiniworksSysExCodec.parseDataType(from: badMessage)
        }
        
        #expect({
            if case .sysExEndInvalid(_) = badMessageError { return true }
            else { return false }
        }())
    }
    
    
    @Test("Manufacturer Error", arguments: [programData, allDumpData])
    func manufacturerError(_ theData: [UInt8]) async throws {
        var badManufacturerMessage = theData
        badManufacturerMessage[1] = 0xFF
        
        let badMessageError = #expect(throws: SysExError.self) {
            try MiniworksSysExCodec.parseDataType(from: badManufacturerMessage)
        }
        
        #expect({
            if case .invalidManufacturerID(_) = badMessageError { return true }
            else { return false }
        }())
    }
    
    
    @Test("Model/Device Error", arguments: [programData, allDumpData])
    func modelError(_ theData: [UInt8]) async throws {
        var badModelMessage = theData
        badModelMessage[2] = 0xFF
        
        let badModelError = #expect(throws: SysExError.self) {
            try MiniworksSysExCodec.parseDataType(from: badModelMessage)
        }
        
        #expect({
            if case .invalidMachineID(_) = badModelError { return true }
            else { return false }
        }())
    }

    
    @Test("Command Error", arguments: [programData, allDumpData])
    func commandError(_ theData: [UInt8]) async throws {
        var badCommandMessage = theData
        badCommandMessage[4] = 0xFF
        
        let badCommandError = #expect(throws: SysExError.self) {
            try MiniworksSysExCodec.parseDataType(from: badCommandMessage)
        }
        
        #expect({
            if case .invalidCommand(_) = badCommandError { return true }
            else { return false }
        }())
    }


    @Test("Checksum Error", arguments: [programData, allDumpData])
    func checksumError(_ theData: [UInt8]) async throws {
        var badChecksumMessage = theData
        badChecksumMessage[badChecksumMessage.count - 2] = 0xFF
        
        let badChecksumError = #expect(throws: SysExError.self) {
            try MiniworksSysExCodec.parseDataType(from: badChecksumMessage)
        }
        
        #expect({
            if case .invalidChecksum(_) = badChecksumError { return true }
            else { return false }
        }())
    }

}
