//
//  SysExConstants.swift
//  4 Pole for the Win
//
//  Created by James B. Majors on 11/7/25.
//

import Foundation


nonisolated
enum SysExConstant {
    static let appName: String = "4 Pole for the Win"
    
    static let messageStart: UInt8 = 0xF0   // [0]
    static let manufacturerID: UInt8 = 0x3E // [1]
    static let machineID: UInt8 = 0x04      // [2]
    
    // Type of Response
    static let programDumpMessage: UInt8 = 0x00    // [4]
    static let programBulkDumpMessage: UInt8 = 0x01// [4]
    static let allDumpMessage: UInt8 = 0x08        // [4]

    // Type of Request
    static let programDumpRequest: UInt8 = 0x40
    static let programBulkDumpRequest: UInt8 = 0x41
    static let allDumpRequest: UInt8 = 0x48
    
    static let endOfMessage: UInt8 = 0xF7   // [36 or 592]
    
    static let header: [UInt8] = [messageStart, manufacturerID, machineID]
    
    
    static let midiChannelKey = "MIDI_CHANNEL"
    static let midiControlKey = "MIDI_CONTROL"
    static let deviceIDKey = "DEVICE_ID"
    static let startUpProgramIDKey = "START_UP_PROGRAM_ID"
    static let noteNumberKey = "NOTE_NUMBER"
    static let knobModeKey = "KNOB_MODE"
    
    static let modulationWheel = 0x01             // CC#1
    static let breathControl = 0x02               // CC#2 - Used for Envelope Display
    static let sustainSwitch = 0x40               // CC#64
    static let resetAllControllers = 0x79         // CC#121
    static let allnotesOff = 0x7B                 // CC#123

}
