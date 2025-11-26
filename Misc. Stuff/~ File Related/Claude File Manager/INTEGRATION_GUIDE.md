# Complete Integration Guide

This guide shows how to integrate the File Manager system and UI into your Miniworks MIDI editor application.

## Complete File List

### Core File Manager System
1. **MiniworksFileManager.swift** - Main file operations
2. **MiniworksFileManager+Codable.swift** - JSON serialization
3. **MiniworksFileManager+Examples.swift** - Usage examples
4. **README_FileManager.md** - File manager documentation

### UI Components
5. **FileManagerView.swift** - Main UI container
6. **FileManagerViewModel.swift** - State management
7. **ProfilesTabView.swift** - Profile management UI
8. **ProgramsTabView.swift** - Program management UI
9. **SysExTabView.swift** - SysEx import/export UI
10. **BackupsTabView.swift** - Backup management UI
11. **UI_DOCUMENTATION.md** - UI system documentation

## Step-by-Step Integration

### Step 1: Add Files to Your Project

```
YourProject/
├── FileManager/
│   ├── Core/
│   │   ├── MiniworksFileManager.swift
│   │   └── MiniworksFileManager+Codable.swift
│   └── UI/
│       ├── FileManagerView.swift
│       ├── FileManagerViewModel.swift
│       ├── ProfilesTabView.swift
│       ├── ProgramsTabView.swift
│       ├── SysExTabView.swift
│       └── BackupsTabView.swift
```

### Step 2: Update Your App Structure

```swift
import SwiftUI

@main
struct MiniworksEditorApp: App {
    // Global device profile state
    @State private var deviceProfile = MiniworksDeviceProfile.newMachineConfiguration()
    
    // Show/hide file manager
    @State private var showingFileManager = false
    
    var body: some Scene {
        WindowGroup {
            MainEditorView(deviceProfile: $deviceProfile)
                .sheet(isPresented: $showingFileManager) {
                    FileManagerView(deviceProfile: $deviceProfile)
                        .frame(minWidth: 900, minHeight: 600)
                }
        }
        .commands {
            // Add File Manager to menu bar
            fileManagerCommands
        }
    }
    
    // MARK: - Commands
    
    private var fileManagerCommands: some Commands {
        CommandMenu("File Manager") {
            Button("Open File Manager...") {
                showingFileManager = true
            }
            .keyboardShortcut("m", modifiers: [.command, .shift])
            
            Divider()
            
            Button("Quick Save") {
                Task {
                    await quickSave()
                }
            }
            .keyboardShortcut("s", modifiers: [.command])
            
            Button("Create Backup") {
                Task {
                    await createBackup()
                }
            }
            .keyboardShortcut("b", modifiers: [.command, .shift])
        }
    }
    
    // MARK: - Quick Actions
    
    private func quickSave() async {
        let fileManager = MiniworksFileManager.shared
        let name = "QuickSave_\(Date().timeIntervalSince1970)"
        try? await fileManager.saveProfile(deviceProfile, name: name)
    }
    
    private func createBackup() async {
        let fileManager = MiniworksFileManager.shared
        try? await fileManager.createBackup(of: deviceProfile)
    }
}
```

### Step 3: Add File Manager Button to Your Main UI

```swift
struct MainEditorView: View {
    @Binding var deviceProfile: MiniworksDeviceProfile
    @State private var showingFileManager = false
    
    var body: some View {
        VStack {
            // Your main editor UI
            EditorControlsView(profile: $deviceProfile)
            
            // Add file manager button to toolbar
            Spacer()
            
            HStack {
                Spacer()
                
                Button {
                    showingFileManager = true
                } label: {
                    Label("File Manager", systemImage: "folder")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .sheet(isPresented: $showingFileManager) {
            FileManagerView(deviceProfile: $deviceProfile)
        }
    }
}
```

### Step 4: Add Auto-Save to Your Editor

```swift
@Observable
class EditorViewModel {
    var deviceProfile: MiniworksDeviceProfile
    private var autoSaveTimer: Timer?
    
    init(profile: MiniworksDeviceProfile) {
        self.deviceProfile = profile
        startAutoSave()
    }
    
    deinit {
        stopAutoSave()
    }
    
    private func startAutoSave() {
        autoSaveTimer = Timer.scheduledTimer(
            withTimeInterval: 300, // 5 minutes
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.performAutoSave()
            }
        }
    }
    
    private func stopAutoSave() {
        autoSaveTimer?.invalidate()
    }
    
    private func performAutoSave() async {
        let fileManager = MiniworksFileManager.shared
        let name = "AutoSave_\(Date().timeIntervalSince1970)"
        try? await fileManager.saveProfile(deviceProfile, name: name)
    }
}
```

### Step 5: Handle MIDI Parameter Changes

```swift
extension EditorViewModel {
    // When parameters change via MIDI
    func handleMIDIParameterChange(cc: UInt8, value: UInt8, channel: UInt8) {
        // Update the device profile
        let program = deviceProfile.program(number: Int(currentProgramNumber))
        program.updateFromCC(cc, value: value, onChannel: channel)
        
        // Mark as having unsaved changes
        hasUnsavedChanges = true
    }
    
    // When user changes parameters in UI
    func parameterDidChange(_ parameter: ProgramParameter) {
        hasUnsavedChanges = true
        
        // Optionally send to hardware
        if autoSendToHardware {
            sendParameterToHardware(parameter)
        }
    }
}
```

### Step 6: Integrate SysEx Import with Your MIDI System

```swift
class MIDIManager: ObservableObject {
    @Published var deviceProfile: MiniworksDeviceProfile
    private let fileManager = MiniworksFileManager.shared
    
    // When receiving SysEx from hardware
    func handleSysExReceived(_ data: Data) {
        Task { @MainActor in
            // Save received SysEx to temp file
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("received_\(Date().timeIntervalSince1970).syx")
            
            try? data.write(to: tempURL)
            
            // Import it
            if let result = try? await fileManager.importSysExFile(from: tempURL) {
                if let profile = result as? MiniworksDeviceProfile {
                    deviceProfile = profile
                }
            }
            
            // Clean up
            try? FileManager.default.removeItem(at: tempURL)
        }
    }
    
    // Send SysEx to hardware
    func sendProfileToHardware(_ profile: MiniworksDeviceProfile) async {
        // Export as SysEx
        if let url = try? await fileManager.exportProfileAsSysEx(
            profile,
            name: "HardwareTransfer"
        ) {
            // Read the file
            if let data = try? Data(contentsOf: url) {
                // Send via your MIDI output
                sendMIDISysEx(data)
            }
        }
    }
}
```

## Complete Usage Examples

### Example 1: Simple Integration

Minimal integration for basic save/load:

```swift
struct SimpleEditorApp: App {
    @State private var profile = MiniworksDeviceProfile.newMachineConfiguration()
    
    var body: some Scene {
        WindowGroup {
            VStack {
                // Your editor
                Text("Miniworks Editor")
                
                // File manager button
                Button("File Manager") {
                    NSApp.sendAction(#selector(showFileManager), to: nil, from: nil)
                }
            }
        }
        .commands {
            CommandGroup(replacing: .saveItem) {
                Button("Save Profile...") {
                    Task {
                        let fm = MiniworksFileManager.shared
                        try? await fm.saveProfile(profile, name: "MyProfile")
                    }
                }
                .keyboardShortcut("s")
            }
        }
    }
}
```

### Example 2: Full-Featured Integration

Complete integration with all features:

```swift
@main
struct FullFeaturedApp: App {
    @State private var deviceProfile = MiniworksDeviceProfile.newMachineConfiguration()
    @State private var showingFileManager = false
    @State private var midiManager: MIDIManager
    
    init() {
        let profile = MiniworksDeviceProfile.newMachineConfiguration()
        _deviceProfile = State(initialValue: profile)
        _midiManager = State(initialValue: MIDIManager(profile: profile))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(
                deviceProfile: $deviceProfile,
                midiManager: midiManager
            )
            .sheet(isPresented: $showingFileManager) {
                FileManagerView(deviceProfile: $deviceProfile)
            }
            .onAppear {
                loadLastSession()
            }
            .onDisappear {
                saveSession()
            }
        }
        .commands {
            fileCommands
            editCommands
            hardwareCommands
        }
    }
    
    // MARK: - Commands
    
    private var fileCommands: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Profile") {
                deviceProfile = .newMachineConfiguration()
            }
            .keyboardShortcut("n")
        }
        
        CommandGroup(replacing: .saveItem) {
            Button("Save Profile...") {
                Task { await saveProfile() }
            }
            .keyboardShortcut("s")
            
            Button("Save As...") {
                showingFileManager = true
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])
        }
    }
    
    private var editCommands: some Commands {
        CommandMenu("Edit") {
            Button("Copy Program") {
                copyCurrentProgram()
            }
            .keyboardShortcut("c")
            
            Button("Paste Program") {
                pasteProgram()
            }
            .keyboardShortcut("v")
        }
    }
    
    private var hardwareCommands: some Commands {
        CommandMenu("Hardware") {
            Button("Send to Hardware") {
                Task {
                    await midiManager.sendProfileToHardware(deviceProfile)
                }
            }
            .keyboardShortcut("h", modifiers: [.command, .shift])
            
            Button("Receive from Hardware") {
                midiManager.requestDumpFromHardware()
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])
        }
    }
    
    // MARK: - Session Management
    
    private func loadLastSession() {
        Task {
            let fm = MiniworksFileManager.shared
            if let profiles = try? await fm.listProfiles(),
               let lastProfile = profiles.first {
                deviceProfile = try await fm.loadProfile(named: lastProfile)
            }
        }
    }
    
    private func saveSession() {
        Task {
            let fm = MiniworksFileManager.shared
            try? await fm.saveProfile(deviceProfile, name: "LastSession")
        }
    }
    
    private func saveProfile() async {
        // Show save dialog implementation
    }
    
    private func copyCurrentProgram() {
        // Copy implementation
    }
    
    private func pasteProgram() {
        // Paste implementation
    }
}
```

### Example 3: Program Library Browser

Standalone program browser:

```swift
struct ProgramLibraryView: View {
    @State private var viewModel = FileManagerViewModel(
        currentProfile: .newMachineConfiguration()
    )
    @State private var selectedProgram: MiniWorksProgram?
    
    var body: some View {
        NavigationSplitView {
            // Program list
            List(viewModel.availablePrograms) { metadata in
                Button {
                    loadProgram(metadata)
                } label: {
                    HStack {
                        Image(systemName: "music.note")
                        Text(metadata.name)
                    }
                }
            }
            .task {
                await viewModel.refreshProgramsList()
            }
        } detail: {
            // Program details
            if let program = selectedProgram {
                ProgramDetailView(program: program)
            } else {
                Text("Select a program")
            }
        }
    }
    
    private func loadProgram(_ metadata: ProgramMetadata) {
        Task {
            selectedProgram = await viewModel.loadProgram(named: metadata.name)
        }
    }
}
```

## Testing Your Integration

### Test Checklist

- [ ] Save profile from main editor
- [ ] Load profile and verify all parameters
- [ ] Export profile as SysEx
- [ ] Import SysEx file
- [ ] Save individual program
- [ ] Load program into device slot
- [ ] Create manual backup
- [ ] Restore from backup
- [ ] Auto-save triggers after edits
- [ ] Search and sort work correctly
- [ ] Keyboard shortcuts work
- [ ] Error messages display properly
- [ ] Loading indicators appear
- [ ] Success messages show

### Debug Helpers

```swift
// Add to your view model for debugging
extension FileManagerViewModel {
    func printState() {
        print("""
        === File Manager State ===
        Profiles: \(availableProfiles.count)
        Programs: \(availablePrograms.count)
        Backups: \(availableBackups.count)
        Loading: \(isLoading)
        Has Changes: \(hasUnsavedChanges)
        Error: \(errorMessage ?? "none")
        =========================
        """)
    }
}

// Call when debugging
Button("Debug State") {
    viewModel.printState()
}
```

## Performance Tips

### 1. Lazy Load Large Lists

```swift
List {
    ForEach(viewModel.availableProfiles.prefix(50)) { profile in
        ProfileRow(profile: profile)
    }
    
    if viewModel.availableProfiles.count > 50 {
        Button("Load More") {
            // Load next batch
        }
    }
}
```

### 2. Debounce Search

```swift
.onChange(of: searchText) { old, new in
    Task {
        try? await Task.sleep(for: .milliseconds(300))
        if searchText == new {
            await performSearch(new)
        }
    }
}
```

### 3. Cache File Metadata

```swift
class FileManagerViewModel {
    private var metadataCache: [String: ProfileMetadata] = [:]
    
    func getMetadata(for name: String) async -> ProfileMetadata? {
        if let cached = metadataCache[name] {
            return cached
        }
        
        if let fresh = await fetchMetadata(name) {
            metadataCache[name] = fresh
            return fresh
        }
        
        return nil
    }
}
```

## Common Issues and Solutions

### Issue: Files Not Saving

**Problem**: Save appears to work but files don't appear

**Solution**: Check App Sandbox permissions

```swift
// In your .entitlements file:
<key>com.apple.security.files.user-selected.read-write</key>
<true/>
<key>com.apple.security.application-groups</key>
<array>
    <string>YOUR_GROUP_ID</string>
</array>
```

### Issue: SysEx Import Fails

**Problem**: Import shows error or corrupts data

**Solution**: Validate data before importing

```swift
func validateSysExData(_ data: Data) -> Bool {
    let bytes = [UInt8](data)
    
    // Check start/end bytes
    guard bytes.first == 0xF0, bytes.last == 0xF7 else {
        return false
    }
    
    // Check manufacturer ID
    guard bytes[1] == 0x3E else {
        return false
    }
    
    // Check model ID
    guard bytes[2] == 0x04 else {
        return false
    }
    
    return true
}
```

### Issue: UI Not Updating

**Problem**: Changes don't reflect in UI

**Solution**: Ensure proper observation

```swift
// Use @Bindable for Observable classes
@Bindable var viewModel: FileManagerViewModel

// Or @State for creating instances
@State var viewModel = FileManagerViewModel()
```

## Next Steps

1. **Customize Theme**: Update colors and styling in `FileManagerTheme`
2. **Add Features**: Extend with your specific requirements
3. **Test Thoroughly**: Use the test checklist above
4. **Add Analytics**: Track usage patterns
5. **User Feedback**: Collect feedback and iterate

## Additional Resources

- **MiniworksFileManager.swift**: Core file operations documentation
- **UI_DOCUMENTATION.md**: Detailed UI customization guide  
- **README_FileManager.md**: File format specifications
- **MiniworksFileManager+Examples.swift**: More usage examples

## Support

For questions or issues:
1. Check the documentation files
2. Review the example code
3. Test with mock data
4. Check console logs for errors

---

**Version**: 1.0  
**Last Updated**: November 25, 2025  
**Compatibility**: macOS 14.0+, Swift 5.9+
