//
//  FileManagerViewModel.swift
//  Astoria Filter Editor
//
//  Created by Assistant on 11/25/25.
//

import Foundation
import SwiftUI

/**
 # FileManagerViewModel
 
 View model that manages state and coordinates file operations for the file manager UI.
 
 ## Responsibilities
 
 - Maintains current device profile state
 - Tracks available files (profiles, programs, backups)
 - Handles file operations (save, load, delete)
 - Manages SysEx import/export
 - Provides error handling and user feedback
 - Tracks unsaved changes
 
 ## State Management
 
 Uses Swift's `@Observable` macro for automatic view updates when state changes.
 All file operations are async and run off the main thread.
 
 ## Customization Points
 
 - **Auto-save interval**: Modify `autoSaveInterval` constant
 - **Backup retention**: Adjust `maxBackupsToKeep` constant
 - **Default naming**: Customize `generateDefaultName()` method
 */

@MainActor
@Observable
class FileManagerViewModel {
    
    // MARK: - Configuration Constants
    
    /// How often to auto-save (in seconds)
    private let autoSaveInterval: TimeInterval = 300 // 5 minutes
    
    /// Maximum number of backups to retain
    private let maxBackupsToKeep = 10
    
    // MARK: - State Properties
    
    /// Current device profile being edited
    private(set) var currentProfile: MiniworksDeviceProfile
    
    /// Available saved profiles
    private(set) var availableProfiles: [ProfileMetadata] = []
    
    /// Available programs
    private(set) var availablePrograms: [ProgramMetadata] = []
    
    /// Available factory presets
    private(set) var factoryPresets: [ProgramMetadata] = []
    
    /// Available backups
    private(set) var availableBackups: [BackupMetadata] = []
    
    /// Loading state
    private(set) var isLoading = false
    
    /// Error message for display
    private(set) var errorMessage: String?
    
    /// Success message for display
    private(set) var successMessage: String?
    
    /// Whether there are unsaved changes
    private(set) var hasUnsavedChanges = false
    
    /// Last save date
    private(set) var lastSaveDate: Date?
    
    /// Currently selected profile for operations
    var selectedProfile: ProfileMetadata?
    
    /// Currently selected program for operations
    var selectedProgram: ProgramMetadata?
    
    // MARK: - Private Properties
    
    private let fileManager = MiniworksFileManager.shared
    private var autoSaveTimer: Timer?
    private var lastProfileSnapshot: Data?
    
    // MARK: - Lifecycle
    
    init(currentProfile: MiniworksDeviceProfile) {
        self.currentProfile = currentProfile
        self.lastProfileSnapshot = try? JSONEncoder().encode(
            DeviceProfileWrapper(profile: currentProfile)
        )
        startAutoSave()
    }
    
    deinit {
        stopAutoSave()
    }
    
    // MARK: - Initialization
    
    /**
     Initialize the view model by loading available files.
     Call this when the view appears.
     */
    func initialize() async {
        await refreshAllLists()
    }
    
    /**
     Update the current profile reference (called when parent changes it).
     */
    func updateCurrentProfile(_ profile: MiniworksDeviceProfile) {
        self.currentProfile = profile
        checkForUnsavedChanges()
    }
    
    // MARK: - Profile Operations
    
    /**
     Save the current profile with a specific name.
     
     - Parameter name: Name for the profile
     - Returns: True if save was successful
     */
    @discardableResult
    func saveProfile(named name: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await fileManager.saveProfile(currentProfile, name: name)
            lastSaveDate = Date()
            hasUnsavedChanges = false
            updateSnapshot()
            await refreshProfilesList()
            showSuccess("Profile saved: \(name)")
            return true
        } catch {
            showError("Failed to save profile: \(error.localizedDescription)")
            return false
        }
    }
    
    /**
     Load a profile by name.
     
     - Parameter name: Name of the profile to load
     */
    func loadProfile(named name: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let profile = try await fileManager.loadProfile(named: name)
            currentProfile = profile
            hasUnsavedChanges = false
            updateSnapshot()
            showSuccess("Profile loaded: \(name)")
        } catch {
            showError("Failed to load profile: \(error.localizedDescription)")
        }
    }
    
    /**
     Delete a profile by name.
     
     - Parameter name: Name of the profile to delete
     */
    func deleteProfile(named name: String) async {
        do {
            try await fileManager.deleteProfile(named: name)
            await refreshProfilesList()
            showSuccess("Profile deleted: \(name)")
        } catch {
            showError("Failed to delete profile: \(error.localizedDescription)")
        }
    }
    
    /**
     Quick save with default naming.
     Uses "QuickSave" with timestamp.
     */
    func quickSave() async {
        let name = generateDefaultName(prefix: "QuickSave")
        await saveProfile(named: name)
    }
    
    // MARK: - Program Operations
    
    /**
     Save an individual program.
     
     - Parameters:
        - program: The program to save
        - name: Name for the program
        - isFactory: Whether to save as factory preset
     */
    func saveProgram(_ program: MiniWorksProgram, named name: String, isFactory: Bool = false) async {
        isLoading = true
        
        do {
            try await fileManager.saveProgram(program, name: name, isFactory: isFactory)
            await refreshProgramsList()
            showSuccess("Program saved: \(name)")
        } catch {
            showError("Failed to save program: \(error.localizedDescription)")
        }
    }
    
    /**
     Load a program by name.
     
     - Parameters:
        - name: Name of the program
        - fromFactory: Whether to load from factory presets
     - Returns: The loaded program, or nil if load failed
     */
    func loadProgram(named name: String, fromFactory: Bool = false) async -> MiniWorksProgram? {
        do {
            let program = try await fileManager.loadProgram(named: name, fromFactory: fromFactory)
            showSuccess("Program loaded: \(name)")
            return program
        } catch {
            showError("Failed to load program: \(error.localizedDescription)")
            return nil
        }
    }
    
    /**
     Delete a program by name.
     
     - Parameters:
        - name: Name of the program to delete
        - fromFactory: Whether to delete from factory presets (use with caution)
     */
    func deleteProgram(named name: String, fromFactory: Bool = false) async {
        do {
            try await fileManager.deleteProgram(named: name, fromFactory: fromFactory)
            await refreshProgramsList()
            showSuccess("Program deleted: \(name)")
        } catch {
            showError("Failed to delete program: \(error.localizedDescription)")
        }
    }
    
    /**
     Import a program into the current profile at a specific slot.
     
     - Parameters:
        - program: The program to import
        - slot: Program number (1-20)
     */
    func importProgramToSlot(_ program: MiniWorksProgram, slot: Int) {
        guard slot >= 1 && slot <= 20 else { return }
        currentProfile.updateProgram(program, number: slot)
        hasUnsavedChanges = true
        showSuccess("Program imported to slot \(slot)")
    }
    
    // MARK: - SysEx Operations
    
    /**
     Export the current profile as a SysEx file.
     
     - Parameter name: Name for the exported file
     - Returns: URL of the exported file, or nil if export failed
     */
    func exportProfileAsSysEx(named name: String) async -> URL? {
        isLoading = true
        
        do {
            let url = try await fileManager.exportProfileAsSysEx(currentProfile, name: name)
            showSuccess("Profile exported to: \(url.lastPathComponent)")
            return url
        } catch {
            showError("Failed to export profile: \(error.localizedDescription)")
            return nil
        }
    }
    
    /**
     Export a program as a SysEx file.
     
     - Parameters:
        - program: The program to export
        - name: Name for the exported file
     - Returns: URL of the exported file, or nil if export failed
     */
    func exportProgramAsSysEx(_ program: MiniWorksProgram, named name: String) async -> URL? {
        isLoading = true
        
        do {
            let url = try await fileManager.exportProgramAsSysEx(
                program,
                name: name,
                deviceID: currentProfile.deviceID
            )
            showSuccess("Program exported to: \(url.lastPathComponent)")
            return url
        } catch {
            showError("Failed to export program: \(error.localizedDescription)")
            return nil
        }
    }
    
    /**
     Import a SysEx file.
     
     - Parameter url: URL of the .syx file to import
     - Returns: True if import was successful
     */
    @discardableResult
    func importSysExFile(from url: URL) async -> Bool {
        isLoading = true
        
        do {
            let result = try await fileManager.importSysExFile(from: url)
            
            if let profile = result as? MiniworksDeviceProfile {
                currentProfile = profile
                hasUnsavedChanges = true
                showSuccess("Device profile imported from SysEx")
                return true
            }
            else if let program = result as? MiniWorksProgram {
                // For single program imports, we could store it or prompt user
                showSuccess("Program imported from SysEx")
                return true
            }
            
            return false
        } catch {
            showError("Failed to import SysEx: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Backup Operations
    
    /**
     Create a manual backup of the current profile.
     */
    func createBackup() async {
        do {
            _ = try await fileManager.createBackup(of: currentProfile)
            await refreshBackupsList()
            showSuccess("Backup created")
        } catch {
            showError("Failed to create backup: \(error.localizedDescription)")
        }
    }
    
    /**
     Restore a profile from a backup.
     
     - Parameter backup: The backup metadata
     */
    func restoreBackup(_ backup: BackupMetadata) async {
        await loadProfile(named: backup.name)
    }
    
    /**
     Delete a backup.
     
     - Parameter backup: The backup to delete
     */
    func deleteBackup(_ backup: BackupMetadata) async {
        await deleteProfile(named: backup.name)
        await refreshBackupsList()
    }
    
    /**
     Clean up old backups, keeping only the most recent ones.
     */
    func cleanOldBackups() async {
        if availableBackups.count > maxBackupsToKeep {
            let toDelete = availableBackups.suffix(from: maxBackupsToKeep)
            
            for backup in toDelete {
                try? await fileManager.deleteProfile(named: backup.name)
            }
            
            await refreshBackupsList()
            showSuccess("Cleaned \(toDelete.count) old backups")
        }
    }
    
    // MARK: - List Refresh
    
    /**
     Refresh all file lists (profiles, programs, backups).
     */
    func refreshAllLists() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.refreshProfilesList() }
            group.addTask { await self.refreshProgramsList() }
            group.addTask { await self.refreshBackupsList() }
        }
    }
    
    /**
     Refresh the list of available profiles.
     */
    func refreshProfilesList() async {
        do {
            let names = try await fileManager.listProfiles()
            
            // Get file metadata for each profile
            var metadata: [ProfileMetadata] = []
            for name in names {
                if let meta = await getProfileMetadata(name: name) {
                    metadata.append(meta)
                }
            }
            
            availableProfiles = metadata.sorted { $0.modifiedDate > $1.modifiedDate }
        } catch {
            showError("Failed to refresh profiles list: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    /**
     Refresh the list of available programs.
     */
    func refreshProgramsList() async {
        do {
            let userPrograms = try await fileManager.listPrograms(includeFactory: false)
            let factoryPrograms = try await fileManager.listPrograms(includeFactory: true)
                .filter { $0.hasPrefix("Factory:") }
            
            // Get metadata
            availablePrograms = userPrograms.compactMap { name in
                ProgramMetadata(name: name, isFactory: false)
            }.sorted { $0.name < $1.name }
            
            factoryPresets = factoryPrograms.compactMap { name in
                let cleanName = name.replacingOccurrences(of: "Factory: ", with: "")
                return ProgramMetadata(name: cleanName, isFactory: true)
            }.sorted { $0.name < $1.name }
            
        } catch {
            showError("Failed to refresh programs list: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    /**
     Refresh the list of available backups.
     */
    func refreshBackupsList() async {
        do {
            let backups = try await fileManager.listBackups()
            availableBackups = backups.map { backup in
                BackupMetadata(name: backup.name, date: backup.date)
            }.sorted { $0.date > $1.date }
        } catch {
            showError("Failed to refresh backups list: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    // MARK: - Private Helpers
    
    private func getProfileMetadata(name: String) async -> ProfileMetadata? {
        do {
            let directory = try FileManagerPaths.profilesDirectory
            let url = directory.appendingPathComponent("\(name).json")
            
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let modifiedDate = attributes[.modificationDate] as? Date ?? Date()
            let size = attributes[.size] as? Int64 ?? 0
            
            return ProfileMetadata(
                name: name,
                modifiedDate: modifiedDate,
                fileSize: size
            )
        } catch {
            return nil
        }
    }
    
    private func generateDefaultName(prefix: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return "\(prefix)_\(formatter.string(from: Date()))"
    }
    
    private func updateSnapshot() {
        lastProfileSnapshot = try? JSONEncoder().encode(
            DeviceProfileWrapper(profile: currentProfile)
        )
    }
    
    private func checkForUnsavedChanges() {
        guard let snapshot = lastProfileSnapshot else {
            hasUnsavedChanges = true
            return
        }
        
        let currentData = try? JSONEncoder().encode(
            DeviceProfileWrapper(profile: currentProfile)
        )
        
        hasUnsavedChanges = currentData != snapshot
    }
    
    // MARK: - Auto-Save
    
    private func startAutoSave() {
        autoSaveTimer = Timer.scheduledTimer(
            withTimeInterval: autoSaveInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.performAutoSave()
            }
        }
    }
    
    private func stopAutoSave() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = nil
    }
    
    private func performAutoSave() async {
        guard hasUnsavedChanges else { return }
        
        let name = generateDefaultName(prefix: "AutoSave")
        await saveProfile(named: name)
    }
    
    // MARK: - User Feedback
    
    private func showError(_ message: String) {
        errorMessage = message
        isLoading = false
        
        // Auto-clear after delay
        Task {
            try? await Task.sleep(for: .seconds(5))
            if errorMessage == message {
                errorMessage = nil
            }
        }
    }
    
    private func showSuccess(_ message: String) {
        successMessage = message
        isLoading = false
        
        // Auto-clear after delay
        Task {
            try? await Task.sleep(for: .seconds(3))
            if successMessage == message {
                successMessage = nil
            }
        }
    }
    
    /**
     Clear any displayed error or success messages.
     */
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}

// MARK: - Metadata Structures

/**
 Metadata for a saved profile.
 */
struct ProfileMetadata: Identifiable {
    let id = UUID()
    let name: String
    let modifiedDate: Date
    let fileSize: Int64
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
}

/**
 Metadata for a saved program.
 */
struct ProgramMetadata: Identifiable {
    let id = UUID()
    let name: String
    let isFactory: Bool
}

/**
 Metadata for a backup.
 */
struct BackupMetadata: Identifiable {
    let id = UUID()
    let name: String
    let date: Date
}
