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




class MiniWorksGlobalData: Codable, Sendable {
    /// MIDI Channel for receiving and transmitting
    var midiChannel: UInt8 = 1
    
    /// How controls are transmitted or received
    var midiControl: GlobalMIDIControl = .ctr
    
    /// User settable 0-126
    var deviceID: UInt8 = 1
    
    /// Program loaded automatically on startup
    var startUpProgramID: UInt8 = 1
    
    /// Used to trigger envelope
    var noteNumber: UInt8 = 60
    
    /// How knobs sync with value display
    var knobMode: GlobalKnobMode = .relative
    
    
    // MARK: - Lifecycle
    
    // From raw data
    convenience init(fullMessage rawBytes: [UInt8]) {
        let bytes = Array(rawBytes[585...590])
        
        self.init(globalbytes: bytes)
    }
    
    
    // From 'Globals' bytes (585 -> 590)
    convenience init(globalbytes bytes: [UInt8]) {
        self.init()
        
        midiChannel = bytes[0]
        midiControl = GlobalMIDIControl(rawValue: bytes[1]) ?? .off
        
        deviceID = bytes[2]
        
        startUpProgramID = bytes[3]
        
        noteNumber = bytes[4]
        knobMode = GlobalKnobMode(rawValue: bytes[5]) ?? .relative
    }
    
    
    /// Create instance using saved Default Values
    init() {
        self.loadFromDefaults()
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
    
    
    /// Save current values to User Defaults
    func saveToDefaults() {
        UserDefaults.standard.set(midiChannel, forKey: SysExConstant.midiChannelKey)
        UserDefaults.standard.set(midiControl.rawValue, forKey: SysExConstant.midiControlKey)
        UserDefaults.standard.set(deviceID, forKey: SysExConstant.deviceIDKey)
        UserDefaults.standard.set(startUpProgramID, forKey: SysExConstant.startUpProgramIDKey)
        UserDefaults.standard.set(noteNumber, forKey: SysExConstant.noteNumberKey)
        UserDefaults.standard.set(knobMode.rawValue, forKey: SysExConstant.knobModeKey)
        debugPrint(icon: "📚", message: "Defaults Saved")
    }
    
    ///  Set Values to stored values (User Defaults)
    func loadFromDefaults() {
        debugPrint(icon: "📚", message: "")
        midiChannel = UInt8(UserDefaults.standard.integer(forKey: SysExConstant.midiChannelKey))
        
        let control = UInt8(UserDefaults.standard.integer(forKey: SysExConstant.midiControlKey))
        midiControl = GlobalMIDIControl(rawValue: control) ?? .off
        
        deviceID = UInt8(UserDefaults.standard.integer(forKey: SysExConstant.deviceIDKey))
        startUpProgramID = UInt8(UserDefaults.standard.integer(forKey: SysExConstant.startUpProgramIDKey))
        noteNumber = UInt8(UserDefaults.standard.integer(forKey: SysExConstant.noteNumberKey))
        
        let knob = UInt8(UserDefaults.standard.integer(forKey: SysExConstant.knobModeKey))
        knobMode = GlobalKnobMode(rawValue: knob) ?? .relative
    }
}


