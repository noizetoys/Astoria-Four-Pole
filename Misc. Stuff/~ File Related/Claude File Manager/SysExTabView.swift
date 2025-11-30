//
//  SysExTabView.swift
//  Astoria Filter Editor
//
//  Created by Assistant on 11/25/25.
//

import SwiftUI
import UniformTypeIdentifiers

/**
 # SysExTabView
 
 Handles SysEx file import and export operations.
 
 ## Features
 
 - Export device profiles as SysEx
 - Export individual programs as SysEx
 - Import SysEx files from hardware or file sharing
 - Drag and drop support
 - File validation
 - Transfer instructions
 
 ## Customization Points
 
 - **Export Options**: Add custom export settings
 - **Validation**: Customize file validation rules
 - **Instructions**: Update transfer instructions for your hardware
 - **File Types**: Modify supported file extensions
 */

struct SysExTabView: View {
    // MARK: - Properties
    
    @Binding var deviceProfile: MiniworksDeviceProfile
    @Bindable var viewModel: FileManagerViewModel
    
    @State private var isTargetedForDrop = false
    @State private var showingFileImporter = false
    @State private var showingExportOptions = false
    @State private var exportType: SysExExportType = .profile
    @State private var selectedProgramSlot = 1
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 0) {
            // Export section
            exportSection
                .frame(maxWidth: .infinity)
            
            Divider()
            
            // Import section
            importSection
                .frame(maxWidth: .infinity)
        }
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.sysex],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .sheet(isPresented: $showingExportOptions) {
            ExportOptionsSheet(
                exportType: $exportType,
                selectedProgramSlot: $selectedProgramSlot,
                onExport: {
                    Task {
                        await performExport()
                    }
                }
            )
        }
    }
    
    // MARK: - Export Section
    
    private var exportSection: some View {
        VStack(spacing: FileManagerTheme.largeSpacing) {
            // Header
            VStack(spacing: FileManagerTheme.smallSpacing) {
                Image(systemName: "square.and.arrow.up.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(FileManagerTheme.accentColor)
                
                Text("Export SysEx")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Create SysEx files for hardware transfer")
                    .font(FileManagerTheme.bodyFont)
                    .foregroundColor(FileManagerTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Divider()
            
            // Export options
            VStack(spacing: FileManagerTheme.mediumSpacing) {
                ExportOptionCard(
                    icon: "folder.fill",
                    title: "Full Device Profile",
                    description: "Export all 20 programs and global settings",
                    action: {
                        exportType = .profile
                        showingExportOptions = true
                    }
                )
                
                ExportOptionCard(
                    icon: "music.note",
                    title: "Single Program",
                    description: "Export one program from a device slot",
                    action: {
                        exportType = .program
                        showingExportOptions = true
                    }
                )
            }
            
            Spacer()
            
            // Instructions
            instructionsCard(
                icon: "info.circle",
                title: "How to Send to Hardware",
                steps: [
                    "Export your data as a .syx file",
                    "Open your SysEx transfer utility",
                    "Select the exported .syx file",
                    "Send to your Miniworks device"
                ]
            )
        }
        .padding(FileManagerTheme.largeSpacing)
    }
    
    // MARK: - Import Section
    
    private var importSection: some View {
        VStack(spacing: FileManagerTheme.largeSpacing) {
            // Header
            VStack(spacing: FileManagerTheme.smallSpacing) {
                Image(systemName: "square.and.arrow.down.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(FileManagerTheme.successColor)
                
                Text("Import SysEx")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Load SysEx files from hardware or file sharing")
                    .font(FileManagerTheme.bodyFont)
                    .foregroundColor(FileManagerTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Divider()
            
            // Drop zone
            dropZone
            
            // Or divider
            HStack {
                VStack { Divider() }
                Text("or")
                    .foregroundColor(FileManagerTheme.secondaryText)
                    .font(FileManagerTheme.captionFont)
                VStack { Divider() }
            }
            .padding(.horizontal, FileManagerTheme.largeSpacing)
            
            // Browse button
            Button {
                showingFileImporter = true
            } label: {
                Label("Browse Files...", systemImage: "folder")
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            
            Spacer()
            
            // Instructions
            instructionsCard(
                icon: "info.circle",
                title: "Supported Files",
                steps: [
                    "Standard MIDI SysEx files (.syx)",
                    "Waldorf Miniworks format",
                    "Program dumps or full device dumps",
                    "Files from hardware or other users"
                ]
            )
        }
        .padding(FileManagerTheme.largeSpacing)
    }
    
    // MARK: - Drop Zone
    
    private var dropZone: some View {
        VStack(spacing: FileManagerTheme.mediumSpacing) {
            Image(systemName: "arrow.down.doc")
                .font(.system(size: 40))
                .foregroundColor(
                    isTargetedForDrop
                        ? FileManagerTheme.accentColor
                        : FileManagerTheme.secondaryText
                )
            
            Text("Drop SysEx file here")
                .font(FileManagerTheme.titleFont)
                .foregroundColor(FileManagerTheme.primaryText)
            
            Text("Drag and drop a .syx file to import")
                .font(FileManagerTheme.captionFont)
                .foregroundColor(FileManagerTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(
            RoundedRectangle(cornerRadius: FileManagerTheme.cardCornerRadius)
                .strokeBorder(
                    style: StrokeStyle(lineWidth: 2, dash: [8])
                )
                .foregroundColor(
                    isTargetedForDrop
                        ? FileManagerTheme.accentColor
                        : FileManagerTheme.secondaryText.opacity(0.5)
                )
        )
        .background(
            RoundedRectangle(cornerRadius: FileManagerTheme.cardCornerRadius)
                .fill(
                    isTargetedForDrop
                        ? FileManagerTheme.accentColor.opacity(0.1)
                        : FileManagerTheme.secondaryBackground
                )
        )
        .onDrop(of: [.fileURL], isTargeted: $isTargetedForDrop) { providers in
            handleDrop(providers: providers)
        }
    }
    
    // MARK: - Instructions Card
    
    private func instructionsCard(icon: String, title: String, steps: [String]) -> some View {
        VStack(alignment: .leading, spacing: FileManagerTheme.mediumSpacing) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(FileManagerTheme.accentColor)
                Text(title)
                    .font(FileManagerTheme.titleFont)
            }
            
            VStack(alignment: .leading, spacing: FileManagerTheme.smallSpacing) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: FileManagerTheme.smallSpacing) {
                        Text("\(index + 1).")
                            .font(FileManagerTheme.captionFont)
                            .foregroundColor(FileManagerTheme.secondaryText)
                            .frame(width: 20, alignment: .leading)
                        
                        Text(step)
                            .font(FileManagerTheme.captionFont)
                            .foregroundColor(FileManagerTheme.secondaryText)
                    }
                }
            }
        }
        .padding(FileManagerTheme.mediumSpacing)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FileManagerTheme.secondaryBackground)
        .cornerRadius(FileManagerTheme.cardCornerRadius)
    }
    
    // MARK: - Actions
    
    private func performExport() async {
        switch exportType {
        case .profile:
            let name = "MiniworksExport_\(Date().timeIntervalSince1970)"
            if let url = await viewModel.exportProfileAsSysEx(named: name) {
                NSWorkspace.shared.activateFileViewerSelecting([url])
            }
            
        case .program:
            let program = deviceProfile.program(number: selectedProgramSlot)
            let name = "Program_\(selectedProgramSlot)_\(program.programName)"
            if let url = await viewModel.exportProgramAsSysEx(program, named: name) {
                NSWorkspace.shared.activateFileViewerSelecting([url])
            }
        }
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            Task {
                await viewModel.importSysExFile(from: url)
            }
            
        case .failure(let error):
            viewModel.errorMessage = "Failed to import: \(error.localizedDescription)"
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        _ = provider.loadObject(ofClass: URL.self) { url, error in
            guard let url = url, error == nil else { return }
            
            Task { @MainActor in
                await viewModel.importSysExFile(from: url)
            }
        }
        
        return true
    }
}

// MARK: - Export Option Card

struct ExportOptionCard: View {
    let icon: String
    let title: String
    let description: String
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: FileManagerTheme.mediumSpacing) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(FileManagerTheme.accentColor)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(FileManagerTheme.titleFont)
                        .foregroundColor(FileManagerTheme.primaryText)
                    
                    Text(description)
                        .font(FileManagerTheme.captionFont)
                        .foregroundColor(FileManagerTheme.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(FileManagerTheme.secondaryText)
            }
            .padding(FileManagerTheme.mediumSpacing)
            .frame(maxWidth: .infinity)
            .background(FileManagerTheme.cardBackground)
            .cornerRadius(FileManagerTheme.cardCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: FileManagerTheme.cardCornerRadius)
                    .stroke(isHovered ? FileManagerTheme.accentColor : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Export Options Sheet

struct ExportOptionsSheet: View {
    @Environment(\.dismiss) var dismiss
    
    @Binding var exportType: SysExExportType
    @Binding var selectedProgramSlot: Int
    let onExport: () -> Void
    
    var body: some View {
        VStack(spacing: FileManagerTheme.largeSpacing) {
            // Header
            VStack(spacing: FileManagerTheme.smallSpacing) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 40))
                    .foregroundColor(FileManagerTheme.accentColor)
                
                Text("Export Options")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            // Options
            VStack(alignment: .leading, spacing: FileManagerTheme.mediumSpacing) {
                Picker("Export Type", selection: $exportType) {
                    Text("Full Profile").tag(SysExExportType.profile)
                    Text("Single Program").tag(SysExExportType.program)
                }
                .pickerStyle(.segmented)
                
                if exportType == .program {
                    VStack(alignment: .leading, spacing: FileManagerTheme.smallSpacing) {
                        Text("Program Slot")
                            .font(FileManagerTheme.captionFont)
                            .foregroundColor(FileManagerTheme.secondaryText)
                        
                        Picker("Slot", selection: $selectedProgramSlot) {
                            ForEach(1...20, id: \.self) { slot in
                                Text("Slot \(slot)").tag(slot)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                
                // Info box
                HStack(alignment: .top, spacing: FileManagerTheme.smallSpacing) {
                    Image(systemName: "info.circle")
                        .foregroundColor(FileManagerTheme.accentColor)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exportType == .profile ? "Full Device Export" : "Single Program Export")
                            .font(FileManagerTheme.captionFont)
                            .fontWeight(.medium)
                        
                        Text(exportType == .profile
                            ? "Exports all 20 programs and global settings. File size: ~593 bytes"
                            : "Exports one program slot. File size: ~37 bytes"
                        )
                        .font(FileManagerTheme.captionFont)
                        .foregroundColor(FileManagerTheme.secondaryText)
                    }
                }
                .padding(FileManagerTheme.smallSpacing)
                .background(FileManagerTheme.accentColor.opacity(0.1))
                .cornerRadius(6)
            }
            
            // Actions
            HStack(spacing: FileManagerTheme.mediumSpacing) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Export") {
                    onExport()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(FileManagerTheme.largeSpacing)
        .frame(width: 400)
    }
}

// MARK: - Export Type

enum SysExExportType {
    case profile
    case program
}

// MARK: - UTType Extension

extension UTType {
    static var sysex: UTType {
        UTType(filenameExtension: "syx") ?? .data
    }
}

// MARK: - Preview

#Preview("SysEx Tab") {
    struct PreviewWrapper: View {
        @State private var profile = MiniworksDeviceProfile.newMachineConfiguration()
        @State private var viewModel = FileManagerViewModel(
            currentProfile: MiniworksDeviceProfile.newMachineConfiguration()
        )
        
        var body: some View {
            SysExTabView(deviceProfile: $profile, viewModel: viewModel)
                .frame(width: 900, height: 600)
        }
    }
    
    return PreviewWrapper()
}
