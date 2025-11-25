//
//  MiniworksFileManager.swift
//  Astoria Filter Editor
//
//  Created by Assistant on 11/25/25.
//

import Foundation

/**
 # MiniworksFileManager
 
 A comprehensive file management system for the Miniworks MIDI editor that provides:
 - JSON persistence for Device Profiles and Programs
 - SysEx export functionality
 - Organized file structure in user's Application Support directory
 
 ## Architecture Overview
 
 The file manager operates on two main data types:
 1. **Device Profiles**: Complete device state including all 20 user programs and global settings
 2. **Individual Programs**: Single program patches that can be imported/exported independently
 
 ## File Structure
 
 ```
 ~/Library/Application Support/MiniworksEditor/
 ├── Profiles/              # Device profile storage
 │   ├── profile_name.json
 │   └── backup_YYYYMMDD_HHMMSS.json
 ├── Programs/              # Individual program storage
 │   ├── program_name.json
 │   └── factory_presets/
 ├── SysEx/                 # Exported SysEx files
 │   ├── Profiles/
 │   └── Programs/
 └── Logs/                  # Error and operation logs
 ```
 
 ## JSON Format
 
 JSON files use the Codable protocol for type-safe serialization. The format preserves:
 - All parameter values
 - Program metadata (names, tags, creation dates)
 - Global settings
 - Read-only status
 
 ## SysEx Export
 
 SysEx files follow the Waldorf Miniworks specification:
 - Device Profiles: All Dump format (F0 3E 04 [Device ID] 08 ... F7)
 - Programs: Single Program Dump (F0 3E 04 [Device ID] 00/01 ... F7)
 
 All exports include proper checksums calculated per Waldorf specification.
 
 ## Customization Points
 
 To adapt this system for different synthesizers:
 1. Modify `SysExFormat` enum for your device's message types
 2. Update `encodeToSysEx()` methods with your device's byte structure
 3. Adjust `calculateChecksum()` if your device uses different validation
 4. Change directory structure in `FileManagerPaths` as needed
 */




// MARK: - Main File Manager

/**
 Primary class for all file operations.
 
 ## Usage Examples
 
 ```swift
 let fileManager = MiniworksFileManager()
 
 // Save a device profile
 try await fileManager.saveProfile(deviceProfile, name: "My Setup")
 
 // Load a profile
 let profile = try await fileManager.loadProfile(named: "My Setup")
 
 // Export as SysEx
 try await fileManager.exportProfileAsSysEx(deviceProfile, name: "MySetup")
 
 // Save individual program
 try await fileManager.saveProgram(program, name: "Bass Patch")
 ```
 */
@MainActor
class MiniworksFileManager {
    
    private let fileManager = FileManager.default
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder
    
    // MARK: - Lifecycle
    
    init() {
        // Configure JSON encoder for readable output
        jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        jsonEncoder.dateEncodingStrategy = .iso8601
        
        // Configure JSON decoder
        jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .iso8601
        
        // Ensure directory structure exists
        Task {
            try? await createDirectoryStructure()
        }
    }
    
    // MARK: - Directory Management
    
    /**
     Creates the complete directory structure for the application.
     Called automatically on initialization but can be called manually if needed.
     */
    func createDirectoryStructure() async throws {
        let directories = [
            try FileManagerPaths.profilesDirectory,
            try FileManagerPaths.programsDirectory,
            try FileManagerPaths.sysExDirectory,
            try FileManagerPaths.logsDirectory,
            try FileManagerPaths.factoryPresetsDirectory,
            try FileManagerPaths.sysExDirectory.appendingPathComponent("Profiles"),
            try FileManagerPaths.sysExDirectory.appendingPathComponent("Programs")
        ]
        
        for directory in directories {
            if !fileManager.fileExists(atPath: directory.path) {
                try fileManager.createDirectory(
                    at: directory,
                    withIntermediateDirectories: true
                )
            }
        }
    }
    
    // MARK: - Device Profile Operations
    
    /**
     Saves a complete device profile to JSON.
     
     - Parameters:
        - profile: The device profile to save
        - name: Filename (without extension)
     - Throws: `MiniworksFileError` if save fails
     
     The profile is saved with metadata including timestamp and version info.
     */
    func saveProfile(_ profile: MiniworksDeviceProfile, name: String) async throws {
        let wrapper = DeviceProfileWrapper(profile: profile)
        let data = try jsonEncoder.encode(wrapper)
        
        let filename = sanitizeFilename(name)
        let url = try FileManagerPaths.profilesDirectory
            .appendingPathComponent("\(filename).json")
        
        try data.write(to: url, options: .atomic)
        
        logOperation("Saved profile: \(name) to \(url.path)")
    }
    
    /**
     Loads a device profile from JSON.
     
     - Parameter name: Filename (without extension)
     - Returns: The loaded device profile
     - Throws: `MiniworksFileError` if load fails
     */
    func loadProfile(named name: String) async throws -> MiniworksDeviceProfile {
        let filename = sanitizeFilename(name)
        let url = try FileManagerPaths.profilesDirectory
            .appendingPathComponent("\(filename).json")
        
        guard fileManager.fileExists(atPath: url.path)
        else {
            throw MiniworksFileError.fileNotFound(name)
        }
        
        let data = try Data(contentsOf: url)
        let wrapper = try jsonDecoder.decode(DeviceProfileWrapper.self, from: data)
        
        logOperation("Loaded profile: \(name) from \(url.path)")
        
        return wrapper.toDeviceProfile()
    }
    
    /**
     Lists all available device profiles.
     
     - Returns: Array of profile names (without extensions)
     */
    func listProfiles() async throws -> [String] {
        let directory = try FileManagerPaths.profilesDirectory
        let contents = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.nameKey],
            options: .skipsHiddenFiles
        )
        
        return contents
            .filter { $0.pathExtension == "json" }
            .map { $0.deletingPathExtension().lastPathComponent }
            .sorted()
    }
    
    /**
     Deletes a device profile.
     
     - Parameter name: Profile name to delete
     - Throws: `MiniworksFileError` if deletion fails
     */
    func deleteProfile(named name: String) async throws {
        let filename = sanitizeFilename(name)
        let url = try FileManagerPaths.profilesDirectory
            .appendingPathComponent("\(filename).json")
        
        try fileManager.removeItem(at: url)
        logOperation("Deleted profile: \(name)")
    }
    
    // MARK: - Individual Program Operations
    
    /**
     Saves an individual program to JSON.
     
     - Parameters:
        - program: The program to save
        - name: Filename (without extension)
        - isFactory: If true, saves to factory presets directory
     - Throws: `MiniworksFileError` if save fails
     */
    func saveProgram(_ program: MiniWorksProgram, name: String, isFactory: Bool = false) async throws {
        let wrapper = ProgramWrapper(program: program)
        let data = try jsonEncoder.encode(wrapper)
        
        let filename = sanitizeFilename(name)
        let directory = isFactory 
            ? try FileManagerPaths.factoryPresetsDirectory 
            : try FileManagerPaths.programsDirectory
        let url = directory.appendingPathComponent("\(filename).json")
        
        try data.write(to: url, options: .atomic)
        
        logOperation("Saved program: \(name) to \(url.path)")
    }
    
    /**
     Loads an individual program from JSON.
     
     - Parameters:
        - name: Filename (without extension)
        - fromFactory: If true, loads from factory presets directory
     - Returns: The loaded program
     - Throws: `MiniworksFileError` if load fails
     */
    func loadProgram(named name: String, fromFactory: Bool = false) async throws -> MiniWorksProgram {
        let filename = sanitizeFilename(name)
        let directory = fromFactory 
            ? try FileManagerPaths.factoryPresetsDirectory 
            : try FileManagerPaths.programsDirectory
        let url = directory.appendingPathComponent("\(filename).json")
        
        guard fileManager.fileExists(atPath: url.path) else {
            throw MiniworksFileError.fileNotFound(name)
        }
        
        let data = try Data(contentsOf: url)
        let wrapper = try jsonDecoder.decode(ProgramWrapper.self, from: data)
        
        logOperation("Loaded program: \(name) from \(url.path)")
        
        return wrapper.toProgram()
    }
    
    /**
     Lists all available programs.
     
     - Parameter includeFactory: Whether to include factory presets
     - Returns: Array of program names (without extensions)
     */
    func listPrograms(includeFactory: Bool = false) async throws -> [String] {
        var allPrograms: [String] = []
        
        // User programs
        let userDirectory = try FileManagerPaths.programsDirectory
        let userContents = try fileManager.contentsOfDirectory(
            at: userDirectory,
            includingPropertiesForKeys: [.nameKey],
            options: .skipsHiddenFiles
        )
        allPrograms += userContents
            .filter { $0.pathExtension == "json" }
            .map { $0.deletingPathExtension().lastPathComponent }
        
        // Factory programs
        if includeFactory {
            let factoryDirectory = try FileManagerPaths.factoryPresetsDirectory
            let factoryContents = try fileManager.contentsOfDirectory(
                at: factoryDirectory,
                includingPropertiesForKeys: [.nameKey],
                options: .skipsHiddenFiles
            )
            allPrograms += factoryContents
                .filter { $0.pathExtension == "json" }
                .map { "Factory: " + $0.deletingPathExtension().lastPathComponent }
        }
        
        return allPrograms.sorted()
    }
    
    /**
     Deletes an individual program.
     
     - Parameters:
        - name: Program name to delete
        - fromFactory: If true, deletes from factory presets (use with caution)
     - Throws: `MiniworksFileError` if deletion fails
     */
    func deleteProgram(named name: String, fromFactory: Bool = false) async throws {
        let filename = sanitizeFilename(name)
        let directory = fromFactory 
            ? try FileManagerPaths.factoryPresetsDirectory 
            : try FileManagerPaths.programsDirectory
        let url = directory.appendingPathComponent("\(filename).json")
        
        try fileManager.removeItem(at: url)
        logOperation("Deleted program: \(name)")
    }
    
    // MARK: - SysEx Export Operations
    
    /**
     Exports a complete device profile as a SysEx file (All Dump format).
     
     - Parameters:
        - profile: The device profile to export
        - name: Filename (without extension)
     - Returns: URL of the exported file
     - Throws: `MiniworksFileError` if export fails
     
     ## SysEx Structure
     The exported file contains:
     - 20 user programs (programs 1-20)
     - Global settings (MIDI channel, device ID, etc.)
     - Checksum validation byte
     
     Total size: 593 bytes per Waldorf specification
     */
    func exportProfileAsSysEx(_ profile: MiniworksDeviceProfile, name: String) async throws -> URL {
        let filename = sanitizeFilename(name)
        let directory = try FileManagerPaths.sysExDirectory.appendingPathComponent("Profiles")
        
        // Ensure subdirectory exists
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        
        let url = directory.appendingPathComponent("\(filename).syx")
        
        // Build complete SysEx message
        var sysExData: [UInt8] = []
        
        // Header
        sysExData.append(contentsOf: SysExFormat.header(
            deviceID: profile.deviceID,
            messageType: SysExFormat.allDump
        ))
        
        // Program and global data
        let payload = profile.encodeToBytes()
        sysExData.append(contentsOf: payload)
        
        // Checksum
        let checksum = calculateChecksum(payload)
        sysExData.append(checksum)
        
        // End of SysEx
        sysExData.append(SysExFormat.endByte)
        
        // Write to file
        let data = Data(sysExData)
        try data.write(to: url, options: .atomic)
        
        logOperation("Exported profile as SysEx: \(name) to \(url.path)")
        
        return url
    }
    
    /**
     Exports an individual program as a SysEx file (Program Dump format).
     
     - Parameters:
        - program: The program to export
        - name: Filename (without extension)
        - deviceID: Device ID to use in SysEx header (default: 0)
     - Returns: URL of the exported file
     - Throws: `MiniworksFileError` if export fails
     
     ## SysEx Structure
     The exported file contains:
     - Single program data (29 parameters)
     - Checksum validation byte
     
     Total size: 37 bytes per Waldorf specification
     */
    func exportProgramAsSysEx(
        _ program: MiniWorksProgram,
        name: String,
        deviceID: UInt8 = 0
    ) async throws -> URL {
        let filename = sanitizeFilename(name)
        let directory = try FileManagerPaths.sysExDirectory.appendingPathComponent("Programs")
        
        // Ensure subdirectory exists
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        
        let url = directory.appendingPathComponent("\(filename).syx")
        
        // Build SysEx message
        var sysExData: [UInt8] = []
        
        // Header
        sysExData.append(contentsOf: SysExFormat.header(
            deviceID: deviceID,
            messageType: SysExFormat.programDump
        ))
        
        // Program data
        let payload = program.encodeToBytes(forAllDump: false)
        sysExData.append(contentsOf: payload)
        
        // Checksum
        let checksum = calculateChecksum(payload)
        sysExData.append(checksum)
        
        // End of SysEx
        sysExData.append(SysExFormat.endByte)
        
        // Write to file
        let data = Data(sysExData)
        try data.write(to: url, options: .atomic)
        
        logOperation("Exported program as SysEx: \(name) to \(url.path)")
        
        return url
    }
    
    /**
     Imports a SysEx file and parses it into a device profile or program.
     
     - Parameter url: URL of the .syx file to import
     - Returns: Either a device profile or program, depending on message type
     - Throws: `MiniworksFileError` if import fails
     
     ## Supported Formats
     - All Dump (0x08): Returns `MiniworksDeviceProfile`
     - Program Dump (0x00): Returns `MiniWorksProgram`
     */
    func importSysExFile(from url: URL) async throws -> Any {
        guard fileManager.fileExists(atPath: url.path) else {
            throw MiniworksFileError.fileNotFound(url.lastPathComponent)
        }
        
        let data = try Data(contentsOf: url)
        let bytes = [UInt8](data)
        
        // Validate basic structure
        guard bytes.first == SysExFormat.startByte,
              bytes.last == SysExFormat.endByte,
              bytes.count > 6
        else {
            throw MiniworksFileError.invalidSysEx
        }
        
        // Check manufacturer and model ID
        guard bytes[1] == SysExFormat.waldorfID,
              bytes[2] == SysExFormat.miniworksID
        else {
            throw MiniworksFileError.invalidSysEx
        }
        
        let messageType = bytes[4]
        
        // Parse based on message type
        switch messageType {
        case SysExFormat.allDump:
            // Parse as device profile
            let profile = try parseAllDump(bytes)
            logOperation("Imported device profile from SysEx: \(url.lastPathComponent)")
            return profile
            
        case SysExFormat.programDump:
            // Parse as single program
            let program = try parseProgramDump(bytes)
            logOperation("Imported program from SysEx: \(url.lastPathComponent)")
            return program
            
        default:
            throw MiniworksFileError.invalidSysEx
        }
    }
    
    // MARK: - Backup Operations
    
    /**
     Creates a timestamped backup of a device profile.
     
     - Parameter profile: The profile to backup
     - Returns: URL of the backup file
     - Throws: `MiniworksFileError` if backup fails
     
     Backups are saved with timestamp format: backup_YYYYMMDD_HHMMSS.json
     */
    func createBackup(of profile: MiniworksDeviceProfile) async throws -> URL {
        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "-", with: "")
        
        let backupName = "backup_\(timestamp)"
        try await saveProfile(profile, name: backupName)
        
        let url = try FileManagerPaths.profilesDirectory
            .appendingPathComponent("\(backupName).json")
        
        logOperation("Created backup: \(backupName)")
        
        return url
    }
    
    /**
     Lists all available backups.
     
     - Returns: Array of backup filenames with creation dates
     */
    func listBackups() async throws -> [(name: String, date: Date)] {
        let directory = try FileManagerPaths.profilesDirectory
        let contents = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.nameKey, .creationDateKey],
            options: .skipsHiddenFiles
        )
        
        return contents
            .filter { $0.lastPathComponent.hasPrefix("backup_") && $0.pathExtension == "json" }
            .compactMap { url in
                guard let date = try? url.resourceValues(forKeys: [.creationDateKey]).creationDate else {
                    return nil
                }
                return (name: url.deletingPathExtension().lastPathComponent, date: date)
            }
            .sorted { $0.date > $1.date }
    }
    
    // MARK: - Utility Methods
    
    /**
     Sanitizes a filename by removing invalid characters.
     
     - Parameter filename: Original filename
     - Returns: Sanitized filename safe for filesystem
     */
    private func sanitizeFilename(_ filename: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        return filename
            .components(separatedBy: invalidCharacters)
            .joined(separator: "_")
            .trimmingCharacters(in: .whitespaces)
    }
    
    /**
     Calculates checksum for SysEx data.
     
     ## Customization Point
     Modify this method if your device uses a different checksum algorithm.
     
     The Waldorf Miniworks uses a simple 7-bit checksum:
     Sum all data bytes, keep only bits 0-6.
     
     - Parameter data: Data bytes to checksum (excluding header and end byte)
     - Returns: Checksum byte
     */
    private func calculateChecksum(_ data: [UInt8]) -> UInt8 {
        let sum = data.reduce(0) { $0 + Int($1) }
        return UInt8(sum & 0x7F)
    }
    
    /**
     Validates a SysEx checksum.
     
     - Parameters:
        - data: Data bytes (excluding header and end byte)
        - checksum: The checksum byte from the message
     - Returns: True if checksum is valid
     */
    private func validateChecksum(_ data: [UInt8], checksum: UInt8) -> Bool {
        calculateChecksum(data) == checksum
    }
    
    /**
     Parses an All Dump SysEx message into a device profile.
     
     - Parameter bytes: Complete SysEx message
     - Returns: Parsed device profile
     - Throws: `MiniworksFileError` if parsing fails
     */
    private func parseAllDump(_ bytes: [UInt8]) throws -> MiniworksDeviceProfile {
        // Validate checksum
        let payload = Array(bytes[5..<(bytes.count - 2)])
        let checksumByte = bytes[bytes.count - 2]
        
        guard validateChecksum(payload, checksum: checksumByte) else {
            throw MiniworksFileError.checksumMismatch
        }
        
        // Extract device ID
//        let deviceID = bytes[3]
        
        // Parse programs (20 programs, 29 bytes each = 580 bytes)
        var programs: [MiniWorksProgram] = []
        for i in 0..<20 {
            let startIndex = 5 + (i * 29)
            let endIndex = startIndex + 29
            let programBytes = Array(bytes[startIndex..<endIndex])
            let program = MiniWorksProgram(bytes: programBytes, number: UInt8(i + 1))
            programs.append(program)
        }
        
        // Parse global data (bytes 585-590)
        let globalBytes = Array(bytes[585...590])
        let globals = MiniWorksGlobalData(globalbytes: globalBytes)
        
        // Create device profile
        let profile = MiniworksDeviceProfile(
            id: Date(),
            programs: programs,
            globals: globals
        )
        
        return profile
    }
    
    /**
     Parses a Program Dump SysEx message into a program.
     
     - Parameter bytes: Complete SysEx message
     - Returns: Parsed program
     - Throws: `MiniworksFileError` if parsing fails
     */
    private func parseProgramDump(_ bytes: [UInt8]) throws -> MiniWorksProgram {
        // Validate checksum
        let payload = Array(bytes[5..<(bytes.count - 2)])
        let checksumByte = bytes[bytes.count - 2]
        
        guard validateChecksum(payload, checksum: checksumByte) else {
            throw MiniworksFileError.checksumMismatch
        }
        
        // Parse program
        if let program = try MiniWorksProgram(bytes: bytes) {
            return program
        }
        else {
            throw MiniworksFileError.decodingFailed
        }
    }
    
    /**
     Logs file operations for debugging and audit trails.
     
     - Parameter message: Message to log
     */
    private func logOperation(_ message: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logMessage = "[\(timestamp)] \(message)"
        
        // Print to console
        print(logMessage)
        
        // Optionally write to log file
        Task {
            do {
                let logFile = try FileManagerPaths.logsDirectory
                    .appendingPathComponent("operations.log")
                
                if let data = (logMessage + "\n").data(using: .utf8) {
                    if fileManager.fileExists(atPath: logFile.path) {
                        let fileHandle = try FileHandle(forWritingTo: logFile)
                        fileHandle.seekToEndOfFile()
                        fileHandle.write(data)
                        try fileHandle.close()
                    } else {
                        try data.write(to: logFile)
                    }
                }
            } catch {
                print("Failed to write to log file: \(error)")
            }
        }
    }
}

// MARK: - Helper Extensions

extension Data {
    var hexString: String {
        map { String(format: "%02X", $0) }.joined(separator: " ")
    }
}
