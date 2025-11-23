//
//  Mod Sources.swift
//  4 Pole for the Win
//
//  Created by James B. Majors on 11/6/25.
//

import Foundation


enum ModulationSource: UInt8, Codable, CaseIterable, Identifiable {
    var id: UInt8 { self.rawValue }
    
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
    
    
    var relatedSources: [ModulationSource] {
        switch self {
            case .lfo: [.lfo, .lfo_ModWheel, .lfo_Aftertouch, .lfo_VCAEnvelope]
            case .vcfEnvelope: [.vcfEnvelope]
            case .vcaEnvelope: [.vcaEnvelope, .velocity_VCAEnvelope]
                
            default: []
        }
    }
    
    
    var shortName: String {
        switch self {
            case .off: return "Off"
            case .lfo: return "LFO"
            case .lfo_ModWheel: return "LFO * ModWhl"
            case .lfo_Aftertouch: return "LFO * AftTch"
            case .lfo_VCAEnvelope: return "LFO * VCAEnv"
            case .vcfEnvelope: return "VCF Env"
            case .vcaEnvelope: return "VCA Env"
            case .signalEnvelope: return "Signal Env"
            case .velocity_VCAEnvelope: return "Vel * VCA Env"
            case .velocity: return "Vel"
            case .keytrack: return "Keytrk"
            case .pitchbend: return "Pttchbnd"
            case .modWheel: return "ModWhl"
            case .aftertouch: return "AftTch"
            case .breathControl: return "Breath"
            case .footcontroller: return "Foot"
        }
    }
    
    
    var name: String {
        switch self {
            case .off: return "Off"
            case .lfo: return "LFO"
            case .lfo_ModWheel: return "LFO * ModWheel"
            case .lfo_Aftertouch: return "LFO * AfterTouch"
            case .lfo_VCAEnvelope: return "LFO * VCAEnvelope"
            case .vcfEnvelope: return "VCF Envelope"
            case .vcaEnvelope: return "VCA Envelope"
            case .signalEnvelope: return "Signal Envelope Follower"
            case .velocity_VCAEnvelope: return "Vel * VCA Envelope"
            case .velocity: return "Velocity"
            case .keytrack: return "Keytracking"
            case .pitchbend: return "Pitchbend"
            case .modWheel: return "ModWheel"
            case .aftertouch: return "AfterTouch"
            case .breathControl: return "Breath Controller"
            case .footcontroller: return "Foot Controller"
        }
    }
}
