//
//  MIDI Message Type.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/14/25.
//

import Foundation
import CoreMIDI


//fileprivate var defaultMidiChannel = UInt8(UserDefaults.standard.integer(forKey: SysExConstant.midiChannelKey))

fileprivate let defaultMidiChannel: UInt8 = 1

enum MIDIMessageType: Sendable {
    case sysex([UInt8])
    
    case noteOn(channel: UInt8 = defaultMidiChannel, note: UInt8, velocity: UInt8)
    case noteOff(channel: UInt8 = defaultMidiChannel, note: UInt8, velocity: UInt8)
    
    case controlChange(channel: UInt8 = defaultMidiChannel, cc: UInt8, value: UInt8)
    case programChange(channel: UInt8 = defaultMidiChannel, program: UInt8)
    
    case pitchBend(channel: UInt8 = defaultMidiChannel, value: UInt16)
    
    case aftertouch(channel: UInt8 = defaultMidiChannel, pressure: UInt8)
    case polyAftertouch(channel: UInt8 = defaultMidiChannel, note: UInt8, pressure: UInt8)
}
