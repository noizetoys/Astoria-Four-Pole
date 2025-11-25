//
//  DeviceProfileWrapper.swift
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


