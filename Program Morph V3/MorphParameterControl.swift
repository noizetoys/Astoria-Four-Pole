//
//  MorphParameterControl.swift
//  Astoria Filter Editor
//
//  Comprehensive system for controlling which parameters morph
//

import Foundation
import SwiftUI

// MARK: - Parameter Groups

/// Logical groupings of parameters for selective morphing
enum ParameterGroup: String, CaseIterable, Identifiable {
    case vcfEnvelope = "VCF Envelope"
    case vcaEnvelope = "VCA Envelope"
    case vcfModulation = "VCF Modulation"
    case vcaModulation = "VCA Modulation"
    case lfo = "LFO"
    case filters = "Filters"
    case output = "Output"
    case timing = "Timing"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .vcfEnvelope: return "waveform.path.ecg"
        case .vcaEnvelope: return "waveform.path"
        case .vcfModulation: return "slider.horizontal.3"
        case .vcaModulation: return "slider.vertical.3"
        case .lfo: return "waveform"
        case .filters: return "equalizer"
        case .output: return "speaker.wave.2"
        case .timing: return "timer"
        }
    }
    
    var description: String {
        switch self {
        case .vcfEnvelope:
            return "Filter envelope ADSR and cutoff amount"
        case .vcaEnvelope:
            return "Amplitude envelope ADSR and volume amount"
        case .vcfModulation:
            return "Cutoff and resonance modulation amounts"
        case .vcaModulation:
            return "Volume and panning modulation amounts"
        case .lfo:
            return "LFO speed and speed modulation amount"
        case .filters:
            return "Cutoff, resonance"
        case .output:
            return "Volume, panning"
        case .timing:
            return "Gate time"
        }
    }
    
    /// Which parameter types belong to this group
    func contains(_ type: MiniWorksParameter) -> Bool {
        switch self {
        case .vcfEnvelope:
            return [.VCFEnvelopeAttack, .VCFEnvelopeDecay, .VCFEnvelopeSustain, 
                    .VCFEnvelopeRelease, .VCFEnvelopeCutoffAmount].contains(type)
            
        case .vcaEnvelope:
            return [.VCAEnvelopeAttack, .VCAEnvelopeDecay, .VCAEnvelopeSustain,
                    .VCAEnvelopeRelease, .VCAEnvelopeVolumeAmount].contains(type)
            
        case .vcfModulation:
            return [.cutoffModulationAmount, .resonanceModulationAmount].contains(type)
            
        case .vcaModulation:
            return [.volumeModulationAmount, .panningModulationAmount].contains(type)
            
        case .lfo:
            return [.LFOSpeed, .LFOSpeedModulationAmount].contains(type)
            
        case .filters:
            return [.cutoff, .resonance].contains(type)
            
        case .output:
            return [.volume, .panning].contains(type)
            
        case .timing:
            return [.gateTime].contains(type)
        }
    }
}

// MARK: - Discrete Parameter Handling Strategy

/// How to handle discrete (enum-based) parameters during morphing
enum DiscreteParameterStrategy: String, CaseIterable, Identifiable {
    case ignore = "Ignore"
    case snapAtHalf = "Snap at 50%"
    case snapAtThreshold = "Snap at Threshold"
    case useSource = "Use Source"
    case useDestination = "Use Destination"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .ignore:
            return "Don't change discrete parameters"
        case .snapAtHalf:
            return "Switch from source to destination at 50% morph position"
        case .snapAtThreshold:
            return "Switch at custom threshold (e.g., 75%)"
        case .useSource:
            return "Always use source program value"
        case .useDestination:
            return "Always use destination program value"
        }
    }
    
    /// Determine which value to use for a discrete parameter
    func selectValue(source: UInt8, destination: UInt8, position: Double, threshold: Double = 0.5) -> UInt8 {
        switch self {
        case .ignore:
            return source  // Keep current value
        case .snapAtHalf:
            return position < 0.5 ? source : destination
        case .snapAtThreshold:
            return position < threshold ? source : destination
        case .useSource:
            return source
        case .useDestination:
            return destination
        }
    }
}

// MARK: - Morph Filter Configuration

/// Configuration for controlling which parameters participate in morphing
@Observable
class MorphFilterConfig {
    
    // MARK: - Group Selection
    
    /// Which parameter groups are enabled for morphing
    var enabledGroups: Set<ParameterGroup> = Set(ParameterGroup.allCases)
    
    /// Quick toggles for common scenarios
    var envelopesOnly: Bool {
        get {
            enabledGroups == [.vcfEnvelope, .vcaEnvelope]
        }
        set {
            if newValue {
                enabledGroups = [.vcfEnvelope, .vcaEnvelope]
            }
        }
    }
    
    var filtersOnly: Bool {
        get {
            enabledGroups == [.filters, .vcfModulation]
        }
        set {
            if newValue {
                enabledGroups = [.filters, .vcfModulation]
            }
        }
    }
    
    // MARK: - Individual Parameter Control
    
    /// Specifically disabled parameters (overrides group settings)
    var disabledParameters: Set<MiniWorksParameter> = []
    
    /// Specifically enabled parameters (overrides group settings)
    var forceEnabledParameters: Set<MiniWorksParameter> = []
    
    // MARK: - Discrete Parameter Handling
    
    /// How to handle modulation source selectors
    var modulationSourceStrategy: DiscreteParameterStrategy = .snapAtHalf
    
    /// Threshold for snap-at-threshold strategy
    var discreteSnapThreshold: Double = 0.75
    
    /// Whether to include LFO shape (discrete parameter)
    var includeLFOShape: Bool = false
    
    /// Whether to include trigger source (discrete parameter)
    var includeTriggerSource: Bool = false
    
    /// Whether to include trigger mode (discrete parameter)
    var includeTriggerMode: Bool = false
    
    // MARK: - Query Methods
    
    /// Check if a parameter should be morphed
    func shouldMorph(_ type: MiniWorksParameter) -> Bool {
        // Force disabled overrides everything
        if disabledParameters.contains(type) {
            return false
        }
        
        // Force enabled overrides group settings
        if forceEnabledParameters.contains(type) {
            return true
        }
        
        // Check if parameter's group is enabled
        for group in ParameterGroup.allCases {
            if group.contains(type) {
                return enabledGroups.contains(group)
            }
        }
        
        // Default: don't morph if not in any group
        return false
    }
    
    /// Check if a parameter is discrete (enum-based)
    func isDiscrete(_ type: MiniWorksParameter) -> Bool {
        type.isModulationSourceSelector || 
        type == .LFOShape ||
        type == .triggerSource ||
        type == .triggerMode
    }
    
    /// Get the appropriate strategy for a discrete parameter
    func discreteStrategy(for type: MiniWorksParameter) -> DiscreteParameterStrategy {
        if type.isModulationSourceSelector {
            return modulationSourceStrategy
        }
        
        // LFO Shape, trigger source/mode use same strategy
        return modulationSourceStrategy
    }
    
    // MARK: - Presets
    
    static var allParameters: MorphFilterConfig {
        let config = MorphFilterConfig()
        config.enabledGroups = Set(ParameterGroup.allCases)
        return config
    }
    
    static var envelopesOnly: MorphFilterConfig {
        let config = MorphFilterConfig()
        config.enabledGroups = [.vcfEnvelope, .vcaEnvelope]
        return config
    }
    
    static var filtersOnly: MorphFilterConfig {
        let config = MorphFilterConfig()
        config.enabledGroups = [.filters, .vcfModulation]
        return config
    }
    
    static var modulationOnly: MorphFilterConfig {
        let config = MorphFilterConfig()
        config.enabledGroups = [.vcfModulation, .vcaModulation, .lfo]
        return config
    }
    
    static var vcfOnly: MorphFilterConfig {
        let config = MorphFilterConfig()
        config.enabledGroups = [.vcfEnvelope, .filters, .vcfModulation]
        return config
    }
    
    static var vcaOnly: MorphFilterConfig {
        let config = MorphFilterConfig()
        config.enabledGroups = [.vcaEnvelope, .output, .vcaModulation]
        return config
    }
}

// MARK: - Enhanced Program Extension

extension MiniWorksProgram {
    
    /// Get all parameters that should be morphed based on configuration
    func morphableParameters(using config: MorphFilterConfig) -> [ProgramParameter] {
        let allParams = [
            vcfEnvelopeAttack, vcfEnvelopeDecay, vcfEnvelopeSustain, vcfEnvelopeRelease,
            vcaEnvelopeAttack, vcaEnvelopeDecay, vcaEnvelopeSustain, vcaEnvelopeRelease,
            vcfEnvelopeCutoffAmount, vcaEnvelopeVolumeAmount,
            lfoSpeed, lfoSpeedModulationAmount,
            cutoffModulationAmount, resonanceModulationAmount,
            volumeModulationAmount, panningModulationAmount,
            cutoff, resonance, volume, panning,
            gateTime
        ]
        
        // Add optional discrete parameters if enabled
        var params = allParams
        
        if config.includeLFOShape {
            params.append(lfoShape)
        }
        
        if config.includeTriggerSource {
            params.append(triggerSource)
        }
        
        if config.includeTriggerMode {
            params.append(triggerMode)
        }
        
        // Filter based on configuration
        return params.filter { param in
            // Skip modulation sources unless explicitly included
            if param.isModSource && !config.forceEnabledParameters.contains(param.type) {
                return false
            }
            
            return config.shouldMorph(param.type)
        }
    }
    
    /// Get parameters grouped by category
    var parametersByGroup: [ParameterGroup: [ProgramParameter]] {
        var grouped: [ParameterGroup: [ProgramParameter]] = [:]
        
        let allParams = [
            vcfEnvelopeAttack, vcfEnvelopeDecay, vcfEnvelopeSustain, vcfEnvelopeRelease,
            vcfEnvelopeCutoffAmount,
            vcaEnvelopeAttack, vcaEnvelopeDecay, vcaEnvelopeSustain, vcaEnvelopeRelease,
            vcaEnvelopeVolumeAmount,
            lfoSpeed, lfoSpeedModulationAmount, lfoShape, lfoSpeedModulationSource,
            cutoffModulationAmount, resonanceModulationAmount,
            volumeModulationAmount, panningModulationAmount,
            cutoffModulationSource, resonanceModulationSource,
            volumeModulationSource, panningModulationSource,
            cutoff, resonance, volume, panning,
            gateTime, triggerSource, triggerMode
        ]
        
        for group in ParameterGroup.allCases {
            grouped[group] = allParams.filter { group.contains($0.type) }
        }
        
        return grouped
    }
}

// MARK: - Analysis Extension

extension MorphFilterConfig {
    
    /// Get a summary of what will be morphed
    func summary(for program: MiniWorksProgram) -> String {
        let morphable = program.morphableParameters(using: self)
        let total = program.allParameters.count
        
        let groupSummary = enabledGroups.map(\.rawValue).sorted().joined(separator: ", ")
        
        return """
        Morph Filter Summary:
        - Enabled Groups: \(groupSummary)
        - Parameters to Morph: \(morphable.count) of \(total)
        - Disabled: \(disabledParameters.count) specific parameters
        - Force Enabled: \(forceEnabledParameters.count) specific parameters
        - Discrete Strategy: \(modulationSourceStrategy.rawValue)
        """
    }
    
    /// Get list of parameters that will be morphed
    func morphedParameterNames(for program: MiniWorksProgram) -> [String] {
        program.morphableParameters(using: self).map(\.name)
    }
}
