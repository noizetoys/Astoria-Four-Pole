//
//  LFOShape.swift
//  4 Pole for the Win
//
//  Created by James B. Majors on 11/7/25.
//

import Foundation
import SwiftUI


enum ContainedParameter: Codable, Equatable {
    case lfo(LFOType)
    case trigger(TriggerSource)
    case mode(TriggerMode)
    
    
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
enum TriggerMode: String, Codable, CaseIterable {
    case multi = "Multi"
    case single = "Single"
    
    var value: UInt8 {
        switch self {
            case .multi: 0
            case .single: 1
        }
    }
}


extension ContainedParameter {
    private enum CodingKeys: String, CodingKey { case kind, lfo, trigger, mode }
    
    enum Kind: String, Codable { case lfo, trigger, mode }
}

extension ContainedParameter {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        switch kind {
            case .lfo:
                let value = try container.decode(LFOType.self, forKey: .lfo)
                self = .lfo(value)
            case .trigger:
                let value = try container.decode(TriggerSource.self, forKey: .trigger)
                self = .trigger(value)
            case .mode:
                let value = try container.decode(TriggerMode.self, forKey: .mode)
                self = .mode(value)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
            case .lfo(let value):
                try container.encode(Kind.lfo, forKey: .kind)
                try container.encode(value, forKey: .lfo)
            case .trigger(let value):
                try container.encode(Kind.trigger, forKey: .kind)
                try container.encode(value, forKey: .trigger)
            case .mode(let value):
                try container.encode(Kind.mode, forKey: .kind)
                try container.encode(value, forKey: .mode)
        }
    }
}


extension Binding where Value == ContainedParameter {
    var lfoBinding: Binding<LFOType>? {
        switch wrappedValue {
            case .lfo(let current):
                return Binding<LFOType>(
                    get: { current },
                    set: { newValue in
                        wrappedValue = .lfo(newValue)
                    }
                )
            default:
                return nil
        }
    }
    
    var triggerBinding: Binding<TriggerSource>? {
        switch wrappedValue {
            case .trigger(let current):
                return Binding<TriggerSource>(
                    get: { current },
                    set: { newValue in
                        wrappedValue = .trigger(newValue)
                    }
                )
            default:
                return nil
        }
    }
    
    var modeBinding: Binding<TriggerMode>? {
        switch wrappedValue {
            case .mode(let current):
                return Binding<TriggerMode>(
                    get: { current },
                    set: { newValue in
                        wrappedValue = .mode(newValue)
                    }
                )
        default:
            return nil
        }
    }
}
