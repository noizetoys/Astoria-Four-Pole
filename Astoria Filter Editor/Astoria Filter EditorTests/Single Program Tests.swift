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
    private(set) var programData: [UInt8]
    
    init() async throws {
        programData = singleProgramSampleData
    }
    
    
    // Length
    @Test("Program Length Test")
    func length() async throws {
        #expect(programData.count == 37)
    }
    
    
    @Test("Incorrect Length Test")
    func incorrectLength() async throws {
        #expect(programData.count != 36)
        #expect(programData.count != 38)
    }

    
    @Test("Single Dump Parsing Test")
    func singleDumpParsing() async throws {
        let dataType = try await MiniworksSysExCodec.parseDataType(from: programData)
        
        #expect({
            if case .programDumpMessage(_) = dataType {
                return true
            }
            else { return false }
        }())
    }
    
    
    @Test("Single Dump Checksum Test")
    func singleDumpChecksum() async throws {
        let isValid = await MiniworksSysExCodec.isValidChecksum(for: .programDumpMessage(programData))
        
        #expect(isValid)
    }
    
    
    @Test("Single Dump Checksum Error Test")
    func singleDumpChecksumError() async throws {
        var programData = self.programData
        programData[35] = 0xFF
        
        let isValid = await MiniworksSysExCodec.isValidChecksum(for: .programDumpMessage(programData))
        
        #expect(isValid == false)
    }
    
    
    // Parse and Encode
    @Test("Single Dump Parse and Encode Test")
    func singleDumpParseAndEncode() async throws {
        let program = try await MiniworksSysExCodec.decodeProgram(from: programData)
        let encoded = await MiniworksSysExCodec.encodeToSysExMessage(program: program)
        
        #expect(programData.count == encoded.count)
    }
    
    
    /// Take the data, create an object, then convert the object back to data
    @Test("Single Dump Encode and Parse Test")
    func singleDumpEncodeAndParse() async throws {
        let program = try? await MiniWorksProgram(bytes: programData)
        
        #expect(program != nil)
        
        if let program {
            let encodedProgram = await MiniworksSysExCodec.encodeToSysExMessage(program: program)
            let decodedProgramData = try? await MiniworksSysExCodec.decodeProgram(from: encodedProgram)
            
            #expect(decodedProgramData != nil)
            
            let reEncodedData = await MiniworksSysExCodec.encodeToSysExMessage(program: decodedProgramData!)
            #expect(programData.count == reEncodedData.count)
        }
        else {
            
        }
    }
    
    /* Byte #      Value Description
        0   F0     Start of System Exclusive
        1   3E     Waldorf Electronics GmbH Manufacturer ID
        2   04     MiniWorks 4-Pole Machine ID
        3   DEV    Global parameter Device ID, see manual 5.6
        4   40h    Dump Type, here Program Dump Request
        5   PRG    Program Number 0-39 for P.1 to P.40
        6   F7h    End of System Exclusive
     */
    @Test("Single Dump Request Message Test")
    func singleDumpRequestMessage() async throws {
        let programNumber: UInt8 = 2
        let request = try SysExMessageType.programDumpRequest(programNumber).requestMessage()
        #expect(request.count == 7)
        
        #expect(request[0] == SysExConstant.messageStart)
        #expect(request[1] == SysExConstant.manufacturerID)
        #expect(request[2] == SysExConstant.machineID)
            // Can't guaranteee The Device ID so we ignore it.
        #expect(request[4] == SysExConstant.programDumpRequest)
        #expect(request[5] == programNumber)
        #expect(request[6] == SysExConstant.endOfMessage)
    }

    
    @Test("Single Bulk Dump Request Message Test")
    func singleBulkDumpRequestMessage() async throws {
        let programNumber: UInt8 = 2
        let request = try SysExMessageType.programBulkDumpRequest(programNumber).requestMessage()
        #expect(request.count == 7)
        
        #expect(request[0] == SysExConstant.messageStart)
        #expect(request[1] == SysExConstant.manufacturerID)
        #expect(request[2] == SysExConstant.machineID)
            // Can't guaranteee The Device ID so we ignore it.
        #expect(request[4] == SysExConstant.programBulkDumpRequest)
        #expect(request[5] == programNumber)
        #expect(request[6] == SysExConstant.endOfMessage)
    }

}
