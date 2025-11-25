//
//  ProgramWrapper.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/25/25.
//
import Foundation


/**
 # Codable Wrappers for File Persistence
 
 This file provides `Codable` wrappers for the main data types that need to be
 persisted to JSON. Since your original classes use `@Observable` and contain
 complex nested structures, these wrappers provide a clean serialization layer.
 
 ## Architecture
 
 The wrapper pattern:
 1. **Wrapper Structs**: Simple, flat structures that conform to `Codable`
 2. **Conversion Methods**: Transform between your domain models and wrappers
 3. **Type Safety**: Preserve all Swift types through the serialization process
 
 ## Why Wrappers?
 
 - `@Observable` classes don't automatically conform to `Codable`
 - Provides version compatibility (can add fields without breaking old files)
 - Separates persistence concerns from domain logic
 - Allows for data migration when formats change
 
 ## Customization
 
 To add new fields to persist:
 1. Add the property to the appropriate wrapper struct
 2. Update the initializer to include the new field
 3. Update the conversion method (`toDeviceProfile()` or `toProgram()`)
 4. Increment the `version` number if changing the format
 */



// MARK: - Program Wrapper

/**
 Codable wrapper for `MiniWorksProgram`.
 
 ## Storage Format
 Programs are stored with all parameters as individual values rather than
 as nested `ProgramParameter` objects. This makes the JSON more readable
 and easier to edit manually if needed.
 */
struct ProgramWrapper: Codable {
    /// Format version for future compatibility
    let version: String
    
    /// Timestamp when program was saved
    let savedAt: Date
    
    /// The actual program data
    let program: ProgramCodable
    
    // MARK: - Lifecycle
    
    init(program: MiniWorksProgram) {
        self.version = "1.0"
        self.savedAt = Date()
        self.program = ProgramCodable(program: program)
    }
    
    // MARK: - Conversion
    
    func toProgram() -> MiniWorksProgram {
        program.toProgram()
    }
}

// MARK: - Program Codable

/**
 Serializable representation of a `MiniWorksProgram`.
 
 All parameter values are stored as raw UInt8 values for simplicity.
 Enum-based parameters (like modulation sources) are stored as their raw values.
 */
struct ProgramCodable: Codable {
    // Metadata
    let programNumber: UInt8
    let programName: String
    let isReadOnly: Bool
    let tags: [ProgramTagCodable]
    
    // VCF Envelope
    let vcfEnvelopeAttack: UInt8
    let vcfEnvelopeDecay: UInt8
    let vcfEnvelopeSustain: UInt8
    let vcfEnvelopeRelease: UInt8
    let vcfEnvelopeCutoffAmount: UInt8
    
    // Cutoff
    let cutoff: UInt8
    let cutoffModulationAmount: UInt8
    let cutoffModulationSource: UInt8
    
    // Resonance
    let resonance: UInt8
    let resonanceModulationAmount: UInt8
    let resonanceModulationSource: UInt8
    
    // VCA Envelope
    let vcaEnvelopeAttack: UInt8
    let vcaEnvelopeDecay: UInt8
    let vcaEnvelopeSustain: UInt8
    let vcaEnvelopeRelease: UInt8
    let vcaEnvelopeVolumeAmount: UInt8
    
    // Volume
    let volume: UInt8
    let volumeModulationAmount: UInt8
    let volumeModulationSource: UInt8
    
    // LFO
    let lfoSpeed: UInt8
    let lfoSpeedModulationAmount: UInt8
    let lfoShape: UInt8
    let lfoSpeedModulationSource: UInt8
    
    // Panning
    let panning: UInt8
    let panningModulationAmount: UInt8
    let panningModulationSource: UInt8
    
    // Trigger
    let gateTime: UInt8
    let triggerSource: UInt8
    let triggerMode: UInt8
    
    // MARK: - Lifecycle
    
    init(program: MiniWorksProgram) {
        self.programNumber = program.programNumber
        self.programName = program.programName
        self.isReadOnly = program.isReadOnly
        self.tags = program.tags.map { ProgramTagCodable(tag: $0) }
        
        // VCF Envelope
        self.vcfEnvelopeAttack = program.vcfEnvelopeAttack.value
        self.vcfEnvelopeDecay = program.vcfEnvelopeDecay.value
        self.vcfEnvelopeSustain = program.vcfEnvelopeSustain.value
        self.vcfEnvelopeRelease = program.vcfEnvelopeRelease.value
        self.vcfEnvelopeCutoffAmount = program.vcfEnvelopeCutoffAmount.value
        
        // Cutoff
        self.cutoff = program.cutoff.value
        self.cutoffModulationAmount = program.cutoffModulationAmount.value
        self.cutoffModulationSource = program.cutoffModulationSource.value
        
        // Resonance
        self.resonance = program.resonance.value
        self.resonanceModulationAmount = program.resonanceModulationAmount.value
        self.resonanceModulationSource = program.resonanceModulationSource.value
        
        // VCA Envelope
        self.vcaEnvelopeAttack = program.vcaEnvelopeAttack.value
        self.vcaEnvelopeDecay = program.vcaEnvelopeDecay.value
        self.vcaEnvelopeSustain = program.vcaEnvelopeSustain.value
        self.vcaEnvelopeRelease = program.vcaEnvelopeRelease.value
        self.vcaEnvelopeVolumeAmount = program.vcaEnvelopeVolumeAmount.value
        
        // Volume
        self.volume = program.volume.value
        self.volumeModulationAmount = program.volumeModulationAmount.value
        self.volumeModulationSource = program.volumeModulationSource.value
        
        // LFO
        self.lfoSpeed = program.lfoSpeed.value
        self.lfoSpeedModulationAmount = program.lfoSpeedModulationAmount.value
        self.lfoShape = program.lfoShape.value
        self.lfoSpeedModulationSource = program.lfoSpeedModulationSource.value
        
        // Panning
        self.panning = program.panning.value
        self.panningModulationAmount = program.panningModulationAmount.value
        self.panningModulationSource = program.panningModulationSource.value
        
        // Trigger
        self.gateTime = program.gateTime.value
        self.triggerSource = program.triggerSource.value
        self.triggerMode = program.triggerMode.value
    }
    
    // MARK: - Conversion
    
    /**
     Converts the codable representation back to a full `MiniWorksProgram`.
     
     - Returns: Fully initialized program with all parameters
     */
    func toProgram() -> MiniWorksProgram {
        let program = MiniWorksProgram()
        
        // Metadata
        program.programNumber = programNumber
        program.programName = programName
        program.tags = tags.map { $0.toTag() }
        
        // VCF Envelope
        program.vcfEnvelopeAttack.setValue(vcfEnvelopeAttack)
        program.vcfEnvelopeDecay.setValue(vcfEnvelopeDecay)
        program.vcfEnvelopeSustain.setValue(vcfEnvelopeSustain)
        program.vcfEnvelopeRelease.setValue(vcfEnvelopeRelease)
        program.vcfEnvelopeCutoffAmount.setValue(vcfEnvelopeCutoffAmount)
        
        // Cutoff
        program.cutoff.setValue(cutoff)
        program.cutoffModulationAmount.setValue(cutoffModulationAmount)
        program.cutoffModulationSource.setValue(cutoffModulationSource)
        
        // Resonance
        program.resonance.setValue(resonance)
        program.resonanceModulationAmount.setValue(resonanceModulationAmount)
        program.resonanceModulationSource.setValue(resonanceModulationSource)
        
        // VCA Envelope
        program.vcaEnvelopeAttack.setValue(vcaEnvelopeAttack)
        program.vcaEnvelopeDecay.setValue(vcaEnvelopeDecay)
        program.vcaEnvelopeSustain.setValue(vcaEnvelopeSustain)
        program.vcaEnvelopeRelease.setValue(vcaEnvelopeRelease)
        program.vcaEnvelopeVolumeAmount.setValue(vcaEnvelopeVolumeAmount)
        
        // Volume
        program.volume.setValue(volume)
        program.volumeModulationAmount.setValue(volumeModulationAmount)
        program.volumeModulationSource.setValue(volumeModulationSource)
        
        // LFO
        program.lfoSpeed.setValue(lfoSpeed)
        program.lfoSpeedModulationAmount.setValue(lfoSpeedModulationAmount)
        program.lfoShape.setValue(lfoShape)
        program.lfoSpeedModulationSource.setValue(lfoSpeedModulationSource)
        
        // Panning
        program.panning.setValue(panning)
        program.panningModulationAmount.setValue(panningModulationAmount)
        program.panningModulationSource.setValue(panningModulationSource)
        
        // Trigger
        program.gateTime.setValue(gateTime)
        program.triggerSource.setValue(triggerSource)
        program.triggerMode.setValue(triggerMode)
        
        return program
    }
}
