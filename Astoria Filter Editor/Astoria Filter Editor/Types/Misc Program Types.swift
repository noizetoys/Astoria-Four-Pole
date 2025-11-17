//
//  LFOShape.swift
//  4 Pole for the Win
//
//  Created by James B. Majors on 11/7/25.
//

import Foundation


enum ContainedParameter: Codable {
    case lfo(LFOType)
    case trigger(TriggerSource)
    case mode(Mode)
    
    
    var name: String {
        switch self {
            case .lfo(let lfo): return lfo.rawValue
            case .trigger(let trigger): return trigger.rawValue
            case .mode(let mode): return mode.rawValue
        }
    }
    
        // Used for MIDI value lookup
        // Note: Since the underlying LFO, Trigger, and Mode enums have unique
        // value mappings (e.g., LFO's 0 is Sine, Trigger's 0 is Audio), no offset is needed.
    var value: UInt8 {
        switch self {
            case .lfo(let lfo): return lfo.value
            case .trigger(let trigger): return trigger.value
            case .mode(let mode): return mode.value
        }
    }
    
        // NOTE: Custom Codable implementation is required for this enum due to associated values.
}


    // MARK: - LFO Shapes
enum LFOType: String, Codable, CaseIterable {
    case sine = "Sine"
    case triangle = "Triangle"
    case sawtooth = "Sawtooth"
    case pulse = "Pulse/Square"
    case sampleHold = "Sample & Hold"
    
    var value: UInt8 {
        switch self {
            case .sine: 0
            case .triangle: 1
            case .sawtooth: 2
            case .pulse: 3
            case .sampleHold: 4
        }
    }
}


    // MARK: - Trigger Sources
enum TriggerSource: String, Codable, CaseIterable {
    case audio = "Audio"
    case MIDI = "MIDI"
    case all = "All"
    
    var value: UInt8 {
        switch self {
            case .audio: 0
            case .MIDI: 1
            case .all: 2
        }
    }
}


    // MARK: - Trigger Modes
enum Mode: String, Codable, CaseIterable {
    case multi = "Multi"
    case single = "Single"
    
    var value: UInt8 {
        switch self {
            case .multi: 0
            case .single: 1
        }
    }
}


