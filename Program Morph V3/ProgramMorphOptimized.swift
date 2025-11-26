//
//  ProgramMorphOptimized.swift
//  Astoria Filter Editor
//
//  Optimized version that only updates parameters that actually change
//

import Foundation
import SwiftUI
import Combine

/// Tracks a parameter that changes during morphing
private struct MorphableParameter {
    let type: MiniWorksParameter
    let sourceValue: UInt8
    let destinationValue: UInt8
    
    var hasChanged: Bool {
        sourceValue != destinationValue
    }
    
    func interpolate(at position: Double) -> UInt8 {
        guard hasChanged else { return sourceValue }
        
        let fromDouble = Double(sourceValue)
        let toDouble = Double(destinationValue)
        let result = fromDouble + (toDouble - fromDouble) * position
        return UInt8(max(0, min(127, result.rounded())))
    }
}

/// Optimized program morphing that only processes changed parameters
@Observable
final class ProgramMorphOptimized {
    
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
    
    var morphPosition: Double = 0.0 {
        didSet {
            if isAutoMorphing {
                updateChangedParameters()
            }
        }
    }
    
    var morphDuration: Double = 2.0
    private(set) var isAutoMorphing = false
    var updateRate: Double = 30.0
    var sendCCMessages = true
    
    // MARK: - Optimization State
    
    /// Only parameters that actually change between source and destination
    private var changedParameters: [MorphableParameter] = []
    
    /// Cache of last sent values to avoid duplicate CC messages
    private var lastSentValues: [MiniWorksParameter: UInt8] = [:]
    
    /// Statistics for monitoring
    private(set) var totalParameters: Int = 0
    private(set) var unchangedParameters: Int = 0
    private(set) var messagesSaved: Int = 0
    
    // MARK: - Private Properties
    
    private var morphTimer: Timer?
    private var startTime: Date?
    
    // MARK: - Initialization
    
    init(source: MiniWorksProgram, destination: MiniWorksProgram) {
        self.sourceProgram = source
        self.destinationProgram = destination
        rebuildMorphableParameters()
    }
    
    // MARK: - Public Methods
    
    func startMorph(to targetPosition: Double = 1.0) {
        guard !isAutoMorphing else { return }
        
        isAutoMorphing = true
        startTime = Date()
        lastSentValues.removeAll() // Clear cache at start of morph
        
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
            updateChangedParameters()
        }
    }
    
    func swapPrograms() {
        swap(&sourceProgram, &destinationProgram)
        morphPosition = 1.0 - morphPosition
        rebuildMorphableParameters()
        lastSentValues.removeAll()
        updateChangedParameters()
    }
    
    func resetToSource() {
        stopMorph()
        morphPosition = 0.0
        lastSentValues.removeAll()
        updateChangedParameters()
    }
    
    func jumpToDestination() {
        stopMorph()
        morphPosition = 1.0
        lastSentValues.removeAll()
        updateChangedParameters()
    }
    
    /// Returns the percentage of parameters that don't change
    var optimizationRatio: Double {
        guard totalParameters > 0 else { return 0 }
        return Double(unchangedParameters) / Double(totalParameters)
    }
    
    // MARK: - Private Methods
    
    private func rebuildMorphableParameters() {
        let sourceProps = sourceProgram.allParameters
        let destProps = destinationProgram.allParameters
        
        guard sourceProps.count == destProps.count else {
            debugPrint(icon: "⚠️", message: "Parameter count mismatch between programs")
            return
        }
        
        changedParameters.removeAll()
        totalParameters = 0
        unchangedParameters = 0
        
        for (sourceParam, destParam) in zip(sourceProps, destProps) {
            // Only consider parameters that use CC and have numeric values
            guard sourceParam.type == destParam.type,
                  !sourceParam.isModSource,
                  sourceParam.containedParameter == nil else {
                continue
            }
            
            totalParameters += 1
            
            let morphable = MorphableParameter(
                type: sourceParam.type,
                sourceValue: sourceParam.value,
                destinationValue: destParam.value
            )
            
            if morphable.hasChanged {
                changedParameters.append(morphable)
            } else {
                unchangedParameters += 1
            }
        }
        
        debugPrint(
            icon: "🎛️",
            message: "Morph optimization: \(changedParameters.count) changing, \(unchangedParameters) unchanged (\(String(format: "%.1f%%", optimizationRatio * 100)) reduction)"
        )
    }
    
    private func updateChangedParameters() {
        guard sendCCMessages else { return }
        
        // Only iterate through parameters that actually change
        for param in changedParameters {
            let newValue = param.interpolate(at: morphPosition)
            
            // Additional optimization: only send if value actually changed from last send
            if lastSentValues[param.type] != newValue {
                sendCCUpdate(for: param.type, value: newValue)
                lastSentValues[param.type] = newValue
            } else {
                messagesSaved += 1
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

// MARK: - Additional Optimizations

extension ProgramMorphOptimized {
    
    /// Returns detailed statistics about the current morph
    struct MorphStatistics {
        let totalParameters: Int
        let changingParameters: Int
        let unchangedParameters: Int
        let optimizationPercentage: Double
        let messagesSaved: Int
        let estimatedMessagesPerUpdate: Int
        let estimatedBandwidthUsage: Double // bytes per second
        
        var description: String {
            """
            Morph Statistics:
            - Total Parameters: \(totalParameters)
            - Changing: \(changingParameters)
            - Unchanged: \(unchangedParameters)
            - Optimization: \(String(format: "%.1f%%", optimizationPercentage * 100))
            - Messages Saved: \(messagesSaved)
            - Messages/Update: \(estimatedMessagesPerUpdate)
            - Bandwidth: \(String(format: "%.0f", estimatedBandwidthUsage)) bytes/sec
            """
        }
    }
    
    var statistics: MorphStatistics {
        let messagesPerUpdate = changedParameters.count
        let bytesPerUpdate = messagesPerUpdate * 3 // Each CC message is 3 bytes
        let bandwidthUsage = Double(bytesPerUpdate) * updateRate
        
        return MorphStatistics(
            totalParameters: totalParameters,
            changingParameters: changedParameters.count,
            unchangedParameters: unchangedParameters,
            optimizationPercentage: optimizationRatio,
            messagesSaved: messagesSaved,
            estimatedMessagesPerUpdate: messagesPerUpdate,
            estimatedBandwidthUsage: bandwidthUsage
        )
    }
    
    /// Reset statistics counters
    func resetStatistics() {
        messagesSaved = 0
    }
}

// MARK: - Even More Aggressive Optimization

extension ProgramMorphOptimized {
    
    /// Configure value change threshold to avoid sending tiny changes
    /// Default is 1 (any change), but you can set to 2-3 to reduce message count
    var valueChangeThreshold: UInt8 {
        get { _valueChangeThreshold }
        set { _valueChangeThreshold = max(1, newValue) }
    }
    private var _valueChangeThreshold: UInt8 = 1
    
    /// Check if value change exceeds threshold
    private func shouldSendUpdate(oldValue: UInt8, newValue: UInt8) -> Bool {
        let delta = abs(Int(newValue) - Int(oldValue))
        return delta >= Int(valueChangeThreshold)
    }
    
    /// Update with threshold checking
    private func updateChangedParametersWithThreshold() {
        guard sendCCMessages else { return }
        
        for param in changedParameters {
            let newValue = param.interpolate(at: morphPosition)
            let lastValue = lastSentValues[param.type] ?? param.sourceValue
            
            if shouldSendUpdate(oldValue: lastValue, newValue: newValue) {
                sendCCUpdate(for: param.type, value: newValue)
                lastSentValues[param.type] = newValue
            } else {
                messagesSaved += 1
            }
        }
    }
}

// MARK: - Comparison Methods

extension ProgramMorphOptimized {
    
    /// Compare efficiency with non-optimized approach
    func compareWithNaiveApproach(updateCount: Int = 100) -> String {
        let naiveMessages = totalParameters * updateCount
        let optimizedMessages = changedParameters.count * updateCount
        let saved = naiveMessages - optimizedMessages
        let percentSaved = Double(saved) / Double(naiveMessages) * 100
        
        return """
        Efficiency Comparison (for \(updateCount) updates):
        
        Naive Approach:
        - Messages sent: \(naiveMessages)
        - Bandwidth: \(naiveMessages * 3) bytes
        
        Optimized Approach:
        - Messages sent: \(optimizedMessages)
        - Bandwidth: \(optimizedMessages * 3) bytes
        
        Savings:
        - Messages saved: \(saved)
        - Bandwidth saved: \(saved * 3) bytes
        - Efficiency gain: \(String(format: "%.1f%%", percentSaved))
        """
    }
}
