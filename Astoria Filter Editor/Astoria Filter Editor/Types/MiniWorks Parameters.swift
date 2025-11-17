//
//  MiniWorks Parameters.swift
//  4 Pole for the Win
//
//  Created by James B. Majors on 11/6/25.
//

import Foundation



enum MiniWorksParameter: String, Codable {
    case VCFEnvelopeAttack = "VCF Envelope Attack"
    case VCFEnvelopeDecay = "VCF Envelope Decay"
    case VCFEnvelopeSustain = "VCF Envelope Sustain"
    case VCFEnvelopeRelease = "VCF Envelope Release"
    
    case VCAEnvelopeAttack = "VCA Envelope Attack"
    case VCAEnvelopeDecay = "VCA Envelope Decay"
    case VCAEnvelopeSustain = "VCA Envelope Sustain"
    case VCAEnvelopeRelease = "VCA Envelope Release"
    
    case VCFEnvelopeCutoffAmount = "VCF Envelope Cutoff Amount"
    case VCAEnvelopeVolumeAmount = "VCA Envelope Volume Amount"
    
    case LFOSpeed = "LFO Speed"
    case LFOSpeedModulationAmount = "LFO Speed Modulation Amount"
    case LFOShape = "LFO Shape"
    case LFOSpeedModulationSource = "LFO Speed Modulation Source"
    
    case cutoffModulationAmount = "Cutoff Modulation Amount"
    case resonanceModulationAmount = "Resonance Modulation Amount"
    case volumeModulationAmount = "Volume Modulation Amount"
    case panningModulationAmount = "Panning Modulation Amount"
    
    case cutoffModulationSource = "Cutoff Modulation Source"
    case resonanceModulationSource = "Resonance Modulation Source"
    case volumeModulationSource = "Volume Modulation Source"
    case panningModulationSource = "Panning Modulation Source"
    
    case cutoff = "Cutoff"
    case resonance = "Resonance"
    case volume = "Volume"
    case panning = "Panning"
    
    case gateTime = "Gate Time"
    case triggerSource = "Trigger Source"
    case triggerMode = "Trigger Mode"
    
    
    // Computed Properties
    
    var ccValue: UInt8 {
        switch self {
            case .VCFEnvelopeAttack: 0x0E           // CC#14
            case .VCFEnvelopeDecay: 0x0F            // CC#15
            case .VCFEnvelopeSustain: 0x10          // CC#16
            case .VCFEnvelopeRelease: 0x11          // CC#17
                
            case .VCAEnvelopeAttack: 0x12           // CC#18
            case .VCAEnvelopeDecay: 0x13            // CC#19
            case .VCAEnvelopeSustain: 0x14          // CC#20
            case .VCAEnvelopeRelease: 0x15          // CC#21
                
            case .VCFEnvelopeCutoffAmount: 0x16     // CC#22
            case .VCAEnvelopeVolumeAmount: 0x17     // CC#23
                
            case .LFOSpeed: 0x18                    // CC#24
            case .LFOShape: 0x19                    // CC#25
            case .LFOSpeedModulationAmount: 0x1A    // CC#26
            case .LFOSpeedModulationSource: 0x1B    // CC#27
                
            case .cutoffModulationAmount: 0x46      // CC#70
            case .resonanceModulationAmount: 0x48   // CC#72
            case .volumeModulationAmount: 0x4A      // CC#74
            case .panningModulationAmount: 0x4C     // :#76
                
            case .cutoffModulationSource: 0x47      // CC#71
            case .resonanceModulationSource: 0x49   // CC#73
            case .volumeModulationSource: 0x2A      // CC#75
            case .panningModulationSource: 0x4D     // :#77
                
            case .cutoff: 0x4E                      // CC#78
            case .resonance: 0x4F                   // CC#79
            case .volume: 0x09                      // CC#9
            case .panning: 0x0A                     // :#10
                
            case .gateTime: 0x50                    // CC#80
            case .triggerSource: 0x51               // CC#81
            case .triggerMode: 0x52                 // CC#82
                
        }
    }
    
    
    var bitPosition: Int {
        switch self {
            case .VCFEnvelopeAttack: 6
            case .VCFEnvelopeDecay: 7
            case .VCFEnvelopeSustain: 8
            case .VCFEnvelopeRelease: 9
                
            case .VCAEnvelopeAttack: 10
            case .VCAEnvelopeDecay: 11
            case .VCAEnvelopeSustain: 12
            case .VCAEnvelopeRelease: 13
                
            case .VCFEnvelopeCutoffAmount: 14
            case .VCAEnvelopeVolumeAmount: 15
                
            case .LFOSpeed: 16
            case .LFOSpeedModulationAmount: 17
            case .LFOShape: 18
            case .LFOSpeedModulationSource: 19
                
            case .cutoffModulationAmount: 20
            case .resonanceModulationAmount: 21
            case .volumeModulationAmount: 22
            case .panningModulationAmount: 23
                
            case .cutoffModulationSource: 24
            case .resonanceModulationSource: 25
            case .volumeModulationSource: 26
            case .panningModulationSource: 27
                
            case .cutoff: 28
            case .resonance: 29
            case .volume: 30
            case .panning: 31
                
            case .gateTime: 32
            case .triggerSource: 33
            case .triggerMode: 34
                
        }
    }
    
    
    var valueRange: ClosedRange<UInt8> {
        switch self {
            case .LFOShape: 0...4
                
            case .LFOSpeedModulationSource,
                    .cutoffModulationSource,
                    .resonanceModulationSource,
                    .volumeModulationSource,
                    .panningModulationSource: 0...15
                
            case .triggerSource: 0...2  // 0: Audio, 1: MIDI, 2: All
            case .triggerMode: 0...1    // 0: Multi, 1: Single
                
            default : 0...127   // Most values -> Mapped to other values
        }
    }
    
    
        /// Determines if this parameter selects a ModulationSource enum case. (5 parameters)
    var isModulationSourceSelector: Bool {
        switch self {
            case .LFOSpeedModulationSource,
                    .cutoffModulationSource,
                    .resonanceModulationSource,
                    .volumeModulationSource,
                    .panningModulationSource:
                return true
                
            default: return false
        }
    }
    
    
        /// Determines if this parameter is a Modulation Amount (0-127 slider). (5 parameters)
    var isModulationAmount: Bool {
        switch self {
            case .LFOSpeedModulationAmount,
                    .cutoffModulationAmount,
                    .resonanceModulationAmount,
                    .volumeModulationAmount,
                    .panningModulationAmount:
                return true
                
            default: return false
        }
    }
    
    
        /// Returns the options array if this parameter controls a unique, grouped enum. (3 parameters)
    var containedOptions: [ContainedParameter]? {
        switch self {
            case .LFOShape: LFOType.allCases.map { .lfo($0) }
            case .triggerSource: TriggerSource.allCases.map { .trigger($0) }
            case .triggerMode: Mode.allCases.map { .mode($0) }
                
            // All other 21 parameters (Envelopes, Cutoff, Volume, etc.)
            default: nil
        }
    }
}



    //enum MiniWorksParameter: String, Codable {
    //    case VCFEnvelopeAttack = "VCF Envelope Attack"
    //    case VCFEnvelopeDecay = "VCF Envelope Decay"
    //    case VCFEnvelopeSustain = "VCF Envelope Sustain"
    //    case VCFEnvelopeRelease = "VCF Envelope Release"
    //
    //    case VCAEnvelopeAttack = "VCA Envelope Attack"
    //    case VCAEnvelopeDecay = "VCA Envelope Decay"
    //    case VCAEnvelopeSustain = "VCA Envelope Sustain"
    //    case VCAEnvelopeRelease = "VCA Envelope Release"
    //
    //    case VCFEnvelopeCutoffAmount = "VCF Envelope Cutoff Amount"
    //    case VCAEnvelopeVolumeAmount = "VCA Envelope Volume Amount"
    //
    //    case LFOSpeed = "LFO Speed"
    //    case LFOSpeedModulationAmount = "LFO Speed Modulation Amount"
    //    case LFOShape = "LFO Shape"
    //    case LFOSpeedModulationSource = "LFO Speed Modulation Source"
    //
    //    case cutoffModulationAmount = "Cutoff Modulation Amount"
    //    case resonanceModulationAmount = "Resonance Modulation Amount"
    //    case volumeModulationAmount = "Volume Modulation Amount"
    //    case panningModulationAmount = "Panning Modulation Amount"
    //
    //    case cutoffModulationSource = "Cutoff Modulation Source"
    //    case resonanceModulationSource = "Resonance Modulation Source"
    //    case volumeModulationSource = "Volume Modulation Source"
    //    case panningModulationSource = "Panning Modulation Source"
    //
    //    case cutoff = "Cutoff"
    //    case resonance = "Resonance"
    //    case volume = "Volume"
    //    case panning = "Panning"
    //
    //    case gateTime = "Gate Time"
    //    case triggerSource = "Trigger Source"
    //    case triggerMode = "Trigger Mode"
    //
    //
    //    var ccValue: UInt8 {
    //       switch self {
    //           case .VCFEnvelopeAttack: 0x0E           // CC#14
    //           case .VCFEnvelopeDecay: 0x0F            // CC#15
    //           case .VCFEnvelopeSustain: 0x10          // CC#16
    //           case .VCFEnvelopeRelease: 0x11          // CC#17
//
//           case .VCAEnvelopeAttack: 0x12           // CC#18
//           case .VCAEnvelopeDecay: 0x13            // CC#19
//           case .VCAEnvelopeSustain: 0x14          // CC#20
//           case .VCAEnvelopeRelease: 0x15          // CC#21
//               
//           case .VCFEnvelopeCutoffAmount: 0x16     // CC#22
//           case .VCAEnvelopeVolumeAmount: 0x17     // CC#23
//               
//           case .LFOSpeed: 0x18                    // CC#24
//           case .LFOShape: 0x19                    // CC#25
//           case .LFOSpeedModulationAmount: 0x1A    // CC#26
//           case .LFOSpeedModulationSource: 0x1B    // CC#27
//               
//           case .cutoffModulationAmount: 0x46      // CC#70
//           case .resonanceModulationAmount: 0x48   // CC#72
//           case .volumeModulationAmount: 0x4A      // CC#74
//           case .panningModulationAmount: 0x4C     // :#76
//               
//           case .cutoffModulationSource: 0x47      // CC#71
//           case .resonanceModulationSource: 0x49   // CC#73
//           case .volumeModulationSource: 0x2A      // CC#75
//           case .panningModulationSource: 0x4D     // :#77
//               
//           case .cutoff: 0x4E                      // CC#78
//           case .resonance: 0x4F                   // CC#79
//           case .volume: 0x09                      // CC#9
//           case .panning: 0x0A                     // :#10
//               
//           case .gateTime: 0x50                    // CC#80
//           case .triggerSource: 0x51               // CC#81
//           case .triggerMode: 0x52                 // CC#82
//
//        }
//    }
//    
//    
//    var bitPosition: Int {
//        switch self {
//            case .VCFEnvelopeAttack: 6
//            case .VCFEnvelopeDecay: 7
//            case .VCFEnvelopeSustain: 8
//            case .VCFEnvelopeRelease: 9
//                
//            case .VCAEnvelopeAttack: 10
//            case .VCAEnvelopeDecay: 11
//            case .VCAEnvelopeSustain: 12
//            case .VCAEnvelopeRelease: 13
//                
//            case .VCFEnvelopeCutoffAmount: 14
//            case .VCAEnvelopeVolumeAmount: 15
//                
//            case .LFOSpeed: 16
//            case .LFOSpeedModulationAmount: 17
//            case .LFOShape: 18
//            case .LFOSpeedModulationSource: 19
//                
//            case .cutoffModulationAmount: 20
//            case .resonanceModulationAmount: 21
//            case .volumeModulationAmount: 22
//            case .panningModulationAmount: 23
//                
//            case .cutoffModulationSource: 24
//            case .resonanceModulationSource: 25
//            case .volumeModulationSource: 26
//            case .panningModulationSource: 27
//                
//            case .cutoff: 28
//            case .resonance: 29
//            case .volume: 30
//            case .panning: 31
//                
//            case .gateTime: 32
//            case .triggerSource: 33
//            case .triggerMode: 34
//
//        }
//    }
//    
//    
//    var valueRange: ClosedRange<UInt8> {
//        switch self {
//            case .LFOShape: 1...4
//                
//            case .LFOSpeedModulationSource,
//                    .cutoffModulationSource,
//                    .resonanceModulationSource,
//                    .volumeModulationSource,
//                    .panningModulationSource: 1...15
//                
//            case .triggerSource: 0...2  // 0: Audio, 1: MIDI, 2: All
//            case .triggerMode: 0...1    // 0: Multi, 1: Single
//                
//            default : 0...127   // Most values -> Mapped to other values
//        }
//    }
//    
//        /// Returns true if this parameter controls a selectable ModulationSource.
//    var isModulationSourceSelector: Bool {
//        switch self {
//            case .LFOSpeedModulationSource,
//                    .cutoffModulationSource,
//                    .resonanceModulationSource,
//                    .volumeModulationSource,
//                    .panningModulationSource:
//                return true
//            default:
//                return false
//        }
//    }
//    
//        /// Returns true if this parameter controls a Modulation Amount.
//    var isModulationAmount: Bool {
//        switch self {
//            case .LFOSpeedModulationAmount,
//                    .cutoffModulationAmount,
//                    .resonanceModulationAmount,
//                    .volumeModulationAmount,
//                    .panningModulationAmount:
//                return true
//            default:
//                return false
//        }
//    }
//    
//        /// Returns the options array if this parameter controls a unique, grouped enum (LFO Shape, Trigger Source/Mode).
//    var containedOptions: [ContainedParameter]? {
//        switch self {
//            case .LFOShape:
//                return LFOType.allCases.map { .lfo($0) }
//                
//            case .triggerSource:
//                return TriggerSource.allCases.map { .trigger($0) }
//                
//            case .triggerMode:
//                return Mode.allCases.map { .mode($0) }
//                
//            default:
//                    // This covers all envelope, VCA/VCF amounts, and standard parameters
//                return nil
//        }
//    }
//}
