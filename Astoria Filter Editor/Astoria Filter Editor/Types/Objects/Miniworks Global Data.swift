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
    @GlobalSetting(key: SysExConstant.midiChannelKey)
    var midiChannel: UInt8 = 0x01
    
    /// How controls are transmitted or received
    @GlobalSetting(key: SysExConstant.midiControlKey)
    var midiControl: GlobalMIDIControl = .ctr
    
    /// User settable 0-126
    @GlobalSetting(key: SysExConstant.deviceIDKey)
    var deviceID: UInt8 = 1
    
    /// Program loaded automatically on startup
    @GlobalSetting(key: SysExConstant.startUpProgramIDKey)
    var startUpProgramID: UInt8 = 1
    
    /// Used to trigger envelope
    @GlobalSetting(key: SysExConstant.noteNumberKey)
    var noteNumber: UInt8 = 60
    
    /// How knobs sync with value display
    @GlobalSetting(key: SysExConstant.knobModeKey)
    var knobMode: GlobalKnobMode = .relative

    private enum CodingKeys: String, CodingKey {
        case midiChannel
        case midiControl
        case deviceID
        case startUpProgramID
        case noteNumber
        case knobMode
    }

    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init() // load defaults first

        if let channel = try container.decodeIfPresent(UInt8.self, forKey: .midiChannel) {
            self.midiChannel = channel
        }

        if let controlRaw = try container.decodeIfPresent(UInt8.self, forKey: .midiControl) {
            self.midiControl = GlobalMIDIControl(rawValue: controlRaw) ?? self.midiControl
        }

        if let devID = try container.decodeIfPresent(UInt8.self, forKey: .deviceID) {
            self.deviceID = devID
        }

        if let startProg = try container.decodeIfPresent(UInt8.self, forKey: .startUpProgramID) {
            self.startUpProgramID = startProg
        }

        if let note = try container.decodeIfPresent(UInt8.self, forKey: .noteNumber) {
            self.noteNumber = note
        }

        if let knobRaw = try container.decodeIfPresent(UInt8.self, forKey: .knobMode) {
            self.knobMode = GlobalKnobMode(rawValue: knobRaw) ?? self.knobMode
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(midiChannel, forKey: .midiChannel)
        try container.encode(midiControl.rawValue, forKey: .midiControl)
        try container.encode(deviceID, forKey: .deviceID)
        try container.encode(startUpProgramID, forKey: .startUpProgramID)
        try container.encode(noteNumber, forKey: .noteNumber)
        try container.encode(knobMode.rawValue, forKey: .knobMode)
    }
    
    
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
        midiChannel = UInt8(UserDefaults.standard.integer(forKey: SysExConstant.midiChannelKey))
        
        let control = UInt8(UserDefaults.standard.integer(forKey: SysExConstant.midiControlKey))
        midiControl = GlobalMIDIControl(rawValue: control) ?? .off
        
        deviceID = UInt8(UserDefaults.standard.integer(forKey: SysExConstant.deviceIDKey))
        startUpProgramID = UInt8(UserDefaults.standard.integer(forKey: SysExConstant.startUpProgramIDKey))
        noteNumber = UInt8(UserDefaults.standard.integer(forKey: SysExConstant.noteNumberKey))
        
        let knob = UInt8(UserDefaults.standard.integer(forKey: SysExConstant.knobModeKey))
        knobMode = GlobalKnobMode(rawValue: knob) ?? .relative
        
        debugPrint(icon: "📚", message: "channel: \(midiChannel), control: \(midiControl), noteNumber: \(noteNumber), deviceID: \(deviceID)")
    }
}

