//
//  LFOShape.swift
//  4 Pole for the Win
//
//  Created by James B. Majors on 11/7/25.
//

import Foundation


enum LFOShape: UInt8, Codable {
    case sine = 0
    case triangle = 1
    case sawtooth = 2
    case pulse = 3
    case sampleHold = 4
    
    var name: String {
        switch self {
            case .sine: return "Sine"
            case .triangle: return "Triangle"
            case .sawtooth: return "Sawtooth"
            case .pulse: return "Pulse/Square"
            case .sampleHold: return "Sample & Hold"
        }
    }
}


enum TriggerSource: UInt8, Codable {
    case audio = 0
    case MIDI = 1
    case all = 2
    
    var name: String {
        switch self {
            case .audio: return "Audio"
            case .MIDI: return "MIDI"
            case .all: return "All"
        }
    }
}


enum TriggerMode: UInt8, Codable {
    case multi = 0
    case single = 1
    
    var name: String {
        switch self {
            case .multi: return "Multi"
            case .single: return "Single"
        }
    }
}


