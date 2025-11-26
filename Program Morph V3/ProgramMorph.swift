//
//  ProgramMorph.swift
//  Astoria Filter Editor
//
//  Created for morphing between MiniWorks programs
//

import Foundation
import SwiftUI
import Combine

/// Manages morphing between two MiniWorks programs
@Observable
final class ProgramMorph {
    
    // MARK: - Properties
    
    /// Source program (morph position = 0.0)
    var sourceProgram: MiniWorksProgram
    
    /// Destination program (morph position = 1.0)
    var destinationProgram: MiniWorksProgram
    
    /// Current morph position (0.0 = source, 1.0 = destination)
    var morphPosition: Double = 0.0 {
        didSet {
            if isAutoMorphing {
                updateMorphedValues()
            }
        }
    }
    
    /// Duration of the morph in seconds
    var morphDuration: Double = 2.0
    
    /// Whether morphing is currently in progress
    private(set) var isAutoMorphing = false
    
    /// Rate at which CC messages are sent (Hz)
    var updateRate: Double = 30.0 // 30 updates per second
    
    /// Whether to send CC messages during morphing
    var sendCCMessages = true
    
    // MARK: - Private Properties
    
    private var morphTimer: Timer?
    private var startTime: Date?
    
    // MARK: - Initialization
    
    init(source: MiniWorksProgram, destination: MiniWorksProgram) {
        self.sourceProgram = source
        self.destinationProgram = destination
    }
    
    // MARK: - Public Methods
    
    /// Start automatic morphing from current position to target
    func startMorph(to targetPosition: Double = 1.0) {
        guard !isAutoMorphing else { return }
        
        isAutoMorphing = true
        startTime = Date()
        
        let startPosition = morphPosition
        let positionDelta = targetPosition - startPosition
        let interval = 1.0 / updateRate
        
        morphTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            let elapsed = Date().timeIntervalSince(self.startTime!)
            let progress = min(elapsed / self.morphDuration, 1.0)
            
            // Use ease-in-out curve for smoother morphing
            let easedProgress = self.easeInOutCubic(progress)
            
            self.morphPosition = startPosition + (positionDelta * easedProgress)
            
            if progress >= 1.0 {
                self.stopMorph()
                self.morphPosition = targetPosition
            }
        }
    }
    
    /// Stop the current morph
    func stopMorph() {
        morphTimer?.invalidate()
        morphTimer = nil
        isAutoMorphing = false
        startTime = nil
    }
    
    /// Manually update morph position and send CC messages
    func setMorphPosition(_ position: Double, sendCC: Bool = true) {
        morphPosition = max(0.0, min(1.0, position))
        
        if sendCC && !isAutoMorphing {
            updateMorphedValues()
        }
    }
    
    /// Swap source and destination programs
    func swapPrograms() {
        swap(&sourceProgram, &destinationProgram)
        morphPosition = 1.0 - morphPosition
        updateMorphedValues()
    }
    
    /// Reset to source program
    func resetToSource() {
        stopMorph()
        morphPosition = 0.0
        updateMorphedValues()
    }
    
    /// Jump to destination program
    func jumpToDestination() {
        stopMorph()
        morphPosition = 1.0
        updateMorphedValues()
    }
    
    // MARK: - Private Methods
    
    private func updateMorphedValues() {
        let sourceProps = sourceProgram.allParameters
        let destProps = destinationProgram.allParameters
        
        guard sourceProps.count == destProps.count else {
            debugPrint(icon: "⚠️", message: "Parameter count mismatch between programs")
            return
        }
        
        for (sourceParam, destParam) in zip(sourceProps, destProps) {
            // Only morph parameters that use CC and have numeric values
            guard sourceParam.type == destParam.type,
                  !sourceParam.isModSource,
                  sourceParam.containedParameter == nil else {
                continue
            }
            
            let morphedValue = interpolate(
                from: sourceParam.value,
                to: destParam.value,
                position: morphPosition
            )
            
            if sendCCMessages {
                sendCCUpdate(for: sourceParam.type, value: morphedValue)
            }
        }
    }
    
    private func interpolate(from: UInt8, to: UInt8, position: Double) -> UInt8 {
        let fromDouble = Double(from)
        let toDouble = Double(to)
        let result = fromDouble + (toDouble - fromDouble) * position
        return UInt8(max(0, min(127, result.rounded())))
    }
    
    private func sendCCUpdate(for type: MiniWorksParameter, value: UInt8) {
        // Post notification that parameter was updated
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
    
    // Ease-in-out cubic function for smooth acceleration/deceleration
    private func easeInOutCubic(_ t: Double) -> Double {
        if t < 0.5 {
            return 4 * t * t * t
        } else {
            let f = (2 * t - 2)
            return 1 + f * f * f / 2
        }
    }
}

// MARK: - MiniWorksProgram Extension

extension MiniWorksProgram {
    /// Returns all morphable parameters in the correct order
    var allParameters: [ProgramParameter] {
        [
            vcfEnvelopeAttack, vcfEnvelopeDecay, vcfEnvelopeSustain, vcfEnvelopeRelease,
            vcaEnvelopeAttack, vcaEnvelopeDecay, vcaEnvelopeSustain, vcaEnvelopeRelease,
            vcfEnvelopeCutoffAmount, vcaEnvelopeVolumeAmount,
            lfoSpeed, lfoSpeedModulationAmount,
            cutoffModulationAmount, resonanceModulationAmount,
            volumeModulationAmount, panningModulationAmount,
            cutoff, resonance, volume, panning,
            gateTime
            // Note: Excluding mod sources, trigger source/mode as they don't morph well
        ]
    }
}
