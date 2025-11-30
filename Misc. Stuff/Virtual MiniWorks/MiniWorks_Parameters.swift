//
//  MiniWorks Parameters.swift
//  4 Pole for the Win
//
//  Created by James B. Majors on 11/6/25.
//

import Foundation


enum MiniWorksParameter: Int, Codable {
    case VCFEnvelopeAttack = 6 // Byte #
    case VCFEnvelopeDecay = 7
    case VCFEnvelopeSustain = 8
    case VCFEnvelopeRelease = 9
    
    case VCAEnvelopeAttack = 10
    case VCAEnvelopeDecay = 11
    case VCAEnvelopeSustain = 12
    case VCAEnvelopeRelease = 13
    
    case VCFEnvelopeCutoffAmount = 14
    case VCAEnvelopeVolumeAmount = 15
    
    case LFOSpeed = 16
    case LFOSpeedModulationAmount = 17
    case LFOShape = 18
    case LFOSpeedModulationSource = 19
    
    case cutoffModulationAmount = 20
    case resonanceModulationAmount = 21
    case volumeModulationAmount = 22
    case panningModulationAmount = 23

    case cutoffModulationSource = 24
    case resonanceModulationSource = 25
    case volumeModulationSource = 26
    case panningModulationSource = 27

    case cutoff = 28
    case resonance = 29
    case volume = 30
    case panning = 31
    
    case gateTime = 32
    case triggerSource = 33
    case triggerMode = 34
    
    
    var midiRange: ClosedRange<UInt8> {
        switch self {
            case .LFOShape: 1...4
                
            case .LFOSpeedModulationSource,
                    .cutoffModulationSource,
                    .resonanceModulationSource,
                    .volumeModulationSource,
                    .panningModulationSource: 1...15
                
            case .triggerSource: 0...2  // 0: Audio, 1: MIDI, 2: All
            case .triggerMode: 0...1    // 0: Multi, 1: Single
                
            default : 0...127   // Most values -> Mapped to other values
        }
    }
    
    
//    func mappedMIDIValue(_ value: Int) -> Int {
//        switch self {
//            // Log - 0 = 2ms, 64 = 60 sec, 127 = 1 min.
//            case .VCFEnvelopeAttack, .VCAEnvelopeAttack: return 0
//                
//                // 0.008 - 261.1 Hz
//            case .LFOSpeed: return 0
//                
//                // 000...508 ms, 1.00...1.02
//            case .gateTime: return 0
//                
//                // 0...127 -> -64...63
//            case .VCFEnvelopeCutoffAmount, .VCAEnvelopeVolumeAmount,
//                    .LFOSpeedModulationAmount, .cutoffModulationAmount,
//                    .resonanceModulationAmount, .volumeModulationAmount,
//                    .panning, .panningModulationAmount: return value - 64
//
//            default: return value
////                // 0-127
////            case .VCFEnvelopeDecay, .VCFEnvelopeSustain, .VCFEnvelopeRelease, .VCAEnvelopeDecay, .VCAEnvelopeSustain, .VCAEnvelopeRelease:
////            case .LFOShape: return value
////            case .LFOSpeedModulationSource, .cutoffModulationSource,
////                    .resonanceModulationSource, .volumeModulationSource,
////                    .panningModulationSource, .triggerSource, .triggerMode:
////                return value
////
////            case .cutoff:
////            case .resonance:
////            case .volume:
//
//        }
//    }
    
}
