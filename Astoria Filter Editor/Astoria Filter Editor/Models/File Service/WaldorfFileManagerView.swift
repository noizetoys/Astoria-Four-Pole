//
//  WaldorfFileManagerView.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/25/25.
//

import SwiftUI


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
