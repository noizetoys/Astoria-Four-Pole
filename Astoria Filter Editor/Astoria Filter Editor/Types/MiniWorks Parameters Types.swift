//
//  MiniWorks Parameters.swift
//  4 Pole for the Win
//
//  Created by James B. Majors on 11/6/25.
//

import Foundation
import SwiftUI


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
    
    
    var modulationShortName: String {
        switch self {
            case .LFOSpeedModulationSource: "LFO Speed"
            case .cutoffModulationSource: "Cutoff"
            case .resonanceModulationSource: "Resonace"
            case .volumeModulationSource: "Volume"
            case .panningModulationSource: "Panning"
                
            default: ""
        }
    }
    
    
    var color: Color {
        switch self {
            case .LFOSpeedModulationSource: .green
            case .cutoffModulationSource: .yellow
            case .resonanceModulationSource: .red
            case .volumeModulationSource: .orange
            case .panningModulationSource: .blue
                
            default: .white
        }
    }
    
    
    var ccValue: UInt8 {
        switch self {
            case .VCFEnvelopeAttack:  ContinuousController.VCFEnvelopeAttack
            case .VCFEnvelopeDecay:  ContinuousController.VCFEnvelopeDecay
            case .VCFEnvelopeSustain:  ContinuousController.VCFEnvelopeSustain
            case .VCFEnvelopeRelease:  ContinuousController.VCFEnvelopeRelease
                
            case .VCAEnvelopeAttack:  ContinuousController.VCAEnvelopeAttack
            case .VCAEnvelopeDecay:  ContinuousController.VCAEnvelopeDecay
            case .VCAEnvelopeSustain:  ContinuousController.VCAEnvelopeSustain
            case .VCAEnvelopeRelease:  ContinuousController.VCAEnvelopeRelease
                
            case .VCFEnvelopeCutoffAmount:  ContinuousController.VCFEnvelopeCutoffAmount
            case .VCAEnvelopeVolumeAmount:  ContinuousController.VCAEnvelopeVolumeAmount
                
            case .LFOSpeed:  ContinuousController.LFOSpeed
            case .LFOShape:  ContinuousController.LFOShape
            case .LFOSpeedModulationAmount:  ContinuousController.LFOSpeedModulationAmount
            case .LFOSpeedModulationSource:  ContinuousController.LFOSpeedModulationSource
                
            case .cutoffModulationAmount:  ContinuousController.cutoffModulationAmount
            case .resonanceModulationAmount:  ContinuousController.resonanceModulationAmount
            case .volumeModulationAmount:  ContinuousController.volumeModulationAmount
            case .panningModulationAmount:  ContinuousController.panningModulationAmount
                
            case .cutoffModulationSource:  ContinuousController.cutoffModulationSource
            case .resonanceModulationSource:  ContinuousController.resonanceModulationSource
            case .volumeModulationSource:  ContinuousController.volumeModulationSource
            case .panningModulationSource:  ContinuousController.panningModulationSource
                
            case .cutoff:  ContinuousController.cutoff
            case .resonance:  ContinuousController.resonance
            case .volume:  ContinuousController.volume
            case .panning:  ContinuousController.panning
                
            case .gateTime:  ContinuousController.gateTime
            case .triggerSource:  ContinuousController.triggerSource
            case .triggerMode:  ContinuousController.triggerMode
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
    
    
    var initialValue: UInt8 {
        switch self {
            case .VCFEnvelopeAttack,
            .VCFEnvelopeDecay,
            .VCFEnvelopeSustain,
            .VCFEnvelopeRelease: 64
                
            case .VCAEnvelopeAttack,
            .VCAEnvelopeDecay,
            .VCAEnvelopeSustain,
            .VCAEnvelopeRelease: 64
                
            case .VCFEnvelopeCutoffAmount: 0
            case .VCAEnvelopeVolumeAmount: 64

            case .LFOSpeed: 40
            case .LFOSpeedModulationAmount: 64
            case .LFOShape: 0
            case .LFOSpeedModulationSource: 0
                
            case .cutoffModulationAmount,
            .resonanceModulationAmount,
            .volumeModulationAmount,
            .panningModulationAmount: 64
                
            case .cutoffModulationSource,
            .resonanceModulationSource,
            .volumeModulationSource,
            .panningModulationSource: 0
                
            case .cutoff: 127
            case .resonance: 0
            case .volume: 127
            case .panning: 64
                
            case .gateTime: 16
            case .triggerSource: 0
            case .triggerMode: 0
        }
    }
    
    
    // TODO: Finish Tool Tips
    
    var toolTip: String {
        switch self {
            case .LFOSpeed:  
                "Rate from 0.008 to 261.6Hz"
            case .LFOSpeedModulationAmount: 
                "LFO Speed Modulation Amount"
            case .LFOShape:
                "Choose SIne, Triangle, Saw, Pulse, or Sample & Hold"
            case .LFOSpeedModulationSource:
                "Modulation Source for LFO Speed"
                
            case .cutoffModulationAmount: 
                "Cutoff Modulation Amount\nNegative Values are 'Out of Phase'"
                
            case .VCFEnvelopeAttack:
                "Attack - Ascent rate 2m to 1 minute"
            case .VCFEnvelopeDecay:
                "Decay - Descent rate to 'Sustain'"
            case .VCFEnvelopeSustain:
                "Sustain - Level until 'Release'"
            case .VCFEnvelopeRelease:
                "Release - Descent Rate to '0'"
                
            case .VCAEnvelopeAttack:
                "Attack - Ascent rate 2m to 1 minute"
            case .VCAEnvelopeDecay:
                "Decay - Descent rate to 'Sustain'"
            case .VCAEnvelopeSustain:
                "Sustain - Level until 'Release'"
            case .VCAEnvelopeRelease:
                "Release - Descent Rate to '0'"

            case .VCFEnvelopeCutoffAmount:
                "VCF Envelope Amount on Cutoff\nNegative values lower frequency"
                
            case .VCAEnvelopeVolumeAmount:
                "VCA Envelope Amount on Volume\nNegative values lower level"
                
            case .resonanceModulationAmount:
                "Resonance Modulation Amount\nNegative Values are 'Out of Phase'"
            case .volumeModulationAmount:
                "Volume Modulation Amount\nNegative Values are 'Out of Phase'"
            case .panningModulationAmount:
                "Panning Modulation Amount\nNegative Values are 'Out of Phase'"
                
            case .cutoffModulationSource:
                "Cutoff Modulation Source"
            case .resonanceModulationSource:
                "Resonance Modulation Source"
            case .volumeModulationSource:
                "Volume Modulation Source"
            case .panningModulationSource:
                "Panning Modulation Source"
                
            case .cutoff:
                "Cutoff Filter Frequency"
            case .resonance:
                "Resonance - Amount of Amplification at cutoff Point.  Can Self-Oscillate"
            case .volume:
                "Volume - Starting Audio Level"
            case .panning:
                "Panning - Position of Signal in Stereo Field"
                
            case .gateTime:
                "Gate Time of trigger - 000 to 508 ms."
            case .triggerSource:
                "Trigger Source - Audio, MIDI, or Both"
            case .triggerMode:
                "Trigger Mode - Multi (always) or Signal (after envelope runs)"
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
            case .triggerMode: TriggerMode.allCases.map { .mode($0) }
                
            // All other 21 parameters (Envelopes, Cutoff, Volume, etc.)
            default: nil
        }
    }
}



