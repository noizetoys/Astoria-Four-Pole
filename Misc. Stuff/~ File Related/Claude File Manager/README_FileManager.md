# Miniworks File Manager System

A comprehensive file management system for MIDI synthesizer editors that provides JSON persistence and SysEx import/export functionality.

## Overview

This system handles all file operations for the Miniworks MIDI editor, including:

- **JSON Persistence**: Save and load device profiles and individual programs
- **SysEx Export**: Export data as standard MIDI SysEx files for hardware transfer
- **SysEx Import**: Import SysEx files from hardware or file sharing
- **Backup Management**: Automatic timestamped backups
- **Factory Presets**: Separate storage for read-only factory patches
- **Error Handling**: Comprehensive error recovery and validation

## Architecture

### File Structure

```
~/Library/Application Support/MiniworksEditor/
├── Profiles/              # Complete device state (20 programs + globals)
│   ├── My_Setup.json
│   ├── Live_Performance.json
│   └── backup_20251125_103000.json
├── Programs/              # Individual program patches
│   ├── Bass_Patch.json
│   ├── Lead_Sound.json
│   └── Factory/          # Read-only factory presets
│       ├── Factory_Bass.json
│       └── Factory_Pad.json
├── SysEx/                 # Exported SysEx files
│   ├── Profiles/
│   │   └── My_Setup.syx
│   └── Programs/
│       └── Bass_Patch.syx
└── Logs/                  # Operation logs
    └── operations.log
```

### Component Files

1. **MiniworksFileManager.swift**
   - Main file manager class
   - Directory management
   - JSON save/load operations
   - SysEx import/export
   - Checksum validation
   - Error handling

2. **MiniworksFileManager+Codable.swift**
   - Codable wrapper structures
   - JSON serialization
   - Type-safe data conversion
   - Version management
   - Migration support

3. **MiniworksFileManager+Examples.swift**
   - Usage examples
   - SwiftUI integration patterns
   - Error handling patterns
   - Testing utilities
   - Adaptation guide

## Quick Start

### Basic Setup

```swift
// Create shared instance
let fileManager = MiniworksFileManager.shared

// Or create custom instance
let fileManager = MiniworksFileManager()
```

### Save a Device Profile

```swift
let profile = MiniworksDeviceProfile.newMachineConfiguration()

Task {
    try await fileManager.saveProfile(profile, name: "My Setup")
}
```

### Load a Device Profile

```swift
Task {
    let profile = try await fileManager.loadProfile(named: "My Setup")
    // Use the loaded profile
}
```

### Export as SysEx

```swift
Task {
    let url = try await fileManager.exportProfileAsSysEx(
        profile,
        name: "Hardware_Backup"
    )
    print("Exported to: \(url.path)")
}
```

### Import SysEx File

```swift
Task {
    let result = try await fileManager.importSysExFile(from: fileURL)
    
    if let profile = result as? MiniworksDeviceProfile {
        // Handle imported profile
    }
    else if let program = result as? MiniWorksProgram {
        // Handle imported program
    }
}
```

## JSON Format

### Device Profile

```json
{
  "version": "1.0",
  "savedAt": "2025-11-25T10:30:00Z",
  "profileName": "My Setup",
  "programs": [
    {
      "programNumber": 1,
      "programName": "Bass Patch",
      "vcfEnvelopeAttack": 0,
      "vcfEnvelopeDecay": 64,
      "cutoff": 80,
      "resonance": 60,
      ...
    }
  ],
  "globalSettings": {
    "midiChannel": 1,
    "deviceID": 0,
    "noteNumber": 60,
    ...
  }
}
```

### Individual Program

```json
{
  "version": "1.0",
  "savedAt": "2025-11-25T10:30:00Z",
  "program": {
    "programNumber": 1,
    "programName": "Lead Sound",
    "tags": [
      {
        "title": "Lead",
        "backgroundColorHex": "#FF5733",
        "textColorHex": "#FFFFFF"
      }
    ],
    "vcfEnvelopeAttack": 0,
    "vcfEnvelopeDecay": 64,
    ...
  }
}
```

## SysEx Format

### Device Profile (All Dump)

```
Byte 0:     0xF0 (Start of SysEx)
Byte 1:     0x3E (Waldorf ID)
Byte 2:     0x04 (Miniworks ID)
Byte 3:     Device ID (0-126, user settable)
Byte 4:     0x08 (All Dump message type)
Bytes 5-584: Program data (20 programs × 29 bytes)
Bytes 585-590: Global settings (6 bytes)
Byte 591:   Checksum
Byte 592:   0xF7 (End of SysEx)

Total: 593 bytes
```

### Single Program Dump

```
Byte 0:     0xF0 (Start of SysEx)
Byte 1:     0x3E (Waldorf ID)
Byte 2:     0x04 (Miniworks ID)
Byte 3:     Device ID
Byte 4:     0x00 (Program Dump message type)
Byte 5:     Program number (1-20)
Bytes 6-34: Parameter data (29 bytes)
Byte 35:    Checksum
Byte 36:    0xF7 (End of SysEx)

Total: 37 bytes
```

## SwiftUI Integration

### View Model Pattern

```swift
@MainActor
@Observable
class DocumentManagerViewModel {
    private let fileManager = MiniworksFileManager.shared
    
    var currentProfile: MiniworksDeviceProfile?
    var availableProfiles: [String] = []
    var isLoading = false
    var errorMessage: String?
    
    func saveProfile(named name: String) async {
        guard let profile = currentProfile else { return }
        isLoading = true
        
        do {
            try await fileManager.saveProfile(profile, name: name)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
```

### Example View

```swift
struct ProfileManagerView: View {
    @State private var viewModel = DocumentManagerViewModel()
    
    var body: some View {
        VStack {
            List(viewModel.availableProfiles, id: \.self) { name in
                ProfileRow(name: name)
            }
            
            Button("Save Current") {
                Task {
                    await viewModel.saveProfile(named: "My Setup")
                }
            }
        }
        .task {
            await viewModel.refreshLists()
        }
    }
}
```

## Error Handling

### Error Types

```swift
enum MiniworksFileError: LocalizedError {
    case invalidPath
    case fileNotFound(String)
    case invalidJSON
    case invalidSysEx
    case encodingFailed
    case decodingFailed
    case writePermissionDenied
    case checksumMismatch
    case directoryCreationFailed
}
```

### Handling Errors

```swift
do {
    try await fileManager.saveProfile(profile, name: name)
} catch MiniworksFileError.writePermissionDenied {
    // Show permission error to user
} catch MiniworksFileError.invalidPath {
    // Recreate directory structure
    try await fileManager.createDirectoryStructure()
} catch {
    // Handle unexpected errors
    print("Error: \(error.localizedDescription)")
}
```

## Backup Management

### Manual Backup

```swift
Task {
    let backupURL = try await fileManager.createBackup(of: profile)
    print("Backup created: \(backupURL.lastPathComponent)")
}
```

### Automatic Backups

```swift
class BackupManager {
    func startAutomaticBackups(
        profile: MiniworksDeviceProfile,
        intervalMinutes: Int = 30
    ) {
        Timer.scheduledTimer(withTimeInterval: TimeInterval(intervalMinutes * 60), 
                             repeats: true) { _ in
            Task {
                try? await fileManager.createBackup(of: profile)
            }
        }
    }
}
```

### List and Restore Backups

```swift
Task {
    let backups = try await fileManager.listBackups()
    
    for backup in backups {
        print("\(backup.name) - \(backup.date)")
    }
    
    // Restore most recent
    if let latest = backups.first {
        let profile = try await fileManager.loadProfile(named: latest.name)
    }
}
```

## Customization Guide

### Adapting for Different Synthesizers

#### 1. Update SysEx Constants

```swift
enum YourSynthSysExFormat {
    static let startByte: UInt8 = 0xF0
    static let endByte: UInt8 = 0xF7
    static let manufacturerID: UInt8 = 0x??  // Your manufacturer
    static let modelID: UInt8 = 0x??          // Your model
    
    static let programDump: UInt8 = 0x??
    static let allDump: UInt8 = 0x??
}
```

#### 2. Modify Checksum Algorithm

Different manufacturers use different checksums:

**Waldorf/Roland (7-bit sum):**
```swift
private func calculateChecksum(_ data: [UInt8]) -> UInt8 {
    let sum = data.reduce(0) { $0 + Int($1) }
    return UInt8(sum & 0x7F)
}
```

**Two's Complement:**
```swift
private func calculateChecksum(_ data: [UInt8]) -> UInt8 {
    let sum = data.reduce(0) { $0 + Int($1) }
    return UInt8((128 - (sum & 0x7F)) & 0x7F)
}
```

**XOR Checksum:**
```swift
private func calculateChecksum(_ data: [UInt8]) -> UInt8 {
    return data.reduce(0) { $0 ^ $1 }
}
```

#### 3. Update Byte Positions

Modify `parseAllDump()` and `parseProgramDump()` to match your device's structure:

```swift
private func parseYourSynthDump(_ bytes: [UInt8]) throws -> YourSynthProfile {
    // Extract data based on your device's specification
    let programData = Array(bytes[YOUR_START...YOUR_END])
    
    // Parse according to your format
    ...
}
```

#### 4. Create Custom Codable Wrappers

```swift
struct YourSynthProgramCodable: Codable {
    // Add your synth's parameters
    let oscillator1Waveform: UInt8
    let oscillator2Pitch: UInt8
    let filterCutoff: UInt8
    ...
    
    init(program: YourSynthProgram) {
        self.oscillator1Waveform = program.osc1Waveform.value
        ...
    }
}
```

#### 5. Update Directory Structure

```swift
struct FileManagerPaths {
    static let bundleIdentifier = "com.yourcompany.YourSynthEditor"
    
    // Customize directory names as needed
    static var patchesDirectory: URL {
        get throws {
            try applicationSupport.appendingPathComponent("Patches")
        }
    }
}
```

## Testing

### Directory Structure Test

```swift
Task {
    let tester = FileManagerTests()
    await tester.testDirectoryStructure()
}
```

### Round-Trip Test

```swift
Task {
    let tester = FileManagerTests()
    let profile = MiniworksDeviceProfile.newMachineConfiguration()
    await tester.testRoundTrip(profile)
}
```

### Output:
```
✅ Save completed
✅ Load completed
✅ Data integrity verified
✅ Cleanup completed
```

## Best Practices

### 1. Use Async/Await

All file operations should be called from async contexts:

```swift
Task {
    await fileManager.saveProfile(profile, name: "My Setup")
}
```

### 2. Handle Errors Gracefully

Always wrap file operations in do-catch blocks:

```swift
do {
    try await fileManager.saveProfile(profile, name: name)
} catch {
    // Show user-friendly error message
    showAlert("Failed to save: \(error.localizedDescription)")
}
```

### 3. Validate Before Operations

Check file existence and format before importing:

```swift
guard FileManager.default.fileExists(atPath: url.path),
      url.pathExtension == "syx" else {
    throw MiniworksFileError.invalidPath
}
```

### 4. Use Sanitized Filenames

The file manager automatically sanitizes filenames, but you can provide clean names:

```swift
// Good
await fileManager.saveProfile(profile, name: "My Setup")

// Avoid special characters (will be cleaned automatically)
await fileManager.saveProfile(profile, name: "My/Setup:With*Chars")
// Saved as: "My_Setup_With_Chars.json"
```

### 5. Create Regular Backups

Implement automatic backups for important data:

```swift
let backupManager = BackupManager()
backupManager.startAutomaticBackups(profile: currentProfile, intervalMinutes: 30)
```

## Performance Considerations

### Async Operations

All file operations are asynchronous and run off the main thread, preventing UI blocking.

### Memory Efficiency

Large device profiles are streamed rather than loaded entirely into memory when possible.

### Caching

Consider implementing caching for frequently accessed profiles:

```swift
class CachedFileManager {
    private var profileCache: [String: MiniworksDeviceProfile] = [:]
    private let fileManager = MiniworksFileManager.shared
    
    func loadProfile(named name: String) async throws -> MiniworksDeviceProfile {
        if let cached = profileCache[name] {
            return cached
        }
        
        let profile = try await fileManager.loadProfile(named: name)
        profileCache[name] = profile
        return profile
    }
}
```

## Troubleshooting

### "Permission Denied" Errors

Ensure your app has appropriate file system access:

```swift
// Request permission if needed
if !FileManager.default.isWritableFile(atPath: directory.path) {
    // Show permission request dialog
}
```

### "Invalid SysEx" Errors

Verify:
1. File is a valid SysEx file (.syx extension)
2. File contains correct manufacturer/model IDs
3. Checksum is valid
4. File isn't corrupted

### "Directory Not Found" Errors

Recreate directory structure:

```swift
try await fileManager.createDirectoryStructure()
```

### JSON Decode Errors

Check for version compatibility:

```swift
let wrapper = try jsonDecoder.decode(DeviceProfileWrapper.self, from: data)

if wrapper.version != "1.0" {
    // Handle version migration
    let migrator = FileFormatMigrator()
    let migratedData = try migrator.migrate(data, from: wrapper.version, to: "1.0")
}
```

## Version History

### v1.0 (Current)
- Initial release
- JSON persistence for profiles and programs
- SysEx import/export
- Automatic backups
- Factory preset support
- Comprehensive error handling

## License

[Your license here]

## Contributing

[Your contribution guidelines here]

## Support

For questions and issues:
- GitHub Issues: [Your repo]
- Email: [Your email]
- Documentation: [Your docs URL]
