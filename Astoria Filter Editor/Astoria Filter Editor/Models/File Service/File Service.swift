//
//  WaldorfEditorFileManager.swift
//
//  This file contains a self-contained "file manager" module for a
//  Waldorf Miniworks (or similar) Editor/Librarian app.
//
//  It provides:
//
//  1. Data models for:
//      - WaldorfProgram (single patch / program)
//      - WaldorfGlobalSettings (device-wide/global parameters)
//      - WaldorfDeviceConfiguration (20 programs + globals)
//
//  2. A pure Swift "WaldorfFileManager" type that:
//      - Saves/loads individual programs as JSON files
//      - Saves/loads full device configurations as JSON files
//      - Organizes files under Documents/Programs and Documents/Configurations
//
//  3. A SwiftUI "WaldorfFileManagerView" that:
//      - Shows a UI for browsing, saving, loading, and deleting program/config files
//      - Is completely decoupled from your SysEx/MIDI device code
//      - Talks back to the host editor via closures:
//
//          provideCurrentProgram          -> used when saving a single program
//          provideCurrentConfiguration    -> used when saving a full config
//          applyLoadedProgram             -> called when user loads a program
//          applyLoadedConfiguration       -> called when user loads a config
//
//  HOW TO INTEGRATE
//  ----------------
//  In your main editor:
//
//  - Use your real program/config models or start from these and adapt.
//  - Keep the actual SysEx send/receive logic in your editor / MIDI manager.
//  - Wire those to the "applyLoaded..." closures so that when the user
//    loads something from disk, your editor updates and optionally pushes
//    changes to the physical device.
//
//  IMPORTANT DESIGN NOTES
//  ----------------------
//  - File format is JSON for readability, easy debugging, and forward-
//    compatibility. If you later want to support SysEx exports/imports,
//    you can:
//
//      * Add methods that convert between WaldorfProgram/WaldorfDeviceConfiguration
//        and raw [UInt8] SysEx dumps.
//
//      * Add separate "Import from SysEx" / "Export as SysEx" actions,
//        without changing this file manager UI.
//
//  - The module does *not* know anything about MIDI, CoreMIDI, or SysEx.
//    This keeps it reusable and simple to test independently.
//


import SwiftUI
import Foundation




// MARK: - WaldorfFileManager (Core File I/O)

/// Centralized file management for the Waldorf Editor/Librarian.
///
/// Responsibilities:
/// -----------------
/// - Provide file paths for:
///     * Individual program files
///     * Full device configurations
/// - Read/write JSON data using `Codable` models
/// - Enforce invariants where appropriate (e.g. 20 programs in a config)
///
/// This type is intentionally decoupled from:
/// - Any SwiftUI UI
/// - Any MIDI/SysEx implementation
///
/// That makes it easy to:
/// - Test in isolation
/// - Swap the UI without touching storage
/// - Reuse in command-line tools or other apps
struct WaldorfFileManager {
    
    /// Shared singleton instance for convenience.
    /// You can also initialize your own copy if you prefer.
    static let shared = WaldorfFileManager()
    
    /// Folder names under your app's Documents directory.
    private let programsFolderName = "Programs"
    private let configurationsFolderName = "Configurations"
    
    // Private init to enforce singleton usage.
    private init() {}
    
    // MARK: Paths
    
    /// Base URL for the app's Documents directory in the user's container.
    ///
    /// On iOS/macOS sandboxed apps, this is typically:
    ///   <App Sandbox>/Documents/
    private var baseURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    /// Subdirectory for storing individual program files.
    private var programsDirectory: URL {
        baseURL.appendingPathComponent(programsFolderName, isDirectory: true)
    }
    
    /// Subdirectory for storing complete device configurations.
    private var configurationsDirectory: URL {
        baseURL.appendingPathComponent(configurationsFolderName, isDirectory: true)
    }
    
    /// Ensure that a folder exists on disk, creating it if needed.
    private func ensureFolderExists(_ url: URL) throws {
        let fm = FileManager.default
        if !fm.fileExists(atPath: url.path) {
            try fm.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
    
    // MARK: - Encoding / Decoding Helpers
    
    /// JSONEncoder configured for pretty-printed, stable output.
    ///
    /// Sorting keys and pretty-printing is *optional* but very
    /// convenient if you want to open the files in a text editor
    /// and inspect/debug them.
    private var encoder: JSONEncoder {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        return enc
    }
    
    /// Basic JSONDecoder.
    private var decoder: JSONDecoder {
        JSONDecoder()
    }
    
    // MARK: - Program File Operations
    
    /// Returns all program files (URLs) in the Programs folder.
    ///
    /// This gives you paths to JSON files only, sorted by filename.
    func listProgramFiles() throws -> [URL] {
        try ensureFolderExists(programsDirectory)
        let fm = FileManager.default
        let contents = try fm.contentsOfDirectory(at: programsDirectory, includingPropertiesForKeys: nil)
        
        return contents
            .filter { $0.pathExtension.lowercased() == "json" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }
    
    /// Loads *all* programs by decoding them from their JSON files.
    ///
    /// Note:
    /// - If any single file fails to decode, this implementation
    ///   currently *skips* that file (using `try?`) rather than
    ///   failing the entire operation. Adjust as desired.
    func loadAllPrograms() throws -> [WaldorfProgram] {
        try listProgramFiles().compactMap { url in
            try? loadProgram(from: url)
        }
    }
    
    /// Generate a default filename for a program.
    ///
    /// Example:
    ///   "P01 - Warm Filter Sweep.json"
    ///
    /// This makes files human-friendly and nicely sortable.
    private func filename(for program: WaldorfProgram) -> String {
        let number = String(format: "%02d", program.programNumber + 1)
        let safeName = program.name.replacingOccurrences(of: "/", with: "-")
        return "P\(number) - \(safeName).json"
    }
    
    /// Save a single program as a JSON file in the Programs folder.
    ///
    /// - Returns: The URL of the file that was written.
    ///
    /// How this is typically used:
    /// ---------------------------
    /// - Your editor holds a `WaldorfProgram` as "current".
    /// - User taps "Save" in the UI.
    /// - You call `saveProgram(currentProgram)`.
    /// - You might then update a list of programs in the UI.
    @discardableResult
    func saveProgram(_ program: WaldorfProgram) throws -> URL {
        try ensureFolderExists(programsDirectory)
        
        let url = programsDirectory.appendingPathComponent(filename(for: program))
        let data = try encoder.encode(program)
        
        do {
            // `.atomic` ensures the file is written safely in one go.
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            throw WaldorfFileError.encodingFailed(url)
        }
    }
    
    /// Load a program from a specific file URL.
    ///
    /// - Parameter url: Location of a JSON program file.
    /// - Throws: `WaldorfFileError.fileNotFound` or `WaldorfFileError.decodingFailed`.
    func loadProgram(from url: URL) throws -> WaldorfProgram {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw WaldorfFileError.fileNotFound(url)
        }
        let data = try Data(contentsOf: url)
        do {
            return try decoder.decode(WaldorfProgram.self, from: data)
        } catch {
            throw WaldorfFileError.decodingFailed(url)
        }
    }
    
    /// Delete a specific program file.
    ///
    /// This does not touch any in-memory state. You should update your
    /// UI or editor state after calling this if needed.
    func deleteProgram(at url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.removeItem(at: url)
    }
    
    // MARK: - Device Configuration File Operations
    
    /// Returns all configuration files (URLs) in the Configurations folder.
    ///
    /// These are JSON files each representing:
    /// - 20 programs
    /// - Global settings
    /// - A user-friendly configuration name
    func listConfigurationFiles() throws -> [URL] {
        try ensureFolderExists(configurationsDirectory)
        let fm = FileManager.default
        let contents = try fm.contentsOfDirectory(at: configurationsDirectory, includingPropertiesForKeys: nil)
        
        return contents
            .filter { $0.pathExtension.lowercased() == "json" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }
    
    /// Loads all device configurations.
    ///
    /// Similar strategy as `loadAllPrograms()`:
    /// - Skips entries that fail to decode, rather than fail-hard.
    func loadAllConfigurations() throws -> [WaldorfDeviceConfiguration] {
        try listConfigurationFiles().compactMap { url in
            try? loadConfiguration(from: url)
        }
    }
    
    /// Generate a filename for a full device configuration.
    ///
    /// We embed a timestamp for convenience, then the user-friendly name.
    ///
    /// Example:
    ///   "2025-11-18 1230 - Studio Defaults.json"
    private func filename(for configuration: WaldorfDeviceConfiguration) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HHmm"
        let dateStamp = dateFormatter.string(from: Date())
        let safeName = configuration.name.replacingOccurrences(of: "/", with: "-")
        return "\(dateStamp) - \(safeName).json"
    }
    
    /// Save a full device configuration as JSON.
    ///
    /// - Ensures that there are exactly 20 programs.
    /// - Writes to the Configurations folder.
    @discardableResult
    func saveConfiguration(_ configuration: WaldorfDeviceConfiguration) throws -> URL {
        guard configuration.programs.count == 20 else {
            throw WaldorfFileError.invalidProgramCount(expected: 20, actual: configuration.programs.count)
        }
        
        try ensureFolderExists(configurationsDirectory)
        
        let url = configurationsDirectory.appendingPathComponent(filename(for: configuration))
        let data = try encoder.encode(configuration)
        
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            throw WaldorfFileError.encodingFailed(url)
        }
    }
    
    /// Load a full device configuration from disk.
    ///
    /// - Validates that the loaded configuration has exactly 20 programs.
    /// - Throws a specific error if the file is missing, decoding fails,
    ///   or the program count is incorrect.
    func loadConfiguration(from url: URL) throws -> WaldorfDeviceConfiguration {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw WaldorfFileError.fileNotFound(url)
        }
        let data = try Data(contentsOf: url)
        do {
            let config = try decoder.decode(WaldorfDeviceConfiguration.self, from: data)
            guard config.programs.count == 20 else {
                throw WaldorfFileError.invalidProgramCount(expected: 20, actual: config.programs.count)
            }
            return config
        } catch let error as WaldorfFileError {
            throw error
        } catch {
            throw WaldorfFileError.decodingFailed(url)
        }
    }
    
    /// Delete a configuration file from disk.
    func deleteConfiguration(at url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.removeItem(at: url)
    }
}


// MARK: - Example Integration (Preview)

// This preview shows how to embed the file manager in a larger UI.
// In your real app, replace the dummy state with your actual editor
// program/config structs and wire the closures to your MIDI/SysEx logic.

struct WaldorfEditorRootView: View {
    @State private var currentProgram: WaldorfProgram = .init(
        programNumber: 0,
        name: "Init",
        parameters: ["cutoff": 0.5, "resonance": 0.2]
    )
    
    @State private var currentConfiguration: WaldorfDeviceConfiguration =
        .empty(named: "Working Set")
    
    var body: some View {
        TabView {
            // Placeholder for your real editor UI.
            VStack(spacing: 16) {
                Text("Waldorf Editor")
                    .font(.title)
                Text("This is where your main editor UI lives.")
                    .foregroundStyle(.secondary)
                Text("Current Program: \(currentProgram.name)")
                Text("Current Config: \(currentConfiguration.name)")
            }
            .padding()
            .tabItem {
                Label("Editor", systemImage: "slider.horizontal.3")
            }
            
            // File Manager tab.
            WaldorfFileManagerView(
                // When saving a program, we just pass back `currentProgram`.
                provideCurrentProgram: {
                    currentProgram
                },
                // When saving a configuration, pass back `currentConfiguration`.
                provideCurrentConfiguration: {
                    currentConfiguration
                },
                // When a program is loaded from disk:
                applyLoadedProgram: { loaded in
                    currentProgram = loaded
                    // TODO: Optionally push to device via SysEx / CC from here,
                    // or from a ViewModel observing `currentProgram`.
                },
                // When a configuration is loaded from disk:
                applyLoadedConfiguration: { loadedConfig in
                    currentConfiguration = loadedConfig
                    // TODO: Optionally push all 20 programs + globals
                    // to the device from here or from a ViewModel observing
                    // `currentConfiguration`.
                }
            )
            .tabItem {
                Label("Files", systemImage: "folder")
            }
        }
    }
}


struct WaldorfEditorRootView_Previews: PreviewProvider {
    static var previews: some View {
        WaldorfEditorRootView()
    }
}
