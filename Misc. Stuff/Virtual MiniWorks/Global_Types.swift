//
//  MiniWorksGlobalTypes.swift
//  4 Pole for the Win
//
//  Created by James B. Majors on 11/6/25.
//

import Foundation


enum GlobalMIDIControl: UInt8, Codable, CaseIterable {
    case off = 0
    
    // Allows for sending control changes to be
    // Sent to and received from a sequencer
    case ctr = 1
    
    // Signal Envelope will be sent as Breath Controller
    case cts = 2
    
    var name: String {
        switch self {
            case .off: return "Off"
            case .ctr: return "Control Changes"
            case .cts: return "Signal Envelope"
        }
    }
    
}


enum GlobalKnobMode: UInt8, Codable, CaseIterable {
    case jump = 0
    case relative = 1
    
    
    var name: String {
        switch self {
            case .jump: return "Jump"
            case .relative: return "Relative"
        }
    }
    
}


enum MiniWorksGlobalTypes: Int, Codable {
    case globalMidiChannel = 585 // Byte #
    case globalMidiControl = 586
    case globalDeviceID = 587
    case startupProgramID = 588
    
    // Used by Keytracking Mod and when Envelope is triggered
    case globalNoteNumber = 589
    case globalKnobMode = 590
    
    
    var range: ClosedRange<UInt8> {
        switch self {
            case .globalMidiChannel: return 0...16  // 0: Omni, 1-16: Channel
            case .globalMidiControl: return 0...2   // 0: Off, 1: CtR, 2: CtS
            case .globalDeviceID: return 0...126
            case .startupProgramID: return 0...39   // Program 1-40
            case .globalNoteNumber: return 0...127
            case .globalKnobMode: return 0...1     // 0: Jump, 1: Relative
        }
    }
    
    
    var name: String {
        switch self {
            case .globalMidiChannel: return "Global MIDI Channel"
            case .globalMidiControl: return "Global MIDI Control"
            case .globalDeviceID: return "Global Device ID"
            case .startupProgramID: return "Startup Program ID"
            case .globalNoteNumber: return "Global Note Number"
            case .globalKnobMode: return "Global Knob Mode"
        }
    }
    
}



