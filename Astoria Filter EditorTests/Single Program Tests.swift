//
//  Single Program Tests.swift
//  Four Pole Tests
//
//  Created by James Majors on 11/7/25.
//

import Testing
import Foundation

@testable import Astoria_Filter_Editor

struct Single_Program_Tests {
    private(set) var programData: Data
    
    init () async throws {
        programData = singleProgramData
    }
    
    
    // Length
    @Test func length() async throws {
        #expect(programData.count == 37)
    }
    
    @Test func incorrectLength() async throws {
        #expect(programData.count != 38)
    }

    
    // Parsing single dump
    @Test func singleDumpParsing() async throws {
        let dataType = try await SysExMessage.parseType(data: programData)
        
        #expect({
            if case .programDump = dataType {
                return true
            }
            else { return false } }())
    }
    
    
    // Checksum on single dump
    @Test func singleDumpChecksum() async throws {
        let isValid = await SysExMessage.isValidChecksum(for: .programDumpMessage, data: programData)
        
        #expect(isValid)
    }
    
    
    // Checksum error on single dump
    @Test func singleDumpChecksumError() async throws {
        var programData = self.programData
        programData[35] = 0xFF
        
        let isValid = await SysExMessage.isValidChecksum(for: .programDumpMessage, data: programData)
        
        
        #expect(isValid == false)

    }
    
    
    // Parse and Encode
    @Test func singleDumpParseAndEncode() async throws {
        let program = try await SysExObjectCodec.decodeProgram(data: programData)
        
        let encoded = await SysExObjectCodec.encodeToSysEx(program: program)
        
        #expect(programData.count == encoded.count)
    }
    
    
    // Encode and parse
    /// Take the data, create an object, then convert the object back to data
    @Test func singleDumpEncodeAndParse() async throws {
        
        let program = await MiniWorksProgram(data: programData)
        
        #expect(program != nil)
        
        let encodedProgram = await SysExObjectCodec.encodeToSysEx(program: program!)
        
        let decodedProgramData = try? await SysExObjectCodec.decodeProgram(data: encodedProgram)
        
        #expect(decodedProgramData != nil)
        
        let reEncodedData = await SysExObjectCodec.encodeToSysEx(program: decodedProgramData!)
        #expect(programData.count == reEncodedData.count)
        

    }
    
    // Request Message
    @Test func singleDumpRequestMessage() async throws {
        let programNumber = 2
        let request = await SysExMessageRequest.programDump(for: programNumber)
        #expect(request.count == 7)
        
        #expect(request[0] == 0xF0)
        #expect(request[4] == 0x40)
        #expect(request[5] == programNumber)
        #expect(request[6] == 0xF7)
    }


}

