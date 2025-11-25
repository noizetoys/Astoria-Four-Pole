//
//  GlobalSettingsCodable.swift
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
