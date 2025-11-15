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
    private(set) var dumpData: [UInt8]
    
    
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

    
    @Test("All Dump Parsing Test")
    func allDumpParsing() async throws {
        let dataType = try await MiniworksSysExCodec.parseDataType(from: dumpData)
        
        #expect({
            if case .allDumpMessage(_) = dataType {
                return true
            }
            else { return false }
        }())
    }
    
    
    @Test("All Dump Checksum Test")
    func allDumpChecksum() async throws {
        let isValid = await MiniworksSysExCodec.isValidChecksum(for: .allDumpMessage(dumpData))
        
        #expect(isValid)
    }
    
    
    @Test("All Dump Checksum Error")
    func allDumpChecksumError() async throws {
        var testData = dumpData
        testData[591] = 0xFF
        
        let isValid = await MiniworksSysExCodec.isValidChecksum(for: .allDumpMessage(testData))
        
        #expect(!isValid)
    }
    
    
    @Test("All Dump Parse and Encode Test")
    func allDumpParseAndEncode() async throws {
        let allDump = try await MiniworksSysExCodec.decodeAllDump(bytes: dumpData)
        
        let encoded = await MiniworksSysExCodec.encodeSysExMessage(allDump: allDump)
        
        #expect(allDumpSampleData.count == encoded.count)
    }
    
    
    @Test("All Dump Encode and Parse Test")
    func allDumpEncodeAndParse() async throws {
        let theDump = try? await MiniworksSysExCodec.decodeAllDump(bytes: dumpData)
        #expect(theDump != nil)
        
        let encoded = await MiniworksSysExCodec.encodeSysExMessage(allDump: theDump!)
        
        #expect(dumpData.count == encoded.count)
    }
    
    
    @Test("All Dump Request Message Test")
    func allDumpRequestMessage() async throws {
        let request = await SysExMessageRequest.allDumpRequest()
        #expect(request.count == 6)
        
        #expect(request[0] == 0xF0)
        #expect(request[4] == 0x48)
        #expect(request[5] == 0xF7)
    }
    
    
    @Test("All Dump Program Count Test")
    func programCount() async throws {
        let theConfig = try? await MiniworksSysExCodec.decodeAllDump(bytes: dumpData)

        let programCount = await theConfig?.programs.count
        
        #expect(programCount == 20)
    }
    
    
    @Test func incorrectProgramCount() async throws {
        let theConfig = try? await MiniworksSysExCodec.decodeAllDump(bytes: dumpData)
        
        let programCount = await theConfig?.programs.count
        
        #expect(programCount != 19)
        #expect(programCount != 21)
    }
    
    
    // MARK: - Globals
    
    @Test("Globals Length Test")
    func globalsLength() async throws {
        let theConfig = try? await MiniworksSysExCodec.decodeAllDump(bytes: dumpData)
        
        let globals = await theConfig?.globalSetup
        let globalSysEx = await globals?.encodeToBytes()
        
        #expect(globalSysEx?.count == 6)
    }
    
    
    @Test("Globals Properties Value Test")
    func globalsPropertiesValues() async throws {
        let theConfig = try? await MiniworksSysExCodec.decodeAllDump(bytes: dumpData)
        
        let globals = await theConfig?.globalSetup
        #expect(globals != nil)
        
        let midiChannel = await globals!.midiChannel
        #expect((0...16).contains(midiChannel))
        
        let midiControl = await globals!.midiControl.rawValue
        #expect((0...2).contains(midiControl))

        let deviceID = await globals!.deviceID
        #expect((0...126).contains(deviceID))

        let startUpProgramID = await globals!.startUpProgramID
        #expect((0...39).contains(startUpProgramID))

        let noteNumber = await globals!.noteNumber
        #expect((0...127).contains(noteNumber))
        
        let knobMode = await globals!.knobMode.rawValue
        #expect((0...1).contains(knobMode))
    }
    
    
    @Test("Globals Encode Test")
    func globalsDecodeEncode() async throws {
        let setMidiChannel: UInt8 = 16
        let setMidiControl = GlobalMIDIControl.off
        let setDeviceID: UInt8 = 126
        let setStartUpProgramID: UInt8 = 39
        let setNoteNumber: UInt8 = 127
        let setKnobMode = GlobalKnobMode.jump
        
        let theConfig = try? await MiniworksSysExCodec.decodeAllDump(bytes: dumpData)
        
        #expect(theConfig != nil)

        // Mutate MainActor-isolated property on the main actor
        await MainActor.run {
            theConfig?.midiChannel = setMidiChannel
            theConfig?.midiControl = setMidiControl
            theConfig?.deviceID = setDeviceID
            theConfig?.startUpProgramID = setStartUpProgramID
            theConfig?.noteNumber = setNoteNumber
            theConfig?.knobMode = setKnobMode
        }
        
        let encodedData = await MiniworksSysExCodec.encodeSysExMessage(allDump: theConfig!)
        let encodedBytes = [UInt8](encodedData)
        
        #expect(encodedBytes[585] == setMidiChannel)
        #expect(encodedBytes[586] == setMidiControl.rawValue)
        #expect(encodedBytes[587] == setDeviceID)
        #expect(encodedBytes[588] == setStartUpProgramID)
        #expect(encodedBytes[589] == setNoteNumber)
        #expect(encodedBytes[590] == setKnobMode.rawValue)
    }
    
    
    @Test("Globals Decode Test")
    func globalsEncodeDecode() async throws {
        let theConfig = try? await MiniworksSysExCodec.decodeAllDump(bytes: dumpData)
        
        #expect(theConfig != nil)

        let setMidiChannel: UInt8 = await theConfig!.midiChannel
        let setMidiControl: UInt8 = await theConfig!.midiControl.rawValue
        let setDeviceID: UInt8 =  await theConfig!.deviceID
        let setStartUpProgramID: UInt8 =  await theConfig!.startUpProgramID
        let setNoteNumber: UInt8 =  await theConfig!.noteNumber
        let setKnobMode: UInt8 =  await theConfig!.knobMode.rawValue
        
        // Values from the raw Dump
        #expect(setMidiChannel == 0x01)
        #expect(setMidiControl == 0x01)
        #expect(setDeviceID == 0x01)
        #expect(setStartUpProgramID == 0x1F)
        #expect(setNoteNumber == 0x3C)
        #expect(setKnobMode == 0x01)
    }

}

