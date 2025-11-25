//
//  MiniworksFileManager+Examples.swift
//  Astoria Filter Editor
//
//  Created by Assistant on 11/25/25.
//

import Foundation
import SwiftUI

/**
 # Usage Guide and Examples
 
 This file demonstrates how to integrate and use the `MiniworksFileManager`
 in your application. It includes common patterns, SwiftUI integration,
 and best practices.
 
 ## Table of Contents
 
 1. Basic Setup
 2. Saving and Loading Profiles
 3. Working with Individual Programs
 4. SysEx Import/Export
 5. SwiftUI Integration
 6. Error Handling
 7. Backup Management
 8. Adapting for Other Synthesizers
 */

// MARK: - 1. Basic Setup

/**
 ## Basic Setup
 
 Create a file manager instance. Typically you'll want a shared instance
 accessible throughout your app.
 */
extension MiniworksFileManager {
    /// Shared instance for app-wide access
    static let shared = MiniworksFileManager()
}

// MARK: - 2. Saving and Loading Profiles

/**
 ## Examples: Device Profile Operations
 */
class ProfileExamples {
    let fileManager = MiniworksFileManager.shared
    
    /// Save a complete device profile
    func saveCurrentSetup(_ profile: MiniworksDeviceProfile, named name: String) async {
        do {
            try await fileManager.saveProfile(profile, name: name)
            print("✅ Profile saved successfully")
        } catch {
            print("❌ Failed to save profile: \(error.localizedDescription)")
        }
    }
    
    /// Load a profile from disk
    func loadSetup(named name: String) async -> MiniworksDeviceProfile? {
        do {
            let profile = try await fileManager.loadProfile(named: name)
            print("✅ Profile loaded successfully")
            return profile
        } catch {
            print("❌ Failed to load profile: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Get all available profiles
    func getAvailableProfiles() async -> [String] {
        do {
            let profiles = try await fileManager.listProfiles()
            print("📁 Found \(profiles.count) profiles")
            return profiles
        } catch {
            print("❌ Failed to list profiles: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Auto-save with timestamp
    func autoSave(_ profile: MiniworksDeviceProfile) async {
        let timestamp = DateFormatter.localizedString(
            from: Date(),
            dateStyle: .short,
            timeStyle: .short
        )
        let name = "AutoSave_\(timestamp)"
        await saveCurrentSetup(profile, named: name)
    }
}

// MARK: - 3. Working with Individual Programs

/**
 ## Examples: Individual Program Operations
 */
class ProgramExamples {
    let fileManager = MiniworksFileManager.shared
    
    /// Save a single program patch
    func savePatch(_ program: MiniWorksProgram, named name: String) async {
        do {
            try await fileManager.saveProgram(program, name: name)
            print("✅ Program saved: \(name)")
        } catch {
            print("❌ Failed to save program: \(error.localizedDescription)")
        }
    }
    
    /// Load a program from disk
    func loadPatch(named name: String) async -> MiniWorksProgram? {
        do {
            let program = try await fileManager.loadProgram(named: name)
            print("✅ Program loaded: \(name)")
            return program
        } catch {
            print("❌ Failed to load program: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Copy a program to factory presets (for distribution)
    func addToFactory(_ program: MiniWorksProgram, named name: String) async {
        do {
            try await fileManager.saveProgram(program, name: name, isFactory: true)
            print("✅ Added to factory presets: \(name)")
        } catch {
            print("❌ Failed to add to factory: \(error.localizedDescription)")
        }
    }
    
    /// Browse all available patches
    func browsePatchLibrary() async -> [String] {
        do {
            let programs = try await fileManager.listPrograms(includeFactory: true)
            return programs
        } catch {
            print("❌ Failed to browse library: \(error.localizedDescription)")
            return []
        }
    }
}

// MARK: - 4. SysEx Import/Export

/**
 ## Examples: SysEx Operations
 */
class SysExExamples {
    let fileManager = MiniworksFileManager.shared
    
    /// Export device profile as SysEx for hardware backup
    func backupToHardware(_ profile: MiniworksDeviceProfile, named name: String) async -> URL? {
        do {
            let url = try await fileManager.exportProfileAsSysEx(profile, name: name)
            print("✅ SysEx exported to: \(url.path)")
            print("📤 Send this file to your Miniworks via SysEx transfer")
            return url
        } catch {
            print("❌ Failed to export SysEx: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Export a single program as SysEx
    func exportPatchForSharing(_ program: MiniWorksProgram, named name: String) async -> URL? {
        do {
            let url = try await fileManager.exportProgramAsSysEx(
                program,
                name: name,
                deviceID: 0  // Use device ID 0 for compatibility
            )
            print("✅ Program exported: \(url.path)")
            return url
        } catch {
            print("❌ Failed to export program: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Import SysEx file from hardware or file sharing
    func importFromSysEx(fileURL: URL) async {
        do {
            let result = try await fileManager.importSysExFile(from: fileURL)
            
            if let profile = result as? MiniworksDeviceProfile {
                print("✅ Imported device profile")
                // Handle imported profile
                await saveImportedProfile(profile)
            }
            else if let program = result as? MiniWorksProgram {
                print("✅ Imported program")
                // Handle imported program
                await saveImportedProgram(program)
            }
        } catch {
            print("❌ Failed to import SysEx: \(error.localizedDescription)")
        }
    }
    
    private func saveImportedProfile(_ profile: MiniworksDeviceProfile) async {
        let name = "Imported_\(Date().timeIntervalSince1970)"
        do {
            try await fileManager.saveProfile(profile, name: name)
        } catch {
            print("❌ Failed to save imported profile: \(error)")
        }
    }
    
    private func saveImportedProgram(_ program: MiniWorksProgram) async {
        let name = "Imported_\(program.programName)"
        do {
            try await fileManager.saveProgram(program, name: name)
        } catch {
            print("❌ Failed to save imported program: \(error)")
        }
    }
}

// MARK: - 5. SwiftUI Integration

/**
 ## SwiftUI View Model Integration
 
 Example of how to integrate the file manager with your app's view model.
 */
@MainActor
@Observable
class DocumentManagerViewModel {
    private let fileManager = MiniworksFileManager.shared
    
    // Current state
    var currentProfile: MiniworksDeviceProfile?
    var availableProfiles: [String] = []
    var availablePrograms: [String] = []
    var isLoading = false
    var errorMessage: String?
    
    // MARK: - Lifecycle
    
    init() {
        Task {
            await refreshLists()
        }
    }
    
    // MARK: - Profile Operations
    
    func saveProfile(named name: String) async {
        guard let profile = currentProfile else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await fileManager.saveProfile(profile, name: name)
            await refreshLists()
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func loadProfile(named name: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            currentProfile = try await fileManager.loadProfile(named: name)
        } catch {
            errorMessage = "Failed to load: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func deleteProfile(named name: String) async {
        do {
            try await fileManager.deleteProfile(named: name)
            await refreshLists()
        } catch {
            errorMessage = "Failed to delete: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Program Operations
    
    func saveProgram(_ program: MiniWorksProgram, named name: String) async {
        isLoading = true
        
        do {
            try await fileManager.saveProgram(program, name: name)
            await refreshLists()
        } catch {
            errorMessage = "Failed to save program: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func loadProgram(named name: String) async -> MiniWorksProgram? {
        do {
            return try await fileManager.loadProgram(named: name)
        } catch {
            errorMessage = "Failed to load program: \(error.localizedDescription)"
            return nil
        }
    }
    
    // MARK: - SysEx Operations
    
    func exportCurrentProfileAsSysEx(named name: String) async -> URL? {
        guard let profile = currentProfile else { return nil }
        
        do {
            return try await fileManager.exportProfileAsSysEx(profile, name: name)
        } catch {
            errorMessage = "Export failed: \(error.localizedDescription)"
            return nil
        }
    }
    
    func importSysEx(from url: URL) async {
        do {
            let result = try await fileManager.importSysExFile(from: url)
            
            if let profile = result as? MiniworksDeviceProfile {
                currentProfile = profile
            }
            
            await refreshLists()
        } catch {
            errorMessage = "Import failed: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Backup Operations
    
    func createBackup() async {
        guard let profile = currentProfile else { return }
        
        do {
            _ = try await fileManager.createBackup(of: profile)
        } catch {
            errorMessage = "Backup failed: \(error.localizedDescription)"
        }
    }
    
    func listBackups() async -> [(name: String, date: Date)] {
        do {
            return try await fileManager.listBackups()
        } catch {
            errorMessage = "Failed to list backups: \(error.localizedDescription)"
            return []
        }
    }
    
    // MARK: - Utility
    
    func refreshLists() async {
        do {
            availableProfiles = try await fileManager.listProfiles()
            availablePrograms = try await fileManager.listPrograms(includeFactory: false)
        } catch {
            errorMessage = "Failed to refresh lists: \(error.localizedDescription)"
        }
    }
}

// MARK: - Example SwiftUI Views

/**
 ## Example: Profile Picker View
 */
struct ProfilePickerView: View {
    @State private var viewModel = DocumentManagerViewModel()
    @State private var showingSaveDialog = false
    @State private var newProfileName = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // Profile List
            List {
                ForEach(viewModel.availableProfiles, id: \.self) { profileName in
                    HStack {
                        Text(profileName)
                        Spacer()
                        Button("Load") {
                            Task {
                                await viewModel.loadProfile(named: profileName)
                            }
                        }
                    }
                }
            }
            
            // Actions
            HStack {
                Button("Save Current") {
                    showingSaveDialog = true
                }
                .disabled(viewModel.currentProfile == nil)
                
                Button("Create Backup") {
                    Task {
                        await viewModel.createBackup()
                    }
                }
                .disabled(viewModel.currentProfile == nil)
            }
            
            // Error message
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding()
        .sheet(isPresented: $showingSaveDialog) {
            SaveProfileDialog(
                profileName: $newProfileName,
                onSave: {
                    Task {
                        await viewModel.saveProfile(named: newProfileName)
                        showingSaveDialog = false
                        newProfileName = ""
                    }
                }
            )
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView("Loading...")
            }
        }
    }
}

/**
 ## Example: Save Dialog
 */
struct SaveProfileDialog: View {
    @Binding var profileName: String
    let onSave: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Save Profile")
                .font(.headline)
            
            TextField("Profile Name", text: $profileName)
                .textFieldStyle(.roundedBorder)
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                
                Button("Save") {
                    onSave()
                }
                .disabled(profileName.isEmpty)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 300)
    }
}

// MARK: - 6. Error Handling Patterns

/**
 ## Best Practices: Error Handling
 */
class ErrorHandlingExamples {
    let fileManager = MiniworksFileManager.shared
    
    /// Comprehensive error handling with recovery
    func saveWithRecovery(_ profile: MiniworksDeviceProfile, named name: String) async {
        do {
            try await fileManager.saveProfile(profile, name: name)
            print("✅ Save successful")
        }
        catch MiniworksFileError.invalidPath {
            print("⚠️ Invalid path - checking directory structure...")
            try? await fileManager.createDirectoryStructure()
            // Retry
            try? await fileManager.saveProfile(profile, name: name)
        }
        catch MiniworksFileError.writePermissionDenied {
            print("❌ Permission denied - check file permissions")
            // Show user alert about permissions
        }
        catch {
            print("❌ Unexpected error: \(error)")
            // Log for debugging
        }
    }
    
    /// Validate before importing
    func safeImport(from url: URL) async -> Bool {
        // Check file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("❌ File not found")
            return false
        }
        
        // Check file extension
        guard url.pathExtension == "syx" else {
            print("❌ Invalid file type (expected .syx)")
            return false
        }
        
        // Attempt import
        do {
            _ = try await fileManager.importSysExFile(from: url)
            return true
        } catch MiniworksFileError.invalidSysEx {
            print("❌ Invalid SysEx format")
            return false
        } catch MiniworksFileError.checksumMismatch {
            print("❌ Corrupted file (checksum failed)")
            return false
        } catch {
            print("❌ Import failed: \(error)")
            return false
        }
    }
}

// MARK: - 7. Backup Management

/**
 ## Automatic Backup System
 */
@MainActor
class BackupManager {
    let fileManager = MiniworksFileManager.shared
    private var backupTimer: Timer?
    
    /// Start automatic backups every interval
    func startAutomaticBackups(
        profile: MiniworksDeviceProfile,
        intervalMinutes: Int = 30
    ) {
        backupTimer?.invalidate()
        
        backupTimer = Timer.scheduledTimer(
            withTimeInterval: TimeInterval(intervalMinutes * 60),
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.performBackup(profile)
            }
        }
    }
    
    func stopAutomaticBackups() {
        backupTimer?.invalidate()
        backupTimer = nil
    }
    
    private func performBackup(_ profile: MiniworksDeviceProfile) async {
        do {
            let url = try await fileManager.createBackup(of: profile)
            print("🔄 Auto-backup created: \(url.lastPathComponent)")
            
            // Clean old backups (keep last 10)
            await cleanOldBackups(keepLast: 10)
        } catch {
            print("❌ Auto-backup failed: \(error)")
        }
    }
    
    private func cleanOldBackups(keepLast: Int) async {
        do {
            let backups = try await fileManager.listBackups()
            
            if backups.count > keepLast {
                let toDelete = backups.suffix(from: keepLast)
                
                for backup in toDelete {
                    try? await fileManager.deleteProfile(named: backup.name)
                }
                
                print("🗑️ Cleaned \(toDelete.count) old backups")
            }
        } catch {
            print("❌ Failed to clean backups: \(error)")
        }
    }
}

// MARK: - 8. Adapting for Other Synthesizers

/**
 ## Guide: Adapting This System for Different Hardware
 
 To adapt this file manager for a different synthesizer:
 
 ### 1. Update SysEx Format Constants
 
 In `MiniworksFileManager.swift`, modify the `SysExFormat` enum:
 
 ```swift
 enum SysExFormat {
     static let startByte: UInt8 = 0xF0
     static let endByte: UInt8 = 0xF7
     static let yourManufacturerID: UInt8 = 0x??  // Your manufacturer
     static let yourModelID: UInt8 = 0x??          // Your model
     
     static let programDump: UInt8 = 0x??
     static let allDump: UInt8 = 0x??
 }
 ```
 
 ### 2. Update Checksum Calculation
 
 Different manufacturers use different checksum algorithms. Common ones:
 
 - **7-bit sum** (Waldorf, Roland): `sum & 0x7F`
 - **Two's complement**: `(128 - (sum & 0x7F)) & 0x7F`
 - **XOR checksum**: XOR all bytes
 
 Modify `calculateChecksum()` method accordingly.
 
 ### 3. Adjust Byte Positions
 
 Update parsing methods `parseAllDump()` and `parseProgramDump()` to match
 your device's SysEx structure.
 
 ### 4. Create Your Own Codable Wrappers
 
 In `MiniworksFileManager+Codable.swift`, create wrappers for your synthesizer's
 data structures. Follow the same pattern but adjust for your parameters.
 
 ### 5. Update Directory Names
 
 Change `FileManagerPaths` bundle identifier and directory names to match
 your application.
 
 ### Example: Adapting for Roland JX-8P
 
 ```swift
 enum RolandSysExFormat {
     static let rolandID: UInt8 = 0x41
     static let jx8pID: UInt8 = 0x33
     static let allDump: UInt8 = 0x35
     
     // Roland uses two's complement checksum
     static func checksum(_ data: [UInt8]) -> UInt8 {
         let sum = data.reduce(0) { $0 + Int($1) }
         return UInt8((128 - (sum & 0x7F)) & 0x7F)
     }
 }
 ```
 */

