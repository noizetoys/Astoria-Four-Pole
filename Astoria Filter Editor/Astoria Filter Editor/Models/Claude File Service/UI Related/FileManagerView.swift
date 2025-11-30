//
//  FileManagerView.swift
//  Astoria Filter Editor
//
//  Created by Assistant on 11/25/25.
//

import SwiftUI

/**
 # FileManagerView
 
 A comprehensive file management interface for the Miniworks MIDI editor.
 
 ## Features
 
 - **Profile Management**: Save, load, and organize complete device configurations
 - **Program Library**: Browse and manage individual patches
 - **SysEx Operations**: Import/export hardware-compatible files
 - **Backup System**: Automatic and manual backup management
 - **Factory Presets**: Access read-only factory patches
 
 ## Architecture
 
 The view uses a tab-based interface with four main sections:
 1. **Profiles**: Complete device state management
 2. **Programs**: Individual patch library
 3. **SysEx**: Import/export operations
 4. **Backups**: Backup management
 
 ## Customization Points
 
 - **Color Scheme**: Modify `FileManagerTheme` for custom colors
 - **Layout**: Adjust spacing and sizing constants
 - **Icons**: Replace SF Symbols with custom icons
 - **Behaviors**: Customize confirmation dialogs and alerts
 
 ## Usage
 
 ```swift
 @State private var deviceProfile: MiniworksDeviceProfile
 
 var body: some View {
     FileManagerView(deviceProfile: $deviceProfile)
 }
 ```
 */

// MARK: - Theme Configuration

/**
 Visual theme for the file manager interface.
 
 ## Customization
 Modify these values to match your app's design system.
 */
struct FileManagerTheme {
    // MARK: - Colors
    
    /// Primary accent color for interactive elements
    static let accentColor = Color.blue
    
    /// Secondary accent for less prominent actions
    static let secondaryAccent = Color.gray
    
    /// Destructive action color (delete, etc.)
    static let destructiveColor = Color.red
    
    /// Success indicator color
    static let successColor = Color.green
    
    /// Background colors
    static let primaryBackground = Color(NSColor.controlBackgroundColor)
    static let secondaryBackground = Color(NSColor.windowBackgroundColor)
    static let cardBackground = Color(NSColor.controlBackgroundColor)
    
    /// Text colors
    static let primaryText = Color.primary
    static let secondaryText = Color.secondary
    static let tertiaryText = Color(NSColor.tertiaryLabelColor)
    
    // MARK: - Spacing
    
    static let smallSpacing: CGFloat = 8
    static let mediumSpacing: CGFloat = 16
    static let largeSpacing: CGFloat = 24
    
    // MARK: - Sizing
    
    static let cardCornerRadius: CGFloat = 8
    static let buttonHeight: CGFloat = 32
    static let iconSize: CGFloat = 20
    static let thumbnailSize: CGFloat = 60
    
    // MARK: - Typography
    
    static let titleFont = Font.headline
    static let bodyFont = Font.body
    static let captionFont = Font.caption
}

// MARK: - Main File Manager View

struct FileManagerView: View {
    // MARK: - Properties
    
    /// Binding to the current device profile
    @Binding var deviceProfile: MiniworksDeviceProfile
    
    /// View model for file operations
    @State private var viewModel: FileManagerViewModel
    
    /// Currently selected tab
    @State private var selectedTab: FileManagerTab = .profiles
    
    // MARK: - Lifecycle
    
    init(deviceProfile: Binding<MiniworksDeviceProfile>) {
        self._deviceProfile = deviceProfile
        self._viewModel = State(initialValue: FileManagerViewModel(currentProfile: deviceProfile.wrappedValue))
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationSplitView {
            // Sidebar with tabs
            sidebar
        } detail: {
            // Main content area
            TabView(selection: $selectedTab) {
                ProfilesTabView(
                    deviceProfile: $deviceProfile,
                    viewModel: viewModel
                )
                .tag(FileManagerTab.profiles)
                
                ProgramsTabView(
                    deviceProfile: $deviceProfile,
                    viewModel: viewModel
                )
                .tag(FileManagerTab.programs)
                
                SysExTabView(
                    deviceProfile: $deviceProfile,
                    viewModel: viewModel
                )
                .tag(FileManagerTab.sysex)
                
                BackupsTabView(
                    deviceProfile: $deviceProfile,
                    viewModel: viewModel
                )
                .tag(FileManagerTab.backups)
            }
            .tabViewStyle(.automatic)
        }
        .navigationTitle("File Manager")
        .task {
            await viewModel.initialize()
        }
        .onChange(of: deviceProfile) { oldValue, newValue in
            viewModel.updateCurrentProfile(newValue)
        }
    }
    
    
    // MARK: - Sidebar
    
    private var sidebar: some View {
        List(selection: $selectedTab) {
            Section("Manage") {
                ForEach(FileManagerTab.allCases) { tab in
                    NavigationLink(value: tab) {
                        Label {
                            Text(tab.title)
                        } icon: {
                            Image(systemName: tab.icon)
                                .foregroundColor(FileManagerTheme.accentColor)
                        }
                    }
                }
            }
            
            Section("Quick Actions") {
                Button {
                    Task {
                        await viewModel.quickSave()
                    }
                } label: {
                    Label("Quick Save", systemImage: "square.and.arrow.down")
                }
                .disabled(!viewModel.hasUnsavedChanges)
                
                Button {
                    Task {
                        await viewModel.createBackup()
                    }
                } label: {
                    Label("Create Backup", systemImage: "clock.arrow.circlepath")
                }
            }
            
            Section("Status") {
                statusIndicators
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 220)
    }
    
    // MARK: - Status Indicators
    
    private var statusIndicators: some View {
        VStack(alignment: .leading, spacing: FileManagerTheme.smallSpacing) {
            if viewModel.isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading...")
                        .font(FileManagerTheme.captionFont)
                        .foregroundColor(FileManagerTheme.secondaryText)
                }
            }
            
            if viewModel.hasUnsavedChanges {
                HStack {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.orange)
                    Text("Unsaved Changes")
                        .font(FileManagerTheme.captionFont)
                        .foregroundColor(FileManagerTheme.secondaryText)
                }
            }
            
            if let lastSaved = viewModel.lastSaveDate {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Last Saved")
                        .font(FileManagerTheme.captionFont)
                        .foregroundColor(FileManagerTheme.tertiaryText)
                    Text(lastSaved, style: .relative)
                        .font(FileManagerTheme.captionFont)
                        .foregroundColor(FileManagerTheme.secondaryText)
                }
            }
        }
        .padding(.vertical, FileManagerTheme.smallSpacing)
    }
    
}

// MARK: - Tab Definition

enum FileManagerTab: String, CaseIterable, Identifiable {
    case profiles
    case programs
    case sysex
    case backups
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .profiles: return "Profiles"
        case .programs: return "Programs"
        case .sysex: return "SysEx"
        case .backups: return "Backups"
        }
    }
    
    var icon: String {
        switch self {
        case .profiles: return "folder.fill"
        case .programs: return "music.note.list"
        case .sysex: return "arrow.up.arrow.down.circle"
        case .backups: return "clock.arrow.circlepath"
        }
    }
}

// MARK: - Preview

#Preview("File Manager") {
    struct PreviewWrapper: View {
        @State private var profile = MiniworksDeviceProfile.newMachineConfiguration()
        
        var body: some View {
            FileManagerView(deviceProfile: $profile)
                .frame(width: 900, height: 600)
        }
    }
    
    return PreviewWrapper()
}
