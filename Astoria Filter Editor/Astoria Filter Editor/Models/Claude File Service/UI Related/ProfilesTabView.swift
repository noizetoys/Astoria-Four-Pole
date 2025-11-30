//
//  ProfilesTabView.swift
//  Astoria Filter Editor
//
//  Created by Assistant on 11/25/25.
//

import SwiftUI

/**
 # ProfilesTabView
 
 Manages complete device profile operations: save, load, and organize.
 
 ## Features
 
 - List view of all saved profiles
 - Save current profile with custom name
 - Load existing profiles
 - Delete profiles with confirmation
 - Sort by name or date
 - Search functionality
 - Profile details display
 
 ## Customization Points
 
 - **Layout**: Adjust list item sizing and spacing
 - **Actions**: Add custom profile operations
 - **Sorting**: Modify sort options
 - **Details**: Customize profile info display
 */

struct ProfilesTabView: View {
    // MARK: - Properties
    
    @Binding var deviceProfile: MiniworksDeviceProfile
    @Bindable var viewModel: FileManagerViewModel
    
    @State private var showingSaveDialog = false
    @State private var showingDeleteConfirmation = false
    @State private var showingLoadConfirmation = false
    @State private var profileToDelete: ProfileMetadata?
    @State private var profileToLoad: ProfileMetadata?
    @State private var searchText = ""
    @State private var sortOrder: ProfileSortOrder = .dateDescending
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with actions
            header
            
            Divider()
            
            // Main content
            if viewModel.availableProfiles.isEmpty {
                emptyState
            } else {
                profilesList
            }
        }
        .sheet(isPresented: $showingSaveDialog) {
            let nameBinding = Binding<String>(
                get: { deviceProfile.name },
                set: { deviceProfile.name = $0 }
           )
            
            SaveProfileDialog(onSave: {_ in 
                    Task {
                        await viewModel.saveProfile(named: deviceProfile.name)
                    }
                }
            )
        }
        .confirmationDialog(
            "Delete Profile?",
            isPresented: $showingDeleteConfirmation,
            presenting: profileToDelete
        ) { profile in
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteProfile(named: profile.name)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { profile in
            Text("Are you sure you want to delete '\(profile.name)'? This action cannot be undone.")
        }
        .confirmationDialog(
            "Load Profile?",
            isPresented: $showingLoadConfirmation,
            presenting: profileToLoad
        ) { profile in
            Button("Load") {
                Task {
                    await viewModel.loadProfile(named: profile.name)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { profile in
            if viewModel.hasUnsavedChanges {
                Text("You have unsaved changes. Loading '\(profile.name)' will discard them.")
            } else {
                Text("Load '\(profile.name)'?")
            }
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(FileManagerTheme.secondaryText)
                TextField("Search profiles...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(FileManagerTheme.secondaryText)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(FileManagerTheme.secondaryBackground)
            .cornerRadius(6)
            
            Spacer()
            
            // Sort menu
            Menu {
                Picker("Sort By", selection: $sortOrder) {
                    ForEach(ProfileSortOrder.allCases) { order in
                        Text(order.title).tag(order)
                    }
                }
            } label: {
                Label("Sort", systemImage: "arrow.up.arrow.down")
            }
            
            // Save button
            Button {
                showingSaveDialog = true
            } label: {
                Label("Save Profile", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(FileManagerTheme.mediumSpacing)
    }
    
    // MARK: - Profiles List
    
    private var profilesList: some View {
        List {
            ForEach(filteredAndSortedProfiles) { profile in
                ProfileRow(
                    profile: profile,
                    onLoad: {
                        profileToLoad = profile
                        showingLoadConfirmation = true
                    },
                    onDelete: {
                        profileToDelete = profile
                        showingDeleteConfirmation = true
                    },
                    onExport: {
                        Task {
                            await exportProfile(profile)
                        }
                    }
                )
            }
        }
        .listStyle(.plain)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: FileManagerTheme.mediumSpacing) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(FileManagerTheme.secondaryText)
            
            Text("No Saved Profiles")
                .font(.title2)
                .foregroundColor(FileManagerTheme.primaryText)
            
            Text("Save your first profile to get started")
                .font(FileManagerTheme.bodyFont)
                .foregroundColor(FileManagerTheme.secondaryText)
            
            Button {
                showingSaveDialog = true
            } label: {
                Label("Save Current Profile", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Computed Properties
    
    private var filteredAndSortedProfiles: [ProfileMetadata] {
        let filtered = searchText.isEmpty
            ? viewModel.availableProfiles
            : viewModel.availableProfiles.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        
        return filtered.sorted { lhs, rhs in
            switch sortOrder {
            case .nameAscending:
                return lhs.name < rhs.name
            case .nameDescending:
                return lhs.name > rhs.name
            case .dateAscending:
                return lhs.modifiedDate < rhs.modifiedDate
            case .dateDescending:
                return lhs.modifiedDate > rhs.modifiedDate
            }
        }
    }
    
    // MARK: - Actions
    
    private func exportProfile(_ profile: ProfileMetadata) async {
        // First load the profile
        await viewModel.loadProfile(named: profile.name)
        
        // Then export it
        await viewModel.exportProfileAsSysEx(named: profile.name)
    }
}

// MARK: - Profile Row

struct ProfileRow: View {
    let profile: ProfileMetadata
    let onLoad: () -> Void
    let onDelete: () -> Void
    let onExport: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: FileManagerTheme.mediumSpacing) {
            // Icon
            Image(systemName: "folder.fill")
                .font(.title2)
                .foregroundColor(FileManagerTheme.accentColor)
                .frame(width: 40)
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.name)
                    .font(FileManagerTheme.titleFont)
                    .foregroundColor(FileManagerTheme.primaryText)
                
                HStack(spacing: FileManagerTheme.smallSpacing) {
                    Label(
                        profile.modifiedDate.formatted(date: .abbreviated, time: .shortened),
                        systemImage: "clock"
                    )
                    
                    Text("•")
                    
                    Label(profile.formattedSize, systemImage: "doc")
                }
                .font(FileManagerTheme.captionFont)
                .foregroundColor(FileManagerTheme.secondaryText)
            }
            
            Spacer()
            
            // Actions
            if isHovered {
                HStack(spacing: FileManagerTheme.smallSpacing) {
                    Button {
                        onExport()
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                            .labelStyle(.iconOnly)
                    }
                    .buttonStyle(.borderless)
                    .help("Export as SysEx")
                    
                    Button {
                        onLoad()
                    } label: {
                        Label("Load", systemImage: "arrow.down.circle")
                            .labelStyle(.iconOnly)
                    }
                    .buttonStyle(.borderless)
                    .help("Load this profile")
                    
                    Button {
                        onDelete()
                    } label: {
                        Label("Delete", systemImage: "trash")
                            .labelStyle(.iconOnly)
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(FileManagerTheme.destructiveColor)
                    .help("Delete this profile")
                }
            }
        }
        .padding(.vertical, FileManagerTheme.smallSpacing)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Save Profile Dialog

struct SaveProfileDialog: View {
    @Environment(\.dismiss) var dismiss
    
    let onSave: (String) -> Void
    
    @State private var profileName = ""
    @State private var includeTimestamp = true
    @FocusState private var isNameFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: FileManagerTheme.largeSpacing) {
            // Header
            VStack(spacing: FileManagerTheme.smallSpacing) {
                Image(systemName: "square.and.arrow.down.fill")
                    .font(.system(size: 40))
                    .foregroundColor(FileManagerTheme.accentColor)
                
                Text("Save Profile")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Enter a name for this device profile")
                    .font(FileManagerTheme.bodyFont)
                    .foregroundColor(FileManagerTheme.secondaryText)
            }
            
            // Input
            VStack(alignment: .leading, spacing: FileManagerTheme.smallSpacing) {
                Text("Profile Name")
                    .font(FileManagerTheme.captionFont)
                    .foregroundColor(FileManagerTheme.secondaryText)
                
                TextField("e.g., Live Setup 2025", text: $profileName)
                    .textFieldStyle(.roundedBorder)
                    .focused($isNameFieldFocused)
                
                Toggle("Include timestamp", isOn: $includeTimestamp)
                    .font(FileManagerTheme.bodyFont)
            }
            
            // Preview
            if !profileName.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Will be saved as:")
                        .font(FileManagerTheme.captionFont)
                        .foregroundColor(FileManagerTheme.tertiaryText)
                    
                    Text(finalName)
                        .font(FileManagerTheme.bodyFont)
                        .foregroundColor(FileManagerTheme.primaryText)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(FileManagerTheme.secondaryBackground)
                        .cornerRadius(4)
                }
            }
            
            // Actions
            HStack(spacing: FileManagerTheme.mediumSpacing) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Save") {
                    onSave(finalName)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(profileName.isEmpty)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(FileManagerTheme.largeSpacing)
        .frame(width: 400)
        .onAppear {
            isNameFieldFocused = true
        }
    }
    
    private var finalName: String {
        if includeTimestamp {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            return "\(profileName) (\(formatter.string(from: Date())))"
        }
        return profileName
    }
}

// MARK: - Sort Order

enum ProfileSortOrder: String, CaseIterable, Identifiable {
    case nameAscending = "name_asc"
    case nameDescending = "name_desc"
    case dateAscending = "date_asc"
    case dateDescending = "date_desc"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .nameAscending: return "Name (A-Z)"
        case .nameDescending: return "Name (Z-A)"
        case .dateAscending: return "Date (Oldest First)"
        case .dateDescending: return "Date (Newest First)"
        }
    }
}

// MARK: - Preview

#Preview("Profiles Tab") {
    struct PreviewWrapper: View {
        @State private var profile = MiniworksDeviceProfile.newMachineConfiguration()
        @State private var viewModel = FileManagerViewModel(
            currentProfile: MiniworksDeviceProfile.newMachineConfiguration()
        )
        
        var body: some View {
            ProfilesTabView(deviceProfile: $profile, viewModel: viewModel)
                .frame(width: 800, height: 600)
        }
    }
    
    return PreviewWrapper()
}
