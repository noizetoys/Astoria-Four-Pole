//
//  MiniworksFileManager+Codable.swift
//  Astoria Filter Editor
//
//  Created by Assistant on 11/25/25.
//

import Foundation
import SwiftUI

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

// MARK: - Device Profile Wrapper

/**
 Codable wrapper for `MiniworksDeviceProfile`.
 
 ## Version History
 - v1.0: Initial format with programs and global settings
 
 ## Storage Format
 ```json
 {
   "version": "1.0",
   "savedAt": "2025-11-25T10:30:00Z",
   "programs": [...],
   "globalSettings": {...}
 }
 ```
 */
struct DeviceProfileWrapper: Codable {
    /// Format version for future compatibility
    let version: String
    
    /// Timestamp when profile was saved
    let savedAt: Date
    
    /// User programs (1-20)
    let programs: [ProgramCodable]
    
    /// Global device settings
    let globalSettings: GlobalSettingsCodable
    
    /// Optional metadata
    let profileName: String?
    let notes: String?
    
    // MARK: - Lifecycle
    
    init(profile: MiniworksDeviceProfile, name: String? = nil, notes: String? = nil) {
        self.version = "1.0"
        self.savedAt = Date()
        self.programs = profile.programs.map { ProgramCodable(program: $0) }
        self.globalSettings = GlobalSettingsCodable(globals: profile.globalSetup)
        self.profileName = name
        self.notes = notes
    }
    
    // MARK: - Conversion
    
    /**
     Converts the wrapper back to a domain model.
     
     - Returns: Fully initialized `MiniworksDeviceProfile`
     */
    func toDeviceProfile() -> MiniworksDeviceProfile {
        let programs = self.programs.map { $0.toProgram() }
        let globals = globalSettings.toGlobalData()
        
        return MiniworksDeviceProfile(
            id: savedAt,
            programs: programs,
            globals: globals
        )
    }
}

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

// MARK: - Program Tag Codable

/**
 Serializable representation of a program tag.
 
 Colors are stored as hex strings for readability and ease of editing.
 */
struct ProgramTagCodable: Codable {
    let title: String
    let backgroundColorHex: String
    let textColorHex: String
    
    init(tag: ProgramTag) {
        self.title = tag.title
        self.backgroundColorHex = tag.backgroundColor.toHex()
        self.textColorHex = tag.textColor.toHex()
    }
    
    func toTag() -> ProgramTag {
        ProgramTag(
            title: title,
            backgroundColor: Color(hex: backgroundColorHex),
            textColor: Color(hex: textColorHex)
        )
    }
}

// MARK: - Global Settings Codable

/**
 Serializable representation of global device settings.
 */
struct GlobalSettingsCodable: Codable {
    let midiChannel: UInt8
    let midiControl: UInt8
    let deviceID: UInt8
    let startUpProgramID: UInt8
    let noteNumber: UInt8
    let knobMode: UInt8
    
    init(globals: MiniWorksGlobalData) {
        self.midiChannel = globals.midiChannel
        self.midiControl = globals.midiControl.rawValue
        self.deviceID = globals.deviceID
        self.startUpProgramID = globals.startUpProgramID
        self.noteNumber = globals.noteNumber
        self.knobMode = globals.knobMode.rawValue
    }
    
    func toGlobalData() -> MiniWorksGlobalData {
        let globals = MiniWorksGlobalData()
        globals.midiChannel = midiChannel
        globals.midiControl = GlobalMIDIControl(rawValue: midiControl) ?? .off
        globals.deviceID = deviceID
        globals.startUpProgramID = startUpProgramID
        globals.noteNumber = noteNumber
        globals.knobMode = GlobalKnobMode(rawValue: knobMode) ?? .relative
        return globals
    }
}

// MARK: - Color Extensions

/**
 Extensions to support color serialization to/from hex strings.
 */
extension Color {
    /// Converts a Color to a hex string (e.g., "#FF5733")
    func toHex() -> String {
        #if os(macOS)
        guard let nsColor = NSColor(self).usingColorSpace(.sRGB) else {
            return "#000000"
        }
        
        let red = Int(nsColor.redComponent * 255)
        let green = Int(nsColor.greenComponent * 255)
        let blue = Int(nsColor.blueComponent * 255)
        
        return String(format: "#%02X%02X%02X", red, green, blue)
        #else
        // For iOS if needed
        return "#000000"
        #endif
    }
    
    /// Creates a Color from a hex string (e.g., "#FF5733")
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        
        Scanner(string: hex).scanHexInt64(&int)
        
        let r, g, b: Double
        switch hex.count {
        case 6: // RGB (24-bit)
            r = Double((int >> 16) & 0xFF) / 255.0
            g = Double((int >> 8) & 0xFF) / 255.0
            b = Double(int & 0xFF) / 255.0
        default:
            r = 0
            g = 0
            b = 0
        }
        
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Migration Support

/**
 Handles migration between different file format versions.
 
 ## Usage
 
 ```swift
 let migrator = FileFormatMigrator()
 let migratedData = try migrator.migrate(data, from: "1.0", to: "2.0")
 ```
 */
struct FileFormatMigrator {
    /**
     Migrates data from one version to another.
     
     - Parameters:
        - data: Raw JSON data
        - fromVersion: Source version string
        - toVersion: Target version string
     - Returns: Migrated JSON data
     - Throws: Error if migration fails
     
     ## Customization Point
     Add new migration paths here when you update your file format.
     */
    func migrate(_ data: Data, from fromVersion: String, to toVersion: String) throws -> Data {
        // Currently only one version exists
        // Add migration logic here when introducing v2.0
        
        if fromVersion == "1.0" && toVersion == "1.0" {
            return data
        }
        
        // Example for future versions:
        // if fromVersion == "1.0" && toVersion == "2.0" {
        //     return try migrateV1toV2(data)
        // }
        
        throw MiniworksFileError.invalidJSON
    }
    
    // Example migration method:
    // private func migrateV1toV2(_ data: Data) throws -> Data {
    //     // Decode v1 format
    //     // Transform to v2 format
    //     // Re-encode as v2
    // }
}
