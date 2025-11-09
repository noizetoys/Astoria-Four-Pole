//
//  All Dump Tests.swift
//  Four Pole Tests
//
//  Created by James Majors on 11/7/25.
//

import Testing
import Foundation

@testable import Astoria_Filter_Editor


struct All_Dump_Tests {
    private(set) var dumpData: Data
    
    
    init() async throws {
        dumpData = allDumpSampleData
    }
    
    
    // Length
    
    @Test("All Dump Length Test")
    func length() async throws {
        #expect(dumpData.count == 593)
        
    }
    
    
    @Test("All Dump Incorrect Length Test")
    func incorrectLength() async throws {
        #expect(dumpData.count != 592)
        #expect(dumpData.count != 594)
    }

    
    // Parse AllDump
    @Test("All Dump Parsing Test")
    func allDumpParsing() async throws {
        let dataType = try await SysExMessage.parseType(data: dumpData)
        
        #expect({
            if case .allDump = dataType {
                return true
            }
            else { return false }
        }())
    }
    
    
//    @Test("All Dump Parsing Error")
//    func allDumpParsingError() async throws {
//        
//    }
//    
//
    // checksum on all Dump
    @Test("All Dump Checksum Test")
    func allDumpChecksum() async throws {
        let isValid = await SysExMessage.isValidChecksum(for: .allDumpMessage, data: dumpData)
        
        #expect(isValid)
    }
    
    
    // checksum error on all dump
    @Test("All Dump Checksum Error")
    func allDumpChecksumError() async throws {
        var testData = dumpData
        testData[591] = 0xFF
        
        let isValid = await SysExMessage.isValidChecksum(for: .allDumpMessage, data: testData)
        
        #expect(!isValid)
    }
    
    
    // Parse and Encode
    @Test func allDumpParseAndEncode() async throws {
        
    }
    
    
    @Test func allDumpParseAndEncodeError() async throws {
        
    }
    

    @Test func allDumpEncodeAndParse() async throws {
    }
    
    
    @Test func allDumpEncodeAndParseError() async throws {
    }
    
    
    // Request Message
    @Test func allDumpRequestMessage() async throws {
        
    }
    
    
    @Test func allDumpRequestMessageError() async throws {
        
    }

    
    // Program Count
    @Test func programCount() async throws {
        
    }
    
    @Test func incorrectProgramCount() async throws {
        
    }

    
    
}
