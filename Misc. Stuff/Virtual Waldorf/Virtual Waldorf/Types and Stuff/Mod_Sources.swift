//
//  Mod Sources.swift
//  4 Pole for the Win
//
//  Created by James B. Majors on 11/6/25.
//

import Foundation


enum ModulationSource: UInt8, Codable, CaseIterable {
    case off = 0 // Selection/Option number
    
    case lfo = 1                // Low Frequency Oscillator
    case lfo_ModWheel = 2       // LFO scaled by Mod Wheel
    case lfo_Aftertouch = 3     // LFO scales by Aftertouch
    case lfo_VCAEnvelope = 4    // LFO scaled by VCA Envelope
    
    case vcfEnvelope = 5
    case vcaEnvelope = 6
    
    case signalEnvelope = 7     // Trigger or Audio In
    
        // VCA Envelope scaled according to MIDI Note On Velocity
    case velocity_VCAEnvelope = 8
    case velocity = 9           // MIDI Note on Velocity
    
    case keytrack = 10          // The Note entered via <MIDI NOTE>
    case pitchbend = 11
    case modWheel = 12          // MIDI Controller #1
    case aftertouch = 13        // MIDI Channel Pressure
    
        // MIDI Controller #2 -> Best used with Sequencer
    case breathControl = 14
    case footcontroller = 15    // MIDI Controller #4
    
    
    var name: String {
        switch self {
            case .off: return "Off"
            case .lfo: return "LFO"
            case .lfo_ModWheel: return "LFO * ModWheel"
            case .lfo_Aftertouch: return "LFO * Aftertouch"
            case .lfo_VCAEnvelope: return "LFO * VCAEnvelope"
            case .vcfEnvelope: return "VCF Envelope"
            case .vcaEnvelope: return "VCA Envelope"
            case .signalEnvelope: return "Signal Envelope Follower"
            case .velocity_VCAEnvelope: return "Vel * VCA Envelope"
            case .velocity: return "Velocity"
            case .keytrack: return "Keytrack"
            case .pitchbend: return "Pitchbend"
            case .modWheel: return "ModWheel"
            case .aftertouch: return "Aftertouch"
            case .breathControl: return "Breath Control"
            case .footcontroller: return "Foot Controller"
        }
    }
}
