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

