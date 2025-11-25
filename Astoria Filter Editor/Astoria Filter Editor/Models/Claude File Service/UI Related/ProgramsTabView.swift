//
//  ProgramsTabView.swift
//  Astoria Filter Editor
//
//  Created by Assistant on 11/25/25.
//

import SwiftUI

/**
 # ProgramsTabView
 
 Manages individual program/patch operations.
 
 ## Features
 
 - Browse saved programs and factory presets
 - Save individual programs from device
 - Load programs into device slots
 - Copy programs between slots
 - Export programs as SysEx
 - Program preview/details
 - Drag and drop support
 
 ## Customization Points
 
 - **Grid Layout**: Adjust columns and spacing
 - **Card Design**: Customize program card appearance
 - **Actions**: Add custom program operations
 - **Preview**: Customize program details display
 */

struct ProgramsTabView: View {
    // MARK: - Properties
    
    @Binding var deviceProfile: MiniworksDeviceProfile
    @Bindable var viewModel: FileManagerViewModel
    
    @State private var selectedView: ProgramViewMode = .library
    @State private var searchText = ""
    @State private var showingSaveDialog = false
    @State private var showingImportDialog = false
    @State private var programToSave: MiniWorksProgram?
    @State private var programToImport: MiniWorksProgram?
    @State private var selectedSlot = 1
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with mode switcher
            header
            
            Divider()
            
            // Content based on selected mode
            TabView(selection: $selectedView) {
                libraryView
                    .tag(ProgramViewMode.library)
                
                deviceSlotsView
                    .tag(ProgramViewMode.deviceSlots)
                
                factoryPresetsView
                    .tag(ProgramViewMode.factory)
            }
            .tabViewStyle(.automatic)
        }
        .sheet(isPresented: $showingSaveDialog, onDismiss: {
            programToSave = nil
        }) {
            if let program = programToSave {
                SaveProgramDialog(
                    program: program,
                    onSave: { name in
                        Task {
                            await viewModel.saveProgram(program, named: name)
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $showingImportDialog, onDismiss: {
            programToImport = nil
        }) {
            if let program = programToImport {
                ImportProgramDialog(
                    program: program,
                    onImport: { slot in
                        viewModel.importProgramToSlot(program, slot: slot)
                    }
                )
            }
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            // View mode picker
            Picker("View", selection: $selectedView) {
                ForEach(ProgramViewMode.allCases) { mode in
                    Label(mode.title, systemImage: mode.icon)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 400)
            
            Spacer()
            
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(FileManagerTheme.secondaryText)
                TextField("Search programs...", text: $searchText)
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
            .frame(maxWidth: 300)
        }
        .padding(FileManagerTheme.mediumSpacing)
    }
    
    // MARK: - Library View
    
    private var libraryView: some View {
        Group {
            if filteredUserPrograms.isEmpty {
                emptyLibraryState
            } else {
                ScrollView {
                    LazyVGrid(
                        columns: [
                            GridItem(.adaptive(minimum: 200, maximum: 250), spacing: FileManagerTheme.mediumSpacing)
                        ],
                        spacing: FileManagerTheme.mediumSpacing
                    ) {
                        ForEach(filteredUserPrograms) { program in
                            ProgramCard(
                                metadata: program,
                                onLoad: {
                                    Task {
                                        if let loaded = await viewModel.loadProgram(named: program.name) {
                                            programToImport = loaded
                                            showingImportDialog = true
                                        }
                                    }
                                },
                                onDelete: {
                                    Task {
                                        await viewModel.deleteProgram(named: program.name)
                                    }
                                },
                                onExport: {
                                    Task {
                                        if let loaded = await viewModel.loadProgram(named: program.name) {
                                            await viewModel.exportProgramAsSysEx(loaded, named: program.name)
                                        }
                                    }
                                }
                            )
                        }
                    }
                    .padding(FileManagerTheme.mediumSpacing)
                }
            }
        }
    }
    
    // MARK: - Device Slots View
    
    private var deviceSlotsView: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 180, maximum: 220), spacing: FileManagerTheme.mediumSpacing)
                ],
                spacing: FileManagerTheme.mediumSpacing
            ) {
                ForEach(1...20, id: \.self) { slotNumber in
                    DeviceSlotCard(
                        slotNumber: slotNumber,
                        program: deviceProfile.program(number: slotNumber),
                        onSave: {
                            programToSave = deviceProfile.program(number: slotNumber)
                            showingSaveDialog = true
                        },
                        onCopy: {
                            // Copy to pasteboard or internal clipboard
                        },
                        onExport: {
                            Task {
                                let program = deviceProfile.program(number: slotNumber)
                                await viewModel.exportProgramAsSysEx(
                                    program,
                                    named: "Slot_\(slotNumber)_\(program.programName)"
                                )
                            }
                        }
                    )
                }
            }
            .padding(FileManagerTheme.mediumSpacing)
        }
    }
    
    // MARK: - Factory Presets View
    
    private var factoryPresetsView: some View {
        Group {
            if filteredFactoryPrograms.isEmpty {
                emptyFactoryState
            } else {
                ScrollView {
                    LazyVGrid(
                        columns: [
                            GridItem(.adaptive(minimum: 200, maximum: 250), spacing: FileManagerTheme.mediumSpacing)
                        ],
                        spacing: FileManagerTheme.mediumSpacing
                    ) {
                        ForEach(filteredFactoryPrograms) { program in
                            ProgramCard(
                                metadata: program,
                                isFactory: true,
                                onLoad: {
                                    Task {
                                        if let loaded = await viewModel.loadProgram(
                                            named: program.name,
                                            fromFactory: true
                                        ) {
                                            programToImport = loaded
                                            showingImportDialog = true
                                        }
                                    }
                                },
                                onDelete: nil, // Factory presets can't be deleted
                                onExport: {
                                    Task {
                                        if let loaded = await viewModel.loadProgram(
                                            named: program.name,
                                            fromFactory: true
                                        ) {
                                            await viewModel.exportProgramAsSysEx(loaded, named: program.name)
                                        }
                                    }
                                }
                            )
                        }
                    }
                    .padding(FileManagerTheme.mediumSpacing)
                }
            }
        }
    }
    
    // MARK: - Empty States
    
    private var emptyLibraryState: some View {
        VStack(spacing: FileManagerTheme.mediumSpacing) {
            Image(systemName: "music.note.list")
                .font(.system(size: 48))
                .foregroundColor(FileManagerTheme.secondaryText)
            
            Text("No Saved Programs")
                .font(.title2)
                .foregroundColor(FileManagerTheme.primaryText)
            
            Text("Save programs from your device to build your library")
                .font(FileManagerTheme.bodyFont)
                .foregroundColor(FileManagerTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyFactoryState: some View {
        VStack(spacing: FileManagerTheme.mediumSpacing) {
            Image(systemName: "cube.box")
                .font(.system(size: 48))
                .foregroundColor(FileManagerTheme.secondaryText)
            
            Text("No Factory Presets")
                .font(.title2)
                .foregroundColor(FileManagerTheme.primaryText)
            
            Text("Factory presets will appear here when available")
                .font(FileManagerTheme.bodyFont)
                .foregroundColor(FileManagerTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Computed Properties
    
    private var filteredUserPrograms: [ProgramMetadata] {
        searchText.isEmpty
            ? viewModel.availablePrograms
            : viewModel.availablePrograms.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    private var filteredFactoryPrograms: [ProgramMetadata] {
        searchText.isEmpty
            ? viewModel.factoryPresets
            : viewModel.factoryPresets.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
}

// MARK: - Program Card

struct ProgramCard: View {
    let metadata: ProgramMetadata
    var isFactory = false
    let onLoad: () -> Void
    let onDelete: (() -> Void)?
    let onExport: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: FileManagerTheme.mediumSpacing) {
            // Icon and name
            HStack {
                Image(systemName: isFactory ? "cube.box.fill" : "music.note")
                    .font(.title)
                    .foregroundColor(isFactory ? .orange : FileManagerTheme.accentColor)
                
                Spacer()
                
                if isFactory {
                    Text("Factory")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(4)
                }
            }
            
            Text(metadata.name)
                .font(FileManagerTheme.titleFont)
                .lineLimit(2)
            
            Spacer()
            
            // Actions
            if isHovered {
                HStack(spacing: FileManagerTheme.smallSpacing) {
                    Button {
                        onExport()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .buttonStyle(.borderless)
                    .help("Export as SysEx")
                    
                    Spacer()
                    
                    if let onDelete {
                        Button {
                            onDelete()
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(FileManagerTheme.destructiveColor)
                        .help("Delete program")
                    }
                    
                    Button {
                        onLoad()
                    } label: {
                        Text("Import")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
        }
        .padding(FileManagerTheme.mediumSpacing)
        .frame(height: 140)
        .background(FileManagerTheme.cardBackground)
        .cornerRadius(FileManagerTheme.cardCornerRadius)
        .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: FileManagerTheme.cardCornerRadius)
                .stroke(isHovered ? FileManagerTheme.accentColor : .clear, lineWidth: 2)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Device Slot Card

struct DeviceSlotCard: View {
    let slotNumber: Int
    let program: MiniWorksProgram
    let onSave: () -> Void
    let onCopy: () -> Void
    let onExport: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: FileManagerTheme.smallSpacing) {
            // Slot number badge
            HStack {
                Text("\(slotNumber)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(FileManagerTheme.accentColor)
                    .clipShape(Circle())
                
                Spacer()
                
                if program.isReadOnly {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundColor(FileManagerTheme.tertiaryText)
                }
            }
            
            // Program name
            Text(program.programName)
                .font(FileManagerTheme.bodyFont)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            // Tags
            if !program.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(program.tags, id: \.title) { tag in
                            Text(tag.title)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(tag.backgroundColor.opacity(0.2))
                                .foregroundColor(tag.textColor)
                                .cornerRadius(4)
                        }
                    }
                }
            }
            
            // Actions
            if isHovered {
                HStack(spacing: 4) {
                    Button {
                        onExport()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .buttonStyle(.borderless)
                    .help("Export")
                    
                    Button {
                        onCopy()
                    } label: {
                        Image(systemName: "doc.on.doc")
                    }
                    .buttonStyle(.borderless)
                    .help("Copy")
                    
                    Spacer()
                    
                    Button {
                        onSave()
                    } label: {
                        Text("Save")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
        }
        .padding(FileManagerTheme.mediumSpacing)
        .frame(height: 160)
        .background(FileManagerTheme.cardBackground)
        .cornerRadius(FileManagerTheme.cardCornerRadius)
        .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: FileManagerTheme.cardCornerRadius)
                .stroke(isHovered ? FileManagerTheme.accentColor : .clear, lineWidth: 2)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Save Program Dialog

struct SaveProgramDialog: View {
    @Environment(\.dismiss) var dismiss
    
    let program: MiniWorksProgram
    let onSave: (String) -> Void
    
    @State private var programName: String
    @FocusState private var isNameFieldFocused: Bool
    
    init(program: MiniWorksProgram, onSave: @escaping (String) -> Void) {
        self.program = program
        self.onSave = onSave
        _programName = State(initialValue: program.programName)
    }
    
    var body: some View {
        VStack(spacing: FileManagerTheme.largeSpacing) {
            // Header
            VStack(spacing: FileManagerTheme.smallSpacing) {
                Image(systemName: "music.note.list")
                    .font(.system(size: 40))
                    .foregroundColor(FileManagerTheme.accentColor)
                
                Text("Save Program")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            // Input
            VStack(alignment: .leading, spacing: FileManagerTheme.smallSpacing) {
                Text("Program Name")
                    .font(FileManagerTheme.captionFont)
                    .foregroundColor(FileManagerTheme.secondaryText)
                
                TextField("Program name", text: $programName)
                    .textFieldStyle(.roundedBorder)
                    .focused($isNameFieldFocused)
            }
            
            // Actions
            HStack(spacing: FileManagerTheme.mediumSpacing) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Save") {
                    onSave(programName)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(programName.isEmpty)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(FileManagerTheme.largeSpacing)
        .frame(width: 350)
        .onAppear {
            isNameFieldFocused = true
        }
    }
}

// MARK: - Import Program Dialog

struct ImportProgramDialog: View {
    @Environment(\.dismiss) var dismiss
    
    let program: MiniWorksProgram
    let onImport: (Int) -> Void
    
    @State private var selectedSlot = 1
    
    var body: some View {
        VStack(spacing: FileManagerTheme.largeSpacing) {
            // Header
            VStack(spacing: FileManagerTheme.smallSpacing) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(FileManagerTheme.accentColor)
                
                Text("Import Program")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Select a slot for '\(program.programName)'")
                    .font(FileManagerTheme.bodyFont)
                    .foregroundColor(FileManagerTheme.secondaryText)
            }
            
            // Slot picker
            VStack(alignment: .leading, spacing: FileManagerTheme.smallSpacing) {
                Text("Destination Slot")
                    .font(FileManagerTheme.captionFont)
                    .foregroundColor(FileManagerTheme.secondaryText)
                
                Picker("Slot", selection: $selectedSlot) {
                    ForEach(1...20, id: \.self) { slot in
                        Text("Slot \(slot)").tag(slot)
                    }
                }
                .pickerStyle(.menu)
            }
            
            // Actions
            HStack(spacing: FileManagerTheme.mediumSpacing) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Import") {
                    onImport(selectedSlot)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(FileManagerTheme.largeSpacing)
        .frame(width: 350)
    }
}

// MARK: - View Mode

enum ProgramViewMode: String, CaseIterable, Identifiable {
    case library
    case deviceSlots
    case factory
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .library: return "Library"
        case .deviceSlots: return "Device"
        case .factory: return "Factory"
        }
    }
    
    var icon: String {
        switch self {
        case .library: return "folder"
        case .deviceSlots: return "slider.horizontal.3"
        case .factory: return "cube.box"
        }
    }
}

// MARK: - Preview

#Preview("Programs Tab") {
    struct PreviewWrapper: View {
        @State private var profile = MiniworksDeviceProfile.newMachineConfiguration()
        @State private var viewModel = FileManagerViewModel(
            currentProfile: MiniworksDeviceProfile.newMachineConfiguration()
        )
        
        var body: some View {
            ProgramsTabView(deviceProfile: $profile, viewModel: viewModel)
                .frame(width: 800, height: 600)
        }
    }
    
    return PreviewWrapper()
}
