//
//  UserDefaults.swift
//  4 Pole for the Win
//
//  Created by James B. Majors on 11/6/25.
//

import Foundation


class MiniWorksUserDefaults {
    static let shared = MiniWorksUserDefaults()
    private init() { }

    private let defaults = UserDefaults.standard
    
    // MARK: -
    /// MIDI Channel for receiving and transmitting
    private let midiChannelKey = "MIDI_CHANNEL"
    var midiChannel: UInt8 {
        set { defaults.set(Int(newValue), forKey: midiChannelKey) }
        get { UInt8(defaults.integer(forKey: midiChannelKey)) }
    }
    
    
    // MARK: -
    /// How controls are transmitted or received
    private let midiControlKey = "MIDI_CONTROL"
    var midiControl: GlobalMIDIControl {
        set { defaults.set(newValue.rawValue, forKey: midiControlKey) }
        get {
            let value = defaults.integer(forKey: midiControlKey)
            return GlobalMIDIControl(rawValue: UInt8(value)) ?? .ctr
        }
    }
    
    
    // MARK: -
    /// User settable 0-126
    private let deviceIDKey = "DEVICE_ID"
    var deviceID: UInt8 {
        set { defaults.set(Int(newValue), forKey: deviceIDKey) }
        get { UInt8(defaults.integer(forKey: deviceIDKey)) }
    }
    
    
    // MARK: -
    /// Program loaded automatically on startup
    private let startUpProgramIDKey = "START_UP_PROGRAM_ID"
    var startUpProgramID: UInt8 {
        set { defaults.set(Int(newValue), forKey: startUpProgramIDKey) }
        get { UInt8(defaults.integer(forKey: startUpProgramIDKey)) }
    }
    
    
    // MARK: -
    /// Used to trigger envelope
    private let noteNumberKey = "NOTE_NUMBER"
    var noteNumber: UInt8 {
        set { defaults.set(Int(newValue), forKey: noteNumberKey) }
        get { UInt8(defaults.integer(forKey: noteNumberKey)) }
    }
    
    
    // MARK: -
    /// How knobs sync with value display
    private let knobModeKey = "KNOB_MODE"
    var knobMode: GlobalKnobMode {
        set { defaults.set(newValue.rawValue, forKey: knobModeKey) }
        get {
            let value = defaults.integer(forKey: knobModeKey)
            return GlobalKnobMode(rawValue: UInt8(value)) ?? .relative
        }
    }

    
}
