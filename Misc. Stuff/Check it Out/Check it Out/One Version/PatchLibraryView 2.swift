//
//  PatchLibraryView.swift
//  Check it Out
//
//  Created by James B. Majors on 11/20/25.
//
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Main View

struct PatchLibraryView: View {
    @State private var viewModel: PatchLibraryViewModel
    @State private var activeSheet: SheetType?
    @FocusState private var focusedField: PatchLibraryViewModel.FocusField?
    
    init(viewModel: PatchLibraryViewModel = PatchLibraryViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }
    
    enum SheetType: Identifiable {
        case configurationEditor(Configuration?)
        case patchEditor
        case globalDataEditor
        case saveOptions
        case loadPatchOptions(Patch)
        case exportPatches([Patch])
        case exportConfiguration(Configuration)
        
        var id: String {
            switch self {
            case .configurationEditor(let config): return "configEdit-\(config?.id.uuidString ?? "new")"
            case .patchEditor: return "patchEdit"
            case .globalDataEditor: return "globalData"
            case .saveOptions: return "saveOptions"
            case .loadPatchOptions(let patch): return "loadOptions-\(patch.id)"
            case .exportPatches: return "exportPatches"
            case .exportConfiguration: return "exportConfig"
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            mainContent
        }
        .sheet(item: $activeSheet) { sheet in
            sheetContent(for: sheet)
        }
        .onAppear {
            viewModel.focusedField = focusedField
        }
        .onChange(of: focusedField) { _, new in
            viewModel.focusedField = new
        }
    }
    
    // MARK: - Sidebar
    
    private var sidebar: some View {
        List {
            Section("View") {
                Button {
                    viewModel.viewMode = .allPatches
                } label: {
                    Label("All Patches", systemImage: "square.grid.2x2")
                }
                
                if let config = viewModel.currentConfiguration {
                    Button {
                        viewModel.viewMode = .configuration(config.id)
                    } label: {
                        Label("Current Configuration", systemImage: "square.stack.3d.up")
                    }
                }
            }
            
            Section("Configurations") {
                ForEach(viewModel.configurations) { config in
                    configurationRow(config)
                }
                
                Button {
                    activeSheet = .configurationEditor(nil)
                } label: {
                    Label("New Configuration", systemImage: "plus")
                }
            }
        }
        .navigationTitle("Library")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Save Configuration") {
                        viewModel.saveCurrentConfiguration()
                    }
                    .disabled(viewModel.currentConfiguration == nil)
                    .keyboardShortcut("s", modifiers: .command)
                    
                    Button("Save As...") {
                        activeSheet = .saveOptions
                    }
                    .disabled(viewModel.currentConfiguration == nil)
                    
                    Divider()
                    
                    Button("Undo") {
                        viewModel.undoManager.undo(viewModel: viewModel)
                    }
                    .disabled(!viewModel.undoManager.canUndo)
                    .keyboardShortcut("z", modifiers: .command)
                    
                    Button("Redo") {
                        viewModel.undoManager.redo(viewModel: viewModel)
                    }
                    .disabled(!viewModel.undoManager.canRedo)
                    .keyboardShortcut("z", modifiers: [.command, .shift])
                    
                    Divider()
                    
                    Button("Global Settings") {
                        activeSheet = .globalDataEditor
                    }
                    
                    Divider()
                    
                    Button("Export Selected Patches...") {
                        activeSheet = .exportPatches(viewModel.filteredPatches)
                    }
                    
                    if let config = viewModel.currentConfiguration {
                        Button("Export Configuration...") {
                            activeSheet = .exportConfiguration(config)
                        }
                    }
                    
                    Button("Import...") {
                        showImportDialog()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
    
    private func configurationRow(_ config: Configuration) -> some View {
        Button {
            viewModel.viewMode = .configuration(config.id)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(config.name)
                    .font(.headline)
                Text("\(config.patchCount) patches")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .contextMenu {
            Button("Load Configuration") {
                viewModel.loadConfiguration(config)
            }
            Button("View Patches") {
                viewModel.viewMode = .configuration(config.id)
            }
            Button("Edit") {
                activeSheet = .configurationEditor(config)
            }
            Button("Export...") {
                activeSheet = .exportConfiguration(config)
            }
            Divider()
            Button("Delete", role: .destructive) {
                viewModel.deleteConfiguration(config)
            }
        }
        .dropDestination(for: Patch.self) { patches, _ in
            loadPatchesToConfiguration(patches, config: config)
            return true
        }
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            SearchFilterBar(viewModel: viewModel)
                .padding()
                .focused($focusedField, equals: .search)
            
            Divider()
            
            if case .configuration(let id) = viewModel.viewMode,
               let config = viewModel.configurations.first(where: { $0.id == id }) {
                ConfigurationSlotsView(
                    configuration: Binding(
                        get: { viewModel.currentConfiguration ?? config },
                        set: { viewModel.currentConfiguration = $0 }
                    ),
                    viewModel: viewModel,
                    onLoadPatch: { patch in
                        activeSheet = .loadPatchOptions(patch)
                    }
                )
            } else {
                PatchListView(
                    patches: viewModel.filteredPatches,
                    selectedIndex: $viewModel.selectedPatchIndex,
                    onSelect: { patch in
                        activeSheet = .loadPatchOptions(patch)
                    },
                    onEdit: { patch in
                        viewModel.loadPatchToEditor(patch)
                        activeSheet = .patchEditor
                    },
                    onToggleFavorite: { patch in
                        viewModel.toggleFavorite(patch)
                    },
                    onDelete: { patch in
                        viewModel.deletePatch(patch)
                    },
                    onDragStart: { patch in
                        viewModel.draggedPatch = patch
                    }
                )
                .focused($focusedField, equals: .patchList)
            }
        }
        .navigationTitle(viewModeTitle)
    }
    
    private var viewModeTitle: String {
        switch viewModel.viewMode {
        case .allPatches:
            return "All Patches (\(viewModel.filteredPatches.count))"
        case .configuration(let id):
            if let config = viewModel.configurations.first(where: { $0.id == id }) {
                return config.name
            }
            return "Configuration"
        }
    }
    
    // MARK: - Sheet Content
    
    @ViewBuilder
    private func sheetContent(for sheet: SheetType) -> some View {
        switch sheet {
        case .configurationEditor(let config):
            ConfigurationEditorView(
                configuration: config,
                onSave: { newConfig in
                    if let existing = config {
                        if let index = viewModel.configurations.firstIndex(where: { $0.id == existing.id }) {
                            viewModel.configurations[index] = newConfig
                        }
                    } else {
                        viewModel.configurations.append(newConfig)
                    }
                    viewModel.saveAll()
                    activeSheet = nil
                },
                onCancel: { activeSheet = nil }
            )
            
        case .patchEditor:
            if let editor = viewModel.patchEditor {
                PatchEditorView(
                    editor: editor,
                    availableTags: viewModel.availableTags,
                    onSave: { slot in
                        viewModel.savePatchFromEditor(to: slot)
                        activeSheet = nil
                    },
                    onCancel: {
                        viewModel.patchEditor = nil
                        activeSheet = nil
                    }
                )
            }
            
        case .globalDataEditor:
            if let config = viewModel.currentConfiguration {
                GlobalDataEditorView(
                    globalData: Binding(
                        get: { config.globalData },
                        set: { newData in
                            if var current = viewModel.currentConfiguration {
                                current.globalData = newData
                                viewModel.currentConfiguration = current
                                viewModel.saveAll()
                            }
                        }
                    ),
                    onDone: { activeSheet = nil }
                )
            }
            
        case .saveOptions:
            SaveOptionsView(
                onSave: {
                    viewModel.saveCurrentConfiguration()
                    activeSheet = nil
                },
                onSaveAsNew: { name in
                    viewModel.saveConfigurationAsNew(name: name)
                    activeSheet = nil
                },
                onSaveAsCopy: { name in
                    viewModel.saveConfigurationAsCopy(name: name)
                    activeSheet = nil
                },
                onCancel: { activeSheet = nil }
            )
            
        case .loadPatchOptions(let patch):
            LoadPatchOptionsView(
                patch: patch,
                onLoadToEditor: {
                    viewModel.loadPatchToEditor(patch)
                    activeSheet = .patchEditor
                },
                onLoadToSlot: { slot in
                    viewModel.loadPatchToSlot(patch, slot: slot)
                    activeSheet = nil
                },
                onCancel: { activeSheet = nil }
            )
            
        case .exportPatches(let patches):
            ExportPatchesView(
                patches: patches,
                viewModel: viewModel,
                onDone: { activeSheet = nil }
            )
            
        case .exportConfiguration(let config):
            ExportConfigurationView(
                configuration: config,
                viewModel: viewModel,
                onDone: { activeSheet = nil }
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func showImportDialog() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.json]
        
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            
            do {
                let data = try Data(contentsOf: url)
                
                // Try configuration first
                if let _ = try? viewModel.importConfiguration(from: data) {
                    // Success
                    return
                }
                
                // Try patches
                if let _ = try? viewModel.importPatches(from: data) {
                    // Success
                    return
                }
                
                // Unknown format
                print("Unknown file format")
            } catch {
                print("Import failed: \(error)")
            }
        }
    }
    
    private func loadPatchesToConfiguration(_ patches: [Patch], config: Configuration) {
        guard var updatedConfig = viewModel.configurations.first(where: { $0.id == config.id }) else { return }
        
        // Find first empty slot
        if let emptySlot = updatedConfig.patches.firstIndex(where: { $0 == nil }) {
            for (offset, patch) in patches.enumerated() {
                let slot = emptySlot + offset
                guard slot < 20 else { break }
                updatedConfig.setPatch(patch, at: slot)
            }
            
            if let index = viewModel.configurations.firstIndex(where: { $0.id == config.id }) {
                viewModel.configurations[index] = updatedConfig
                viewModel.saveAll()
            }
        }
    }
}
