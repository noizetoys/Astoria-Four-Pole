//
//  MiniWorksGlobalData.swift
//  4 Pole for the Win
//
//  Created by James B. Majors on 11/7/25.
//

import Foundation

/*
 Global Parameters
 
 MIDI Channel = 585
 MIDI Control = 586
 Device ID = 587
 Start Up Program = 588
 MIDI Note Number = 589
 Knob Mode = 590
 
 */


class MiniWorksGlobalData: Codable {
    /// MIDI Channel for receiving and transmitting
    var midiChannel: UInt8 = 1 {
        didSet { MiniWorksUserDefaults.shared.midiChannel = midiChannel }
    }
    
    /// How controls are transmitted or received
    var midiControl: GlobalMIDIControl = .ctr {
        didSet { MiniWorksUserDefaults.shared.midiControl = midiControl }
    }
    
    /// User settable 0-126
    var deviceID: UInt8 = 0 {
        didSet { MiniWorksUserDefaults.shared.deviceID = deviceID }
    }
    
    /// Program loaded automatically on startup
    var startUpProgramID: UInt8 = 1 {
        didSet {
            MiniWorksUserDefaults.shared.startUpProgramID = startUpProgramID
        }
    }
    
    /// Used to trigger envelope
    var noteNumber: UInt8 = 60 {
        didSet {
            MiniWorksUserDefaults.shared.noteNumber = noteNumber
        }
    }
    
    /// How knobs sync with value display
    var knobMode: GlobalKnobMode = .relative {
        didSet { MiniWorksUserDefaults.shared.knobMode = knobMode }
    }
    
    
    // MARK: - Lifecycle
    
    // From raw data
    convenience init(data: Data) {
        self.init()
        
        let rawBytes = [UInt8](data)
        
        let bytes = Array(rawBytes[585...590])
        
        self.init(bytes: bytes)
    }
    
    
    // From 'Globals' bytes (585 -> 590)
    convenience init(bytes: [UInt8]) {
        self.init()

        midiChannel = bytes[0]
        midiControl = GlobalMIDIControl(rawValue: bytes[1]) ?? .off
        
        deviceID = bytes[2]
        
        startUpProgramID = bytes[3]
        
        noteNumber = bytes[4]
        knobMode = GlobalKnobMode(rawValue: bytes[5]) ?? .relative
    }
    
    
    // MARK: - Public
    
    /// Encode to byte stream
    func encodeToBytes() -> [UInt8] {
        [
            midiChannel,
            UInt8(midiControl.rawValue),
            
            deviceID,
            
            startUpProgramID,
            
            noteNumber,
            UInt8(knobMode.rawValue)
        ]
    }
}


