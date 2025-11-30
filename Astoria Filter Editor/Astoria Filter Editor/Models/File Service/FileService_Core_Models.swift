//
//  FileService_Core_Models.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/25/25.
//


// MARK: - Core Models

/// Represents a single Waldorf Miniworks program / patch.
///
/// This is intentionally simple and generic. In a real app, you would
/// likely replace the `parameters` dictionary with a strongly typed
/// struct that mirrors the actual filter parameters (cutoff, resonance,
/// envelope amount, etc.).
///
/// Why `Codable`?
/// --------------
/// We want to be able to encode/decode this type directly to JSON (and
/// potentially other formats later), so we conform to `Codable`.
///
/// Why `Identifiable` & `Hashable`?
/// --------------------------------
/// - `Identifiable`: works nicely with SwiftUI List/ForEach.
/// - `Hashable`: useful if you need to store these in Sets or
///   use them as dictionary keys.
struct WaldorfProgram: Identifiable, Codable, Hashable {
    /// Program number on the physical device (0–19 for 20 programs).
    /// This is the number that your SysEx or CC code might use when
    /// addressing a specific patch slot on the hardware.
    var programNumber: Int
    
    /// Human-readable name, e.g., "Warm Sweep", "Aggressive Bass", etc.
    var name: String
    
    /// Container for parameter values.
    ///
    /// In a real implementation:
    /// - Replace this with a more structured type:
    ///   `struct WaldorfParameters { ... }`.
    /// - That structured type should also be `Codable`.
    ///
    /// Here we use `[String: Double]` as a stand-in so this file
    /// compiles and demonstrates how the file manager works.
    var parameters: [String: Double]
    
    /// Stable identity for SwiftUI List/ForEach.
    ///
    /// Note: we combine a prefix with the programNumber so you can
    /// have different `WaldorfProgram` values with the same
    /// programNumber but distinct identities if needed.
    var id: String { "program-\(programNumber)" }
}

/// Global (device-wide) settings that are not tied to a single patch.
/// Examples might include:
/// - MIDI channel
/// - Input/output gain
/// - Global bypass
///
/// In a real implementation, you would:
/// - Map these fields to the actual global SysEx/global CC parameters.
/// - Extend the struct accordingly.
struct WaldorfGlobalSettings: Codable, Hashable {
    var midiChannel: Int
    var inputGain: Double
    var outputLevel: Double
    var bypassOnStartup: Bool
    
    /// A reasonable default for new configurations.
    static let `default` = WaldorfGlobalSettings(
        midiChannel: 1,
        inputGain: 0.5,
        outputLevel: 0.8,
        bypassOnStartup: false
    )
}

/// Represents a *full device configuration*:
/// - A human-friendly name
/// - The 20 programs on the device
/// - Global settings
///
/// This is what you would save to capture the entire state of a
/// physical device: all 20 program slots + all global parameters.
struct WaldorfDeviceConfiguration: Identifiable, Codable, Hashable {
    /// Friendly name: "Studio Defaults", "Live Set A", etc.
    var name: String
    
    /// Exactly 20 programs for the Waldorf Miniworks.
    /// We will enforce this count in `WaldorfFileManager.saveConfiguration`.
    var programs: [WaldorfProgram]
    
    /// Global properties.
    var globals: WaldorfGlobalSettings
    
    var id: String { "config-\(name)" }
    
    /// Convenience for creating a new, mostly-empty configuration.
    ///
    /// This is helpful when the user first launches the app and you
    /// want to present an editable "working set" before they save to disk.
    static func empty(named name: String = "Untitled Configuration") -> WaldorfDeviceConfiguration {
        let programs = (0..<20).map { index in
            WaldorfProgram(
                programNumber: index,
                name: "Program \(index + 1)",
                parameters: [:]
            )
        }
        return WaldorfDeviceConfiguration(name: name, programs: programs, globals: .default)
    }
}
