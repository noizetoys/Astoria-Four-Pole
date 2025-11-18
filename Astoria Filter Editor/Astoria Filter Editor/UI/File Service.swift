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

// MARK: - Errors

/// Errors specific to file operations in this module.
enum WaldorfFileError: Error, LocalizedError {
    /// The device is expected to hold exactly 20 programs, so we
    /// treat any mismatch as an error when loading/saving complete configs.
    case invalidProgramCount(expected: Int, actual: Int)
    
    /// The file we tried to read was not found on disk.
    case fileNotFound(URL)
    
    /// We could read the file, but decoding JSON into our models failed.
    case decodingFailed(URL)
    
    /// We could not encode JSON or write it to disk.
    case encodingFailed(URL)
    
    /// Human-readable descriptions are useful in SwiftUI Alerts.
    var errorDescription: String? {
        switch self {
            case let .invalidProgramCount(expected, actual):
                return "Expected \(expected) programs, found \(actual)."
            case let .fileNotFound(url):
                return "File not found at \(url.lastPathComponent)."
            case let .decodingFailed(url):
                return "Failed to decode \(url.lastPathComponent)."
            case let .encodingFailed(url):
                return "Failed to encode data for \(url.lastPathComponent)."
        }
    }
}

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

// MARK: - SwiftUI File Manager UI

/// High-level file manager UI for the Waldorf Editor Librarian.
///
/// Intent:
/// -------
/// This view is *only* responsible for:
/// - Presenting lists of saved programs & configurations
/// - Letting the user:
///     * Save the current program
///     * Save the current configuration
///     * Load an existing program/config
///     * Delete an existing program/config
///
/// It does *not*:
/// - Know how to talk to the hardware
/// - Know how to send SysEx or CC
/// - Know how your editor's internal state is structured
///
/// Instead, it uses closures:
///
/// - `provideCurrentProgram()`
///     - Called whenever the user taps "Save Program".
/// - `provideCurrentConfiguration()`
///     - Called whenever the user taps "Save Configuration".
/// - `applyLoadedProgram(loaded)`
///     - Called after a program has been loaded from disk.
///       Your implementation should:
///         * Update the editor's current program state
///         * Optionally push this program to the physical device
/// - `applyLoadedConfiguration(loaded)`
///     - Called after a full configuration has been loaded.
///       Your implementation should:
///         * Update the editor's current config
///         * Optionally push all 20 programs + globals to the device
struct WaldorfFileManagerView: View {
    
    // MARK: Dependencies from the host app
    
    /// Called when the user wants to save the current single program.
    let provideCurrentProgram: () -> WaldorfProgram
    
    /// Called when the user wants to save the current full device configuration.
    let provideCurrentConfiguration: () -> WaldorfDeviceConfiguration
    
    /// Called when the user selects and loads a program from disk.
    let applyLoadedProgram: (WaldorfProgram) -> Void
    
    /// Called when the user selects and loads a configuration from disk.
    let applyLoadedConfiguration: (WaldorfDeviceConfiguration) -> Void
    
    // MARK: UI State (internal to this view)
    
    /// In-memory mirror of program files in the "Programs" folder.
    @State private var programs: [ProgramEntry] = []
    
    /// In-memory mirror of configuration files in the "Configurations" folder.
    @State private var configurations: [ConfigurationEntry] = []
    
    /// Track which program entry is selected in the list.
    @State private var selectedProgramID: ProgramEntry.ID?
    
    /// Track which configuration entry is selected in the list.
    @State private var selectedConfigurationID: ConfigurationEntry.ID?
    
    /// Human-readable error message for Alerts.
    @State private var errorMessage: String?
    
    /// Whether the error alert is being displayed.
    @State private var isShowingErrorAlert = false
    
    /// Simple state to disable the refresh button while we're reloading.
    @State private var isRefreshing = false
    
    /// Which tab (Programs vs Configurations) is active.
    @State private var selectedTab: Tab = .programs
    
    /// Top-level segments in the UI.
    enum Tab: String, CaseIterable, Identifiable {
        case programs = "Programs"
        case configurations = "Configurations"
        
        var id: String { rawValue }
    }
    
    /// Internal type representing a single row in the "Programs" list.
    struct ProgramEntry: Identifiable, Hashable {
        let id = UUID()
        let url: URL
        let program: WaldorfProgram
    }
    
    /// Internal type representing a single row in the "Configurations" list.
    struct ConfigurationEntry: Identifiable, Hashable {
        let id = UUID()
        let url: URL
        let configuration: WaldorfDeviceConfiguration
    }
    
    /// Shared file manager used by this view.
    private let fileManager = WaldorfFileManager.shared
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack {
                // Top segmented control: Programs vs Configurations
                Picker("Type", selection: $selectedTab) {
                    ForEach(Tab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top)
                
                // Main content switches between the two lists.
                Group {
                    switch selectedTab {
                        case .programs:
                            programsList
                        case .configurations:
                            configurationsList
                    }
                }
                .animation(.default, value: selectedTab)
            }
            .navigationTitle("Waldorf File Manager")
            .toolbar {
                // Left toolbar: Refresh button
                ToolbarItemGroup(placement: .automatic) {
                    Button {
                        refresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isRefreshing)
                }
                
                // Right toolbar: Save button (changes behaviour per tab)
                ToolbarItemGroup(placement: .automatic) {
                    switch selectedTab {
                        case .programs:
                            Button {
                                saveCurrentProgram()
                            } label: {
                                Label("Save Program", systemImage: "square.and.arrow.down")
                            }
                        case .configurations:
                            Button {
                                saveCurrentConfiguration()
                            } label: {
                                Label("Save Configuration", systemImage: "square.and.arrow.down")
                            }
                    }
                }
            }
            // Load file lists when the view first appears.
            .onAppear(perform: refresh)
            // Basic error alert.
            .alert("File Error", isPresented: $isShowingErrorAlert, actions: {
                Button("OK", role: .cancel) { }
            }, message: {
                Text(errorMessage ?? "Unknown error")
            })
        }
    }
    
    // MARK: - Subviews
    
    /// List view for individual programs (Programs tab).
    private var programsList: some View {
        List(selection: $selectedProgramID) {
            ForEach(programs) { entry in
                Button {
                    loadProgram(entry)
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(entry.program.name)
                                .font(.headline)
                            Text("Program \(entry.program.programNumber + 1)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        // Show the underlying filename as a hint to the user.
                        Text(entry.url.lastPathComponent)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                // Context menu allows quick Load/Delete actions.
                .contextMenu {
                    Button("Load") {
                        loadProgram(entry)
                    }
                    Button(role: .destructive) {
                        deleteProgram(entry)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }
    
    /// List view for full device configurations (Configurations tab).
    private var configurationsList: some View {
        List(selection: $selectedConfigurationID) {
            ForEach(configurations) { entry in
                Button {
                    loadConfiguration(entry)
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(entry.configuration.name)
                                .font(.headline)
                            Text("\(entry.configuration.programs.count) programs")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(entry.url.lastPathComponent)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .contextMenu {
                    Button("Load") {
                        loadConfiguration(entry)
                    }
                    Button(role: .destructive) {
                        deleteConfiguration(entry)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }
    
    // MARK: - Actions (File operations + UI wiring)
    
    /// Reload the lists of programs/configurations from disk.
    ///
    /// You can call this:
    /// - On appear
    /// - After saving
    /// - After deleting
    private func refresh() {
        isRefreshing = true
        defer { isRefreshing = false }
        
        do {
            // Rebuild the "Programs" list.
            let programFiles = try fileManager.listProgramFiles()
            programs = try programFiles.compactMap { url in
                let program = try fileManager.loadProgram(from: url)
                return ProgramEntry(url: url, program: program)
            }
            
            // Rebuild the "Configurations" list.
            let configFiles = try fileManager.listConfigurationFiles()
            configurations = try configFiles.compactMap { url in
                let config = try fileManager.loadConfiguration(from: url)
                return ConfigurationEntry(url: url, configuration: config)
            }
            
        } catch {
            showError(error)
        }
    }
    
    /// Save the current program supplied by the host editor.
    private func saveCurrentProgram() {
        let program = provideCurrentProgram()
        do {
            _ = try fileManager.saveProgram(program)
            refresh()
        } catch {
            showError(error)
        }
    }
    
    /// Save the current full configuration supplied by the host editor.
    private func saveCurrentConfiguration() {
        let config = provideCurrentConfiguration()
        do {
            _ = try fileManager.saveConfiguration(config)
            refresh()
        } catch {
            showError(error)
        }
    }
    
    /// Apply a given program entry (from the list) to the host editor.
    ///
    /// Note: This only updates editor-side state via `applyLoadedProgram`.
    /// If you want to also push the patch to the device, do that in the
    /// closure you provide when constructing this view.
    private func loadProgram(_ entry: ProgramEntry) {
        applyLoadedProgram(entry.program)
    }
    
    /// Apply a given configuration entry (from the list) to the host editor.
    private func loadConfiguration(_ entry: ConfigurationEntry) {
        applyLoadedConfiguration(entry.configuration)
    }
    
    /// Delete a program entry from disk and refresh the list.
    private func deleteProgram(_ entry: ProgramEntry) {
        do {
            try fileManager.deleteProgram(at: entry.url)
            refresh()
        } catch {
            showError(error)
        }
    }
    
    /// Delete a configuration entry from disk and refresh the list.
    private func deleteConfiguration(_ entry: ConfigurationEntry) {
        do {
            try fileManager.deleteConfiguration(at: entry.url)
            refresh()
        } catch {
            showError(error)
        }
    }
    
    /// Show an error in an Alert.
    private func showError(_ error: Error) {
        errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        isShowingErrorAlert = true
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
