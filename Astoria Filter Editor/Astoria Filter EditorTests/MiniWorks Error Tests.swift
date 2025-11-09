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
    private static let programData: Data = singleProgramSampleData
    private static let allDumpData: Data = allDumpSampleData

    
    @Test("Malformed Message Error", arguments: [programData, allDumpData])
    func malformedMessageError(_ theData: Data) async throws {
        // Less than 6 bytes
        var malformedMessageData = theData
        malformedMessageData[0] = 0xFF
        
        let malformedMessageError = #expect(throws: MiniWorksError.self) {
            try SysExMessage.parseType(data: malformedMessageData)
        }
        
        #expect({
            if case .malformedMessage(_) = malformedMessageError { return true }
            else { return false }
        }())
        
    }

    
    @Test("Incomplete Message Error", arguments: [programData, allDumpData])
    func imcompleteMessageError(_ theData: Data) async throws {
        // Less than 6 bytes
        var incompleteMessageData = theData
        incompleteMessageData = Data(incompleteMessageData[0...4])
        
        let incompleteMessageError = #expect(throws: MiniWorksError.self) {
            try SysExMessage.parseType(data: incompleteMessageData)
        }
        
        #expect({
            if case .incompleteMessage(_) = incompleteMessageError { return true }
            else { return false }
        }())
        
    }
    
    
    @Test("End of Data Error", arguments: [programData, allDumpData])
    func endOfDataError(_ theData: Data) async throws {
        var badMessage = theData
        let lastIndex = badMessage.endIndex
        badMessage[lastIndex.advanced(by: -1)] = 0xFF
        
        let badMessageError = #expect(throws: MiniWorksError.self) {
            try SysExMessage.parseType(data: badMessage)
        }
        
        #expect({
            if case .malformedMessage(_) = badMessageError { return true }
            else { return false }
        }())
    }
    
    
    @Test("Manufacturer Error", arguments: [programData, allDumpData])
    func manufacturerError(_ theData: Data) async throws {
        var badManufacturerMessage = theData
        badManufacturerMessage[1] = 0xFF
        
        let badMessageError = #expect(throws: MiniWorksError.self) {
            try SysExMessage.parseType(data: badManufacturerMessage)
        }
        
        #expect({
            if case .wrongManufacturerID(_) = badMessageError { return true }
            else { return false }
        }())
    }
    
    
    @Test("Model/Device Error", arguments: [programData, allDumpData])
    func modelError(_ theData: Data) async throws {
        var badModelMessage = theData
        badModelMessage[2] = 0xFF
        
        let badModelError = #expect(throws: MiniWorksError.self) {
            try SysExMessage.parseType(data: badModelMessage)
        }
        
        #expect({
            if case .wrongMachineID(_) = badModelError { return true }
            else { return false }
        }())
    }

    
    @Test("Command Error", arguments: [programData, allDumpData])
    func commandError(_ theData: Data) async throws {
        var badCommandMessage = theData
        badCommandMessage[4] = 0xFF
        
        let badCommandError = #expect(throws: MiniWorksError.self) {
            try SysExMessage.parseType(data: badCommandMessage)
        }
        
        #expect({
            if case .unknownCommandByte(_) = badCommandError { return true }
            else { return false }
        }())
    }


    @Test("Checksum Error", arguments: [programData, allDumpData])
    func checksumError(_ theData: Data) async throws {
        var badChecksumMessage = theData
        badChecksumMessage[badChecksumMessage.count - 2] = 0xFF
        
        let badChecksumError = #expect(throws: MiniWorksError.self) {
            try SysExMessage.parseType(data: badChecksumMessage)
        }
        
        #expect({
            if case .invalidChecksum(_) = badChecksumError { return true }
            else { return false }
        }())
    }

}
