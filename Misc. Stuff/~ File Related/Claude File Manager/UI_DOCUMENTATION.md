# File Manager UI System Documentation

Complete SwiftUI interface for the Miniworks File Manager system.

## Overview

This UI system provides a professional, user-friendly interface for managing device profiles, programs, SysEx files, and backups. Built with SwiftUI for macOS, it features:

- **Modern Design**: Native macOS appearance with hover effects and animations
- **Intuitive Navigation**: Tab-based interface with clear organization
- **Drag & Drop**: Support for SysEx file import
- **Real-time Feedback**: Loading states, success/error messages
- **Keyboard Shortcuts**: Standard macOS shortcuts for common actions
- **Accessibility**: Proper labels and help text throughout

## Architecture

### Component Hierarchy

```
FileManagerView (Main Container)
├── NavigationSplitView
│   ├── Sidebar
│   │   ├── Tab Navigation
│   │   ├── Quick Actions
│   │   └── Status Indicators
│   └── Detail View (TabView)
│       ├── ProfilesTabView
│       ├── ProgramsTabView
│       ├── SysExTabView
│       └── BackupsTabView
└── FileManagerViewModel (State Management)
```

### File Structure

1. **FileManagerView.swift** - Main container and navigation
2. **FileManagerViewModel.swift** - State management and business logic
3. **ProfilesTabView.swift** - Device profile management
4. **ProgramsTabView.swift** - Individual program management
5. **SysExTabView.swift** - Import/export operations
6. **BackupsTabView.swift** - Backup management

## Quick Start

### Basic Integration

```swift
import SwiftUI

struct ContentView: View {
    @State private var deviceProfile = MiniworksDeviceProfile.newMachineConfiguration()
    
    var body: some View {
        FileManagerView(deviceProfile: $deviceProfile)
            .frame(minWidth: 900, minHeight: 600)
    }
}
```

### Opening as Sheet/Window

```swift
// As a sheet
.sheet(isPresented: $showingFileManager) {
    FileManagerView(deviceProfile: $deviceProfile)
        .frame(width: 900, height: 600)
}

// As a new window
Button("Open File Manager") {
    let window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 900, height: 600),
        styleMask: [.titled, .closable, .miniaturizable, .resizable],
        backing: .buffered,
        defer: false
    )
    window.center()
    window.contentView = NSHostingView(
        rootView: FileManagerView(deviceProfile: $deviceProfile)
    )
    window.makeKeyAndOrderFront(nil)
}
```

## Customization Guide

### Theme Customization

All visual properties are centralized in `FileManagerTheme`:

```swift
struct FileManagerTheme {
    // Colors
    static let accentColor = Color.blue          // Change to your brand color
    static let destructiveColor = Color.red
    static let successColor = Color.green
    
    // Spacing
    static let smallSpacing: CGFloat = 8
    static let mediumSpacing: CGFloat = 16
    static let largeSpacing: CGFloat = 24
    
    // Sizing
    static let cardCornerRadius: CGFloat = 8
    static let buttonHeight: CGFloat = 32
    static let iconSize: CGFloat = 20
    
    // Typography
    static let titleFont = Font.headline
    static let bodyFont = Font.body
    static let captionFont = Font.caption
}
```

### Custom Brand Colors

```swift
struct FileManagerTheme {
    // Example: Purple theme
    static let accentColor = Color(red: 0.5, green: 0.2, blue: 0.8)
    static let secondaryAccent = Color(red: 0.7, green: 0.4, blue: 0.9)
    
    // Example: Using asset catalog colors
    static let accentColor = Color("BrandPrimary")
    static let destructiveColor = Color("BrandDanger")
}
```

### Adding Custom Actions

#### To Profiles Tab

```swift
// In ProfilesTabView.swift, add to ProfileRow:
Button {
    onCustomAction()
} label: {
    Label("Custom", systemImage: "star")
        .labelStyle(.iconOnly)
}
.buttonStyle(.borderless)
.help("Your custom action")
```

#### To Programs Tab

```swift
// In ProgramsTabView.swift, add to DeviceSlotCard:
Button {
    onAnalyze()
} label: {
    Image(systemName: "waveform.path.ecg")
}
.buttonStyle(.borderless)
.help("Analyze program")
```

### Modifying Layouts

#### Grid Columns

```swift
// In ProgramsTabView.swift, modify grid:
LazyVGrid(
    columns: [
        GridItem(.adaptive(
            minimum: 250,    // Increase for wider cards
            maximum: 300     // Increase for wider cards
        ), spacing: 20)      // Adjust spacing
    ],
    spacing: 20
) {
    // Content
}
```

#### List Spacing

```swift
// In ProfilesTabView.swift:
LazyVStack(spacing: 12) {  // Adjust spacing
    ForEach(profiles) { profile in
        ProfileRow(profile: profile)
            .padding(.vertical, 8)  // Adjust row padding
    }
}
```

## Features Deep Dive

### Profiles Tab

**Purpose**: Manage complete device configurations

**Key Features**:
- Search and sort profiles
- Save with custom names and timestamps
- Load with unsaved changes warning
- Delete with confirmation
- Export to SysEx

**Customization Points**:

```swift
// Add custom sort options
enum ProfileSortOrder {
    case nameAscending
    case nameDescending
    case dateAscending
    case dateDescending
    case custom           // Add your custom sort
}

// Add custom metadata display
struct ProfileRow {
    // Add custom badges:
    if profile.hasCustomTag {
        Text("★")
            .foregroundColor(.yellow)
    }
}
```

### Programs Tab

**Purpose**: Manage individual patches

**Key Features**:
- Three view modes: Library, Device Slots, Factory
- Grid-based browsing
- Drag program cards
- Save from device slots
- Import to specific slots
- Export individual programs

**Customization Points**:

```swift
// Add program preview
struct ProgramCard {
    // Add parameter preview:
    VStack {
        HStack {
            Label("Cutoff: \(program.cutoff.value)", systemImage: "slider.horizontal.3")
            Label("Resonance: \(program.resonance.value)", systemImage: "waveform")
        }
        .font(.caption2)
    }
}

// Add filtering
@State private var filterType: ProgramFilter = .all

enum ProgramFilter {
    case all
    case bass
    case lead
    case pad
    // Add custom filters
}
```

### SysEx Tab

**Purpose**: Import and export SysEx files

**Key Features**:
- Split view: Export | Import
- Drag and drop support
- File browser integration
- Export options sheet
- Hardware transfer instructions

**Customization Points**:

```swift
// Customize transfer instructions
private func instructionsCard() -> some View {
    // Update steps for your hardware:
    steps: [
        "Connect your synthesizer via MIDI",
        "Open SysEx Librarian (or your MIDI utility)",
        "Select the exported .syx file",
        "Send to MIDI channel \(deviceProfile.midiChannel)",
        "Wait for transfer complete message"
    ]
}

// Add validation warnings
if fileSize > expectedSize {
    HStack {
        Image(systemName: "exclamationmark.triangle")
        Text("File size seems unusual")
    }
    .foregroundColor(.orange)
}
```

### Backups Tab

**Purpose**: Manage automatic and manual backups

**Key Features**:
- Organized by time period (Recent, This Week, Older)
- Restore with confirmation
- Manual backup creation
- Auto-cleanup of old backups
- Storage usage display

**Customization Points**:

```swift
// Adjust time periods
private var recentBackups: [BackupMetadata] {
    let cutoff = Calendar.current.date(
        byAdding: .hour, 
        value: -12,     // Change from 24 hours
        to: Date()
    ) ?? Date()
    return backups.filter { $0.date >= cutoff }
}

// Add backup categories
enum BackupCategory {
    case automatic
    case manual
    case beforeUpdate
    case milestone
}

// Customize retention
private let maxBackupsToKeep = 20  // Increase/decrease
```

## State Management

### ViewModel Architecture

The `FileManagerViewModel` uses Swift's `@Observable` macro for reactive state:

```swift
@MainActor
@Observable
class FileManagerViewModel {
    // Public state
    private(set) var currentProfile: MiniworksDeviceProfile
    private(set) var availableProfiles: [ProfileMetadata]
    private(set) var isLoading: Bool
    private(set) var errorMessage: String?
    
    // User selections
    var selectedProfile: ProfileMetadata?
    var selectedProgram: ProgramMetadata?
}
```

### Accessing State in Views

```swift
struct MyCustomView: View {
    @Bindable var viewModel: FileManagerViewModel
    
    var body: some View {
        List(viewModel.availableProfiles) { profile in
            Text(profile.name)
        }
        .opacity(viewModel.isLoading ? 0.5 : 1.0)
    }
}
```

### Custom Actions

```swift
// Add to FileManagerViewModel
func customOperation() async {
    isLoading = true
    defer { isLoading = false }
    
    do {
        // Your custom logic
        try await fileManager.customMethod()
        showSuccess("Operation completed")
    } catch {
        showError("Operation failed: \(error.localizedDescription)")
    }
}

// Call from view
Button("Custom Action") {
    Task {
        await viewModel.customOperation()
    }
}
```

## User Feedback

### Loading States

```swift
// Automatic loading indicators
if viewModel.isLoading {
    ProgressView()
        .scaleEffect(0.8)
}

// Custom loading with message
if viewModel.isLoading {
    HStack {
        ProgressView()
        Text("Processing...")
    }
}
```

### Error Handling

```swift
// Display errors
if let error = viewModel.errorMessage {
    HStack {
        Image(systemName: "exclamationmark.triangle.fill")
            .foregroundColor(.red)
        Text(error)
            .foregroundColor(.red)
    }
    .padding()
    .background(Color.red.opacity(0.1))
    .cornerRadius(8)
}

// Custom error presentation
.alert("Error", isPresented: $showingError) {
    Button("OK") {
        viewModel.clearMessages()
    }
} message: {
    Text(viewModel.errorMessage ?? "Unknown error")
}
```

### Success Messages

```swift
// Toast-style success
if let success = viewModel.successMessage {
    Text(success)
        .padding()
        .background(Color.green.opacity(0.2))
        .foregroundColor(.green)
        .cornerRadius(8)
        .transition(.move(edge: .top))
}
```

## Keyboard Shortcuts

Built-in shortcuts:

- **⌘S** - Save current profile
- **⌘O** - Open file browser
- **⌘B** - Create backup
- **⌘Delete** - Delete selected item
- **⌘Return** - Confirm dialogs
- **⌘.** - Cancel dialogs
- **⌘F** - Focus search field

### Adding Custom Shortcuts

```swift
.keyboardShortcut("e", modifiers: [.command])  // ⌘E
.keyboardShortcut("r", modifiers: [.command, .shift])  // ⌘⇧R

// Example: Add export shortcut
Button("Export") {
    Task {
        await viewModel.exportProfileAsSysEx()
    }
}
.keyboardShortcut("e", modifiers: [.command])
```

## Accessibility

### VoiceOver Support

All interactive elements include proper labels:

```swift
Button {
    action()
} label: {
    Image(systemName: "trash")
}
.accessibilityLabel("Delete profile")
.accessibilityHint("Permanently removes this profile")
```

### Help Text

Hover tooltips are provided throughout:

```swift
.help("This tooltip appears on hover")
```

### Focus Management

```swift
@FocusState private var isFieldFocused: Bool

TextField("Name", text: $name)
    .focused($isFieldFocused)
    .onAppear {
        isFieldFocused = true
    }
```

## Performance Optimization

### Lazy Loading

```swift
// Use lazy stacks for large lists
LazyVStack {
    ForEach(items) { item in
        ItemRow(item: item)
    }
}

// Use lazy grids for cards
LazyVGrid(columns: columns) {
    ForEach(items) { item in
        ItemCard(item: item)
    }
}
```

### Debouncing Search

```swift
@State private var searchText = ""
@State private var debouncedSearch = ""

var body: some View {
    TextField("Search", text: $searchText)
        .onChange(of: searchText) { old, new in
            Task {
                try? await Task.sleep(for: .milliseconds(300))
                if searchText == new {
                    debouncedSearch = new
                }
            }
        }
}
```

### Efficient Updates

```swift
// Use Identifiable for stable identity
struct ProfileMetadata: Identifiable {
    let id = UUID()  // Stable ID
    let name: String
    let date: Date
}

// Avoid expensive operations in body
class ViewModel {
    // Pre-compute expensive values
    var sortedProfiles: [Profile] {
        profiles.sorted()  // Computed once
    }
}
```

## Testing

### Preview Support

All views include preview providers:

```swift
#Preview("Profiles Tab") {
    struct PreviewWrapper: View {
        @State private var profile = MiniworksDeviceProfile.newMachineConfiguration()
        @State private var viewModel = FileManagerViewModel(currentProfile: profile)
        
        var body: some View {
            ProfilesTabView(deviceProfile: $profile, viewModel: viewModel)
                .frame(width: 800, height: 600)
        }
    }
    
    return PreviewWrapper()
}
```

### Mock Data

```swift
extension FileManagerViewModel {
    static func mock() -> FileManagerViewModel {
        let vm = FileManagerViewModel(
            currentProfile: .newMachineConfiguration()
        )
        
        // Add mock data
        vm.availableProfiles = [
            ProfileMetadata(name: "Test 1", modifiedDate: Date(), fileSize: 1024),
            ProfileMetadata(name: "Test 2", modifiedDate: Date(), fileSize: 2048)
        ]
        
        return vm
    }
}
```

## Common Patterns

### Confirmation Dialogs

```swift
.confirmationDialog("Title", isPresented: $showing, presenting: item) { item in
    Button("Confirm") {
        performAction(item)
    }
    Button("Cancel", role: .cancel) {}
} message: { item in
    Text("Are you sure you want to process \(item.name)?")
}
```

### Sheets with Data

```swift
.sheet(isPresented: $showingSheet, onDismiss: {
    cleanup()
}) {
    if let data = dataToShow {
        DetailView(data: data)
    }
}
```

### Hover Effects

```swift
@State private var isHovered = false

SomeView()
    .scaleEffect(isHovered ? 1.05 : 1.0)
    .animation(.easeInOut(duration: 0.2), value: isHovered)
    .onHover { hovering in
        isHovered = hovering
    }
```

## Troubleshooting

### View Not Updating

**Problem**: Changes to data don't update the UI

**Solution**: Ensure proper use of `@Bindable` or `@State`:

```swift
// Correct
@Bindable var viewModel: FileManagerViewModel

// Also correct for @Observable classes
@State var viewModel = FileManagerViewModel()
```

### Memory Issues

**Problem**: Memory usage grows over time

**Solution**: Use weak references and cleanup:

```swift
deinit {
    // Cleanup timers, observers, etc.
    timer?.invalidate()
}
```

### Slow Performance

**Problem**: UI feels sluggish with many items

**Solution**: Use lazy loading and limit initial renders:

```swift
LazyVStack {
    ForEach(items.prefix(100)) { item in
        ItemRow(item: item)
    }
}
```

## Best Practices

1. **Keep Views Small**: Break complex views into smaller components
2. **Use ViewModels**: Separate business logic from UI
3. **Async Operations**: Always use `Task` for file operations
4. **Error Handling**: Provide clear feedback for all operations
5. **Accessibility**: Add labels and help text
6. **Testing**: Use previews and mock data
7. **Performance**: Use lazy loading for large lists
8. **Consistency**: Follow theme throughout the app

## Integration Example

Complete example showing integration with main app:

```swift
import SwiftUI

@main
struct MiniworksEditorApp: App {
    @State private var deviceProfile = MiniworksDeviceProfile.newMachineConfiguration()
    @State private var showingFileManager = false
    
    var body: some Scene {
        WindowGroup {
            ContentView(deviceProfile: $deviceProfile)
                .sheet(isPresented: $showingFileManager) {
                    FileManagerView(deviceProfile: $deviceProfile)
                        .frame(minWidth: 900, minHeight: 600)
                }
        }
        .commands {
            CommandMenu("File Manager") {
                Button("Open File Manager") {
                    showingFileManager = true
                }
                .keyboardShortcut("m", modifiers: [.command, .shift])
            }
        }
    }
}
```

## Version History

- **v1.0**: Initial release with full feature set
- Theme system
- Four main tabs (Profiles, Programs, SysEx, Backups)
- Drag and drop support
- Auto-save functionality
- Backup management

## Support

For questions, issues, or feature requests, please refer to the main project documentation or contact the development team.
