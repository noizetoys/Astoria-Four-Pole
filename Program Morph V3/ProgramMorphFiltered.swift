//
//  ProgramMorphFiltered.swift
//  Astoria Filter Editor
//
//  Advanced morph with parameter filtering and discrete handling
//

import Foundation
import SwiftUI

/// Advanced program morph with full parameter control
@Observable
final class ProgramMorphFiltered {
    
    // MARK: - Properties
    
    var sourceProgram: MiniWorksProgram {
        didSet {
            if oldValue.id != sourceProgram.id {
                rebuildMorphableParameters()
            }
        }
    }
    
    var destinationProgram: MiniWorksProgram {
        didSet {
            if oldValue.id != destinationProgram.id {
                rebuildMorphableParameters()
            }
        }
    }
    
    var filterConfig: MorphFilterConfig {
        didSet {
            rebuildMorphableParameters()
        }
    }
    
    var morphPosition: Double = 0.0 {
        didSet {
            if isAutoMorphing {
                updateMorphedValues()
            }
        }
    }
    
    var morphDuration: Double = 2.0
    private(set) var isAutoMorphing = false
    var updateRate: Double = 30.0
    var sendCCMessages = true
    
    // MARK: - Internal State
    
    private struct MorphableParameter {
        let type: MiniWorksParameter
        let sourceValue: UInt8
        let destinationValue: UInt8
        let isDiscrete: Bool
        
        var hasChanged: Bool {
            sourceValue != destinationValue
        }
        
        func interpolate(at position: Double, strategy: DiscreteParameterStrategy, threshold: Double) -> UInt8 {
            if isDiscrete {
                return strategy.selectValue(
                    source: sourceValue,
                    destination: destinationValue,
                    position: position,
                    threshold: threshold
                )
            }
            
            guard hasChanged else { return sourceValue }
            
            let fromDouble = Double(sourceValue)
            let toDouble = Double(destinationValue)
            let result = fromDouble + (toDouble - fromDouble) * position
            return UInt8(max(0, min(127, result.rounded())))
        }
    }
    
    private var morphableParameters: [MorphableParameter] = []
    private var lastSentValues: [MiniWorksParameter: UInt8] = [:]
    
    private var morphTimer: Timer?
    private var startTime: Date?
    
    // MARK: - Statistics
    
    private(set) var stats = MorphStatistics()
    
    struct MorphStatistics {
        var totalParameters: Int = 0
        var continuousParameters: Int = 0
        var discreteParameters: Int = 0
        var unchangedParameters: Int = 0
        var messagesSent: Int = 0
        var messagesSaved: Int = 0
        
        var description: String {
            """
            Morph Statistics:
            - Total Parameters: \(totalParameters)
            - Continuous: \(continuousParameters)
            - Discrete: \(discreteParameters)
            - Unchanged: \(unchangedParameters)
            - Messages Sent: \(messagesSent)
            - Messages Saved: \(messagesSaved)
            """
        }
    }
    
    // MARK: - Initialization
    
    init(source: MiniWorksProgram, destination: MiniWorksProgram, config: MorphFilterConfig = .allParameters) {
        self.sourceProgram = source
        self.destinationProgram = destination
        self.filterConfig = config
        rebuildMorphableParameters()
    }
    
    // MARK: - Public Methods
    
    func startMorph(to targetPosition: Double = 1.0) {
        guard !isAutoMorphing else { return }
        
        isAutoMorphing = true
        startTime = Date()
        lastSentValues.removeAll()
        stats.messagesSent = 0
        stats.messagesSaved = 0
        
        let startPosition = morphPosition
        let positionDelta = targetPosition - startPosition
        let interval = 1.0 / updateRate
        
        morphTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            let elapsed = Date().timeIntervalSince(self.startTime!)
            let progress = min(elapsed / self.morphDuration, 1.0)
            let easedProgress = self.easeInOutCubic(progress)
            
            self.morphPosition = startPosition + (positionDelta * easedProgress)
            
            if progress >= 1.0 {
                self.stopMorph()
                self.morphPosition = targetPosition
            }
        }
    }
    
    func stopMorph() {
        morphTimer?.invalidate()
        morphTimer = nil
        isAutoMorphing = false
        startTime = nil
    }
    
    func setMorphPosition(_ position: Double, sendCC: Bool = true) {
        morphPosition = max(0.0, min(1.0, position))
        
        if sendCC && !isAutoMorphing {
            updateMorphedValues()
        }
    }
    
    func swapPrograms() {
        swap(&sourceProgram, &destinationProgram)
        morphPosition = 1.0 - morphPosition
        rebuildMorphableParameters()
        lastSentValues.removeAll()
        updateMorphedValues()
    }
    
    func resetToSource() {
        stopMorph()
        morphPosition = 0.0
        lastSentValues.removeAll()
        updateMorphedValues()
    }
    
    func jumpToDestination() {
        stopMorph()
        morphPosition = 1.0
        lastSentValues.removeAll()
        updateMorphedValues()
    }
    
    // MARK: - Configuration Methods
    
    func enableGroup(_ group: ParameterGroup) {
        filterConfig.enabledGroups.insert(group)
        rebuildMorphableParameters()
    }
    
    func disableGroup(_ group: ParameterGroup) {
        filterConfig.enabledGroups.remove(group)
        rebuildMorphableParameters()
    }
    
    func toggleGroup(_ group: ParameterGroup) {
        if filterConfig.enabledGroups.contains(group) {
            disableGroup(group)
        } else {
            enableGroup(group)
        }
    }
    
    func disableParameter(_ type: MiniWorksParameter) {
        filterConfig.disabledParameters.insert(type)
        rebuildMorphableParameters()
    }
    
    func enableParameter(_ type: MiniWorksParameter) {
        filterConfig.forceEnabledParameters.insert(type)
        rebuildMorphableParameters()
    }
    
    func resetFilter() {
        filterConfig = .allParameters
        rebuildMorphableParameters()
    }
    
    // MARK: - Private Methods
    
    private func rebuildMorphableParameters() {
        morphableParameters.removeAll()
        
        let sourceParams = sourceProgram.morphableParameters(using: filterConfig)
        let destParams = destinationProgram.morphableParameters(using: filterConfig)
        
        guard sourceParams.count == destParams.count else {
            debugPrint(icon: "⚠️", message: "Parameter count mismatch")
            return
        }
        
        stats = MorphStatistics()
        stats.totalParameters = sourceParams.count
        
        for (sourceParam, destParam) in zip(sourceParams, destParams) {
            guard sourceParam.type == destParam.type else { continue }
            
            let isDiscrete = filterConfig.isDiscrete(sourceParam.type)
            
            let morphable = MorphableParameter(
                type: sourceParam.type,
                sourceValue: sourceParam.value,
                destinationValue: destParam.value,
                isDiscrete: isDiscrete
            )
            
            morphableParameters.append(morphable)
            
            if isDiscrete {
                stats.discreteParameters += 1
            } else {
                stats.continuousParameters += 1
            }
            
            if !morphable.hasChanged {
                stats.unchangedParameters += 1
            }
        }
        
        let changingCount = morphableParameters.filter(\.hasChanged).count
        let optimization = stats.totalParameters > 0 ? 
            Double(stats.unchangedParameters) / Double(stats.totalParameters) * 100 : 0
        
        debugPrint(
            icon: "🎛️",
            message: """
            Morph configuration updated:
            - Total: \(stats.totalParameters)
            - Continuous: \(stats.continuousParameters)
            - Discrete: \(stats.discreteParameters)
            - Changing: \(changingCount)
            - Unchanged: \(stats.unchangedParameters) (\(String(format: "%.1f%%", optimization)))
            """
        )
    }
    
    private func updateMorphedValues() {
        guard sendCCMessages else { return }
        
        for param in morphableParameters {
            guard param.hasChanged else { continue }
            
            let strategy = filterConfig.discreteStrategy(for: param.type)
            let threshold = filterConfig.discreteSnapThreshold
            
            let newValue = param.interpolate(
                at: morphPosition,
                strategy: strategy,
                threshold: threshold
            )
            
            // Only send if value changed from last send
            if lastSentValues[param.type] != newValue {
                sendCCUpdate(for: param.type, value: newValue)
                lastSentValues[param.type] = newValue
                stats.messagesSent += 1
            } else {
                stats.messagesSaved += 1
            }
        }
    }
    
    private func sendCCUpdate(for type: MiniWorksParameter, value: UInt8) {
        Task { @MainActor in
            NotificationCenter.default.post(
                name: .programParameterUpdated,
                object: nil,
                userInfo: [
                    SysExConstant.parameterType: type,
                    SysExConstant.parameterValue: value
                ]
            )
        }
    }
    
    private func easeInOutCubic(_ t: Double) -> Double {
        if t < 0.5 {
            return 4 * t * t * t
        } else {
            let f = (2 * t - 2)
            return 1 + f * f * f / 2
        }
    }
}

// MARK: - Query Extensions

extension ProgramMorphFiltered {
    
    /// Get list of parameters that will be morphed
    var morphingParameterNames: [String] {
        morphableParameters.map { $0.type.rawValue }
    }
    
    /// Get list of parameters that are changing
    var changingParameterNames: [String] {
        morphableParameters.filter(\.hasChanged).map { $0.type.rawValue }
    }
    
    /// Get enabled groups
    var enabledGroupNames: [String] {
        filterConfig.enabledGroups.map(\.rawValue).sorted()
    }
    
    /// Detailed report of morph configuration
    var configurationReport: String {
        """
        \(filterConfig.summary(for: sourceProgram))
        
        \(stats.description)
        
        Morphing Parameters:
        \(morphingParameterNames.joined(separator: ", "))
        
        Changing Parameters:
        \(changingParameterNames.joined(separator: ", "))
        """
    }
}
