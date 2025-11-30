//
//  ModSource.swift
//  MiniWorksMIDI
//
//  Defines modulation sources available on the Waldorf MiniWorks.
//  These are used for various modulation routing parameters throughout
//  the synthesizer architecture.
//

import Foundation

enum ModSource: Int, CaseIterable, Identifiable {
    case off = 0
    case lfo1 = 1
    case lfo2 = 2
    case envelope = 3
    case velocity = 4
    case modWheel = 5
    case aftertouch = 6
    case keytrack = 7
    
    var id: Int { rawValue }
    
    var displayName: String {
        switch self {
        case .off: return "Off"
        case .lfo1: return "LFO 1"
        case .lfo2: return "LFO 2"
        case .envelope: return "Envelope"
        case .velocity: return "Velocity"
        case .modWheel: return "Mod Wheel"
        case .aftertouch: return "Aftertouch"
        case .keytrack: return "Keytrack"
        }
    }
}
