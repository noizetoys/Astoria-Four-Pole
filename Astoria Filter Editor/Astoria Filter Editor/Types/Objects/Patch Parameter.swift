//
//  Patch Parameter.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/15/25.
//

import Foundation
    /// A struct representing a single patch parameter with all its associated metadata.
    /// The core value is a 7-bit (0-127) UInt8.
struct Parameter<Value: Numeric & Comparable> {
    
        // MARK: - Core Value
    
        /// The actual, underlying 7-bit value (0-127) used for MIDI and storage.
    private var _rawValue: UInt8 = 0
    
        /// Public accessor for the raw 7-bit value. Writes are clamped to 0-127.
    var rawValue: UInt8 {
        get {
            return _rawValue
        }
        set {
                // Enforce the 7-bit MIDI range constraint (0-127)
            _rawValue = min(newValue, 127)
        }
    }
    
        // MARK: - Metadata
    
        /// A human-readable identifier for UI display.
    let name: String
    
        /// The MIDI Continuous Controller (CC) number (0-127).
    let midiCC: UInt8
    
        /// The bit offset within a byte, if this parameter is part of a flag set (Optional).
    let bitPosition: UInt8?
    
        /// A KeyPath that allows generic access to this parameter instance within a PatchConfiguration.
        /// This is typically provided externally during setup.
        // NOTE: Storing the KeyPath here isn't standard, but is listed for completeness
        // if you implement a custom system to find the KeyPath by instance.
        // var keyPath: WritableKeyPath<PatchConfiguration, Parameter<Value>>? = nil
    
        // MARK: - UI & Mapping
    
        /// The abstract minimum value for UI display (e.g., -64, 0.0).
    let uiMin: Value
    
        /// The abstract maximum value for UI display (e.g., 63, 1.0).
    let uiMax: Value
    
        /// The value mapped to the UI range (e.g., -64 to 63). This is the primary value
        /// used by user interfaces.
    var mappedValue: Value {
        get {
                // Map rawValue (0...127) to the (uiMin...uiMax) range.
            let rawRange: Double = 127.0
            let mapRange = Double(uiMax as! Double) - Double(uiMin as! Double)
            let coreValueDouble = Double(_rawValue)
            
                // Mapped = uiMin + (coreValue * mapRange) / rawRange
            let mappedDouble = Double(uiMin as! Double) + (coreValueDouble * mapRange) / rawRange
            
                // Return value cast back to the generic type
            return mappedDouble as! Value
        }
        set {
                // Map the new mappedValue back to the raw 0-127 range.
            let rawRange: Double = 127.0
            let mapRange = Double(uiMax as! Double) - Double(uiMin as! Double)
            
                // Core = (newValue - uiMin) * rawRange / mapRange
            let valueDouble = Double(newValue as! Double)
            let uiMinDouble = Double(uiMin as! Double)
            
            var coreDouble = (valueDouble - uiMinDouble) * rawRange / mapRange
            
                // Clamp the resulting core value to the 0-127 range
            coreDouble = max(0.0, min(127.0, coreDouble.rounded()))
            
            self._rawValue = UInt8(coreDouble)
        }
    }
    
        // MARK: - Initialization
    
    init(name: String,
         midiCC: UInt8,
         bitPosition: UInt8? = nil,
         initialValue: UInt8,
         uiMin: Value,
         uiMax: Value) {
        self.name = name
        self.midiCC = midiCC
        self.bitPosition = bitPosition
        self.uiMin = uiMin
        self.uiMax = uiMax
            // Use the clamped setter for initial assignment
        self.rawValue = initialValue
    }
}
