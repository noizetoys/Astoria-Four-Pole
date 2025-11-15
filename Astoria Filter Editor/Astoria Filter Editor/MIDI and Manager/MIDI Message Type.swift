//
//  MIDI Message Type.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/14/25.
//

import Foundation
import CoreMIDI


enum MIDIMessageType: Sendable {
    case sysex([UInt8])
    
    case noteOn(channel: UInt8, note: UInt8, velocity: UInt8)
    case noteOff(channel: UInt8, note: UInt8, velocity: UInt8)
    
    case controlChange(channel: UInt8, cc: UInt8, value: UInt8)
    case programChange(channel: UInt8, program: UInt8)

    case pitchBend(channel: UInt8, value: UInt16)
    
    case aftertouch(channel: UInt8, pressure: UInt8)
    case polyAftertouch(channel: UInt8, note: UInt8, pressure: UInt8)

}
