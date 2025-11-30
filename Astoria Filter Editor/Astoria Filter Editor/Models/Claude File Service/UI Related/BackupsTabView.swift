//
//  BackupsTabView.swift
//  Astoria Filter Editor
//
//  Created by Assistant on 11/25/25.
//

import SwiftUI

/**
 # BackupsTabView
 
 Manages automatic and manual backups of device profiles.
 
 ## Features
 
 - List all available backups with timestamps
 - Restore from backup
 - Delete old backups
 - Create manual backups
 - Auto-backup configuration
 - Storage management
 
 ## Customization Points
 
 - **Retention Policy**: Adjust default backup count
 - **Display Format**: Customize backup list appearance
 - **Actions**: Add custom backup operations
 - **Auto-backup Settings**: Modify timing and triggers
 */

struct BackupsTabView: View {
    // MARK: - Properties
    
    @Binding var deviceProfile: MiniworksDeviceProfile
    @Bindable var viewModel: FileManagerViewModel
    
    @State private var showingRestoreConfirmation = false
    @State private var showingDeleteConfirmation = false
    @State private var backupToRestore: BackupMetadata?
    @State private var backupToDelete: BackupMetadata?
    @State private var showingCleanupConfirmation = false
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            Divider()
            
            // Content
            if viewModel.availableBackups.isEmpty {
                emptyState
            } else {
                backupsList
            }
        }
        .confirmationDialog(
            "Restore Backup?",
            isPresented: $showingRestoreConfirmation,
            presenting: backupToRestore
        ) { backup in
            Button("Restore") {
                Task {
                    await viewModel.restoreBackup(backup)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { backup in
            if viewModel.hasUnsavedChanges {
                Text("You have unsaved changes. Restoring '\(backup.name)' will discard them.")
            } else {
                Text("Restore backup from \(backup.date.formatted(date: .long, time: .shortened))?")
            }
        }
        .confirmationDialog(
            "Delete Backup?",
            isPresented: $showingDeleteConfirmation,
            presenting: backupToDelete
        ) { backup in
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteBackup(backup)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { backup in
            Text("Delete backup from \(backup.date.formatted())? This action cannot be undone.")
        }
        .confirmationDialog(
            "Clean Old Backups?",
            isPresented: $showingCleanupConfirmation
        ) {
            Button("Clean Up", role: .destructive) {
                Task {
                    await viewModel.cleanOldBackups()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete old backups, keeping only the 10 most recent. This action cannot be undone.")
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Backups")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("\(viewModel.availableBackups.count) backup\(viewModel.availableBackups.count == 1 ? "" : "s") available")
                    .font(FileManagerTheme.captionFont)
                    .foregroundColor(FileManagerTheme.secondaryText)
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: FileManagerTheme.smallSpacing) {
                if viewModel.availableBackups.count > 10 {
                    Button {
                        showingCleanupConfirmation = true
                    } label: {
                        Label("Clean Up", systemImage: "trash")
                    }
                    .help("Delete old backups")
                }
                
                Button {
                    Task {
                        await viewModel.createBackup()
                    }
                } label: {
                    Label("Create Backup", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .help("Create a manual backup now")
            }
        }
        .padding(FileManagerTheme.mediumSpacing)
    }
    
    // MARK: - Backups List
    
    private var backupsList: some View {
        ScrollView {
            LazyVStack(spacing: FileManagerTheme.mediumSpacing) {
                // Recent backups (last 24 hours)
                if !recentBackups.isEmpty {
                    BackupSection(
                        title: "Recent",
                        icon: "clock.fill",
                        iconColor: .green,
                        backups: recentBackups,
                        onRestore: { backup in
                            backupToRestore = backup
                            showingRestoreConfirmation = true
                        },
                        onDelete: { backup in
                            backupToDelete = backup
                            showingDeleteConfirmation = true
                        }
                    )
                }
                
                // This week
                if !thisWeekBackups.isEmpty {
                    BackupSection(
                        title: "This Week",
                        icon: "calendar",
                        iconColor: .blue,
                        backups: thisWeekBackups,
                        onRestore: { backup in
                            backupToRestore = backup
                            showingRestoreConfirmation = true
                        },
                        onDelete: { backup in
                            backupToDelete = backup
                            showingDeleteConfirmation = true
                        }
                    )
                }
                
                // Older
                if !olderBackups.isEmpty {
                    BackupSection(
                        title: "Older",
                        icon: "archivebox.fill",
                        iconColor: .gray,
                        backups: olderBackups,
                        onRestore: { backup in
                            backupToRestore = backup
                            showingRestoreConfirmation = true
                        },
                        onDelete: { backup in
                            backupToDelete = backup
                            showingDeleteConfirmation = true
                        }
                    )
                }
                
                // Storage info
                storageInfoCard
            }
            .padding(FileManagerTheme.mediumSpacing)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: FileManagerTheme.mediumSpacing) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundColor(FileManagerTheme.secondaryText)
            
            Text("No Backups Yet")
                .font(.title2)
                .foregroundColor(FileManagerTheme.primaryText)
            
            Text("Create your first backup to protect your work")
                .font(FileManagerTheme.bodyFont)
                .foregroundColor(FileManagerTheme.secondaryText)
                .multilineTextAlignment(.center)
            
            Button {
                Task {
                    await viewModel.createBackup()
                }
            } label: {
                Label("Create Backup", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            // Info card
            VStack(alignment: .leading, spacing: FileManagerTheme.smallSpacing) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(FileManagerTheme.accentColor)
                    Text("About Backups")
                        .font(FileManagerTheme.titleFont)
                }
                
                VStack(alignment: .leading, spacing: FileManagerTheme.smallSpacing) {
                    Text("• Backups save your complete device state")
                    Text("• Auto-backups occur every 5 minutes when editing")
                    Text("• The 10 most recent backups are kept automatically")
                    Text("• Restore any backup with a single click")
                }
                .font(FileManagerTheme.captionFont)
                .foregroundColor(FileManagerTheme.secondaryText)
            }
            .padding(FileManagerTheme.mediumSpacing)
            .frame(maxWidth: 400)
            .background(FileManagerTheme.secondaryBackground)
            .cornerRadius(FileManagerTheme.cardCornerRadius)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Storage Info Card
    
    private var storageInfoCard: some View {
        VStack(spacing: FileManagerTheme.mediumSpacing) {
            HStack {
                Image(systemName: "externaldrive")
                    .foregroundColor(FileManagerTheme.accentColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Storage Usage")
                        .font(FileManagerTheme.titleFont)
                    
                    Text("Backups are stored locally on your Mac")
                        .font(FileManagerTheme.captionFont)
                        .foregroundColor(FileManagerTheme.secondaryText)
                }
                
                Spacer()
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Backups")
                        .font(FileManagerTheme.captionFont)
                        .foregroundColor(FileManagerTheme.secondaryText)
                    
                    Text("\(viewModel.availableBackups.count)")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Estimated Size")
                        .font(FileManagerTheme.captionFont)
                        .foregroundColor(FileManagerTheme.secondaryText)
                    
                    Text(estimatedBackupSize)
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }
            
            // Cleanup recommendation
            if viewModel.availableBackups.count > 10 {
                HStack(alignment: .top, spacing: FileManagerTheme.smallSpacing) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Consider cleaning up old backups")
                            .font(FileManagerTheme.captionFont)
                            .fontWeight(.medium)
                        
                        Text("You have more than 10 backups. Cleaning up will keep the 10 most recent and free up space.")
                            .font(FileManagerTheme.captionFont)
                            .foregroundColor(FileManagerTheme.secondaryText)
                    }
                }
                .padding(FileManagerTheme.smallSpacing)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(6)
            }
        }
        .padding(FileManagerTheme.mediumSpacing)
        .background(FileManagerTheme.cardBackground)
        .cornerRadius(FileManagerTheme.cardCornerRadius)
    }
    
    // MARK: - Computed Properties
    
    private var recentBackups: [BackupMetadata] {
        let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return viewModel.availableBackups.filter { $0.date >= oneDayAgo }
    }
    
    private var thisWeekBackups: [BackupMetadata] {
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return viewModel.availableBackups.filter { $0.date < oneDayAgo && $0.date >= oneWeekAgo }
    }
    
    private var olderBackups: [BackupMetadata] {
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return viewModel.availableBackups.filter { $0.date < oneWeekAgo }
    }
    
    private var estimatedBackupSize: String {
        // Each backup is roughly 10-50 KB depending on content
        let estimatedBytes = viewModel.availableBackups.count * 30_000
        return ByteCountFormatter.string(fromByteCount: Int64(estimatedBytes), countStyle: .file)
    }
}

// MARK: - Backup Section

struct BackupSection: View {
    let title: String
    let icon: String
    let iconColor: Color
    let backups: [BackupMetadata]
    let onRestore: (BackupMetadata) -> Void
    let onDelete: (BackupMetadata) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: FileManagerTheme.mediumSpacing) {
            // Section header
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                
                Text(title)
                    .font(FileManagerTheme.titleFont)
                
                Text("(\(backups.count))")
                    .font(FileManagerTheme.captionFont)
                    .foregroundColor(FileManagerTheme.secondaryText)
            }
            
            // Backups
            VStack(spacing: FileManagerTheme.smallSpacing) {
                ForEach(backups) { backup in
                    BackupRow(
                        backup: backup,
                        onRestore: { onRestore(backup) },
                        onDelete: { onDelete(backup) }
                    )
                }
            }
        }
    }
}

// MARK: - Backup Row

struct BackupRow: View {
    let backup: BackupMetadata
    let onRestore: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: FileManagerTheme.mediumSpacing) {
            // Icon
            Image(systemName: backupType.icon)
                .font(.title3)
                .foregroundColor(backupType.color)
                .frame(width: 32)
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(backupType.label)
                    .font(FileManagerTheme.bodyFont)
                    .foregroundColor(FileManagerTheme.primaryText)
                
                HStack(spacing: FileManagerTheme.smallSpacing) {
                    Text(backup.date.formatted(date: .abbreviated, time: .shortened))
                    
                    Text("•")
                    
                    Text(timeAgo)
                }
                .font(FileManagerTheme.captionFont)
                .foregroundColor(FileManagerTheme.secondaryText)
            }
            
            Spacer()
            
            // Actions
            if isHovered {
                HStack(spacing: FileManagerTheme.smallSpacing) {
                    Button {
                        onDelete()
                    } label: {
                        Label("Delete", systemImage: "trash")
                            .labelStyle(.iconOnly)
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(FileManagerTheme.destructiveColor)
                    .help("Delete this backup")
                    
                    Button {
                        onRestore()
                    } label: {
                        Label("Restore", systemImage: "arrow.counterclockwise.circle")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .help("Restore from this backup")
                }
            }
        }
        .padding(FileManagerTheme.mediumSpacing)
        .background(FileManagerTheme.cardBackground)
        .cornerRadius(FileManagerTheme.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: FileManagerTheme.cardCornerRadius)
                .stroke(isHovered ? FileManagerTheme.accentColor : .clear, lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
    
    private var backupType: (icon: String, color: Color, label: String) {
        if backup.name.contains("AutoSave") {
            return ("clock.arrow.circlepath", .blue, "Auto Backup")
        } else if backup.name.contains("QuickSave") {
            return ("bolt.circle.fill", .green, "Quick Save")
        } else {
            return ("folder.fill", .purple, "Manual Backup")
        }
    }
    
    private var timeAgo: String {
        let components = Calendar.current.dateComponents(
            [.minute, .hour, .day],
            from: backup.date,
            to: Date()
        )
        
        if let days = components.day, days > 0 {
            return "\(days) day\(days == 1 ? "" : "s") ago"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else {
            return "Just now"
        }
    }
}

// MARK: - Preview

#Preview("Backups Tab") {
    struct PreviewWrapper: View {
        @State private var profile = MiniworksDeviceProfile.newMachineConfiguration()
        @State private var viewModel = FileManagerViewModel(
            currentProfile: MiniworksDeviceProfile.newMachineConfiguration()
        )
        
        var body: some View {
            BackupsTabView(deviceProfile: $profile, viewModel: viewModel)
                .frame(width: 800, height: 600)
                .onAppear {
                    // Add some mock backups for preview
                    viewModel.availableBackups = [
                        BackupMetadata(name: "AutoSave_1", date: Date()),
                        BackupMetadata(name: "QuickSave_1", date: Date().addingTimeInterval(-3600)),
                        BackupMetadata(name: "backup_1", date: Date().addingTimeInterval(-86400)),
                    ]
                }
        }
    }
    
    return PreviewWrapper()
}
