//
//  PatchViewMode.swift
//  Check it Out
//
//  Created by James B. Majors on 11/20/25.
//
import Foundation
import Observation
import SwiftUI

// MARK: - View Models

enum PatchViewMode: Equatable {
    case allPatches
    case configuration(UUID)  // Store ID instead of value
}

enum SortOption: String, CaseIterable {
    case name = "Name"
    case dateCreated = "Date Created"
    case dateModified = "Date Modified"
    case category = "Category"
    case author = "Author"
}

@Observable
class PatchLibraryViewModel {
    var configurations: [Configuration] = []
    var allPatches: [Patch] = []
    var availableTags: [Tag] = []
    var currentConfiguration: Configuration?
    var patchEditor: PatchEditor?
    
    // Search and filter
    var searchText: String = ""
    var selectedTags: Set<Tag> = []
    var sortOption: SortOption = .name
    var sortAscending: Bool = true
    var viewMode: PatchViewMode = .allPatches
    var showFavoritesOnly: Bool = false
    
    // Keyboard navigation
    var selectedPatchIndex: Int?
    var focusedField: FocusField?
    
    // Undo/Redo
    var undoManager = UndoManager()
    
    // Persistence
    var persistenceManager: PersistenceManager
    
    // Drag and drop
    var draggedPatch: Patch?
    
    enum FocusField: Hashable {
        case search
        case patchList
    }
    
    init(persistenceManager: PersistenceManager = PersistenceManager()) {
        self.persistenceManager = persistenceManager

        // Build local values first to avoid using self before initialization
        let resolvedTags: [Tag]
        let resolvedPatches: [Patch]
        let resolvedConfigurations: [Configuration]
        let resolvedCurrentConfiguration: Configuration?

        do {
            let loadedTags = try persistenceManager.loadTags()
            let tags = loadedTags.isEmpty ? Self.createSampleTags() : loadedTags

            let loadedPatches = try persistenceManager.loadPatches(availableTags: tags)
            let patches = loadedPatches.isEmpty ? Self.createSamplePatches(tags: tags) : loadedPatches

            let loadedConfigs = try persistenceManager.loadConfigurations(availablePatches: patches)
            let configs = loadedConfigs.isEmpty ? Self.createSampleConfigurations(patches: patches) : loadedConfigs

            resolvedTags = tags
            resolvedPatches = patches
            resolvedConfigurations = configs
            resolvedCurrentConfiguration = configs.first
        } catch {
            print("Failed to load from persistence: \(error)")
            let tags = Self.createSampleTags()
            let patches = Self.createSamplePatches(tags: tags)
            let configs = Self.createSampleConfigurations(patches: patches)

            resolvedTags = tags
            resolvedPatches = patches
            resolvedConfigurations = configs
            resolvedCurrentConfiguration = configs.first
        }

        // Now assign to stored properties
        self.availableTags = resolvedTags
        self.allPatches = resolvedPatches
        self.configurations = resolvedConfigurations
        self.currentConfiguration = resolvedCurrentConfiguration
    }
    
    func saveAll() {
        do {
            try persistenceManager.saveTags(availableTags)
            try persistenceManager.savePatches(allPatches)
            try persistenceManager.saveConfigurations(configurations)
        } catch {
            print("Failed to save: \(error)")
        }
    }
    
    var filteredPatches: [Patch] {
        var patches: [Patch]
        
        switch viewMode {
        case .allPatches:
            patches = allPatches
        case .configuration(let id):
            if let config = configurations.first(where: { $0.id == id }) {
                patches = config.patches.compactMap { $0 }
            } else {
                patches = []
            }
        }
        
        if !searchText.isEmpty {
            patches = patches.filter { patch in
                patch.name.localizedCaseInsensitiveContains(searchText) ||
                patch.category.localizedCaseInsensitiveContains(searchText) ||
                patch.author.localizedCaseInsensitiveContains(searchText) ||
                patch.notes.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if !selectedTags.isEmpty {
            patches = patches.filter { patch in
                selectedTags.isSubset(of: patch.tags)
            }
        }
        
        if showFavoritesOnly {
            patches = patches.filter { $0.isFavorite }
        }
        
        return sortPatches(patches)
    }
    
    private func sortPatches(_ patches: [Patch]) -> [Patch] {
        let sorted = patches.sorted { lhs, rhs in
            let comparison: Bool
            switch sortOption {
            case .name:
                comparison = lhs.name.localizedCompare(rhs.name) == .orderedAscending
            case .dateCreated:
                comparison = lhs.dateCreated < rhs.dateCreated
            case .dateModified:
                comparison = lhs.dateModified < rhs.dateModified
            case .category:
                comparison = lhs.category.localizedCompare(rhs.category) == .orderedAscending
            case .author:
                comparison = lhs.author.localizedCompare(rhs.author) == .orderedAscending
            }
            return sortAscending ? comparison : !comparison
        }
        return sorted
    }
    
    // MARK: - Keyboard Navigation
    
    func handleKeyPress(_ key: KeyEquivalent) -> Bool {
        switch key {
        case .upArrow:
            moveSelectionUp()
            return true
        case .downArrow:
            moveSelectionDown()
            return true
        case .return:
            if let index = selectedPatchIndex {
                let patches = filteredPatches
                guard index < patches.count else { return false }
                loadPatchToEditor(patches[index])
                return true
            }
            return false
        default:
            return false
        }
    }
    
    private func moveSelectionUp() {
        if let current = selectedPatchIndex, current > 0 {
            selectedPatchIndex = current - 1
        } else {
            selectedPatchIndex = 0
        }
    }
    
    private func moveSelectionDown() {
        let count = filteredPatches.count
        if let current = selectedPatchIndex, current < count - 1 {
            selectedPatchIndex = current + 1
        } else if selectedPatchIndex == nil && count > 0 {
            selectedPatchIndex = 0
        }
    }
    
    // MARK: - Configuration Management
    
    func loadConfiguration(_ config: Configuration) {
        currentConfiguration = config
        saveAll()
    }
    
    func saveCurrentConfiguration() {
        guard let current = currentConfiguration else { return }
        if let index = configurations.firstIndex(where: { $0.id == current.id }) {
            let oldConfig = configurations[index]
            var updatedConfig = current
            updatedConfig.dateModified = Date()
            configurations[index] = updatedConfig
            currentConfiguration = updatedConfig
            undoManager.registerUndo(.modifyConfiguration(oldConfig: oldConfig, newConfig: updatedConfig))
            saveAll()
        }
    }
    
    func saveConfigurationAsNew(name: String) {
        guard var current = currentConfiguration else { return }
        current.id = UUID()
        current.name = name
        current.dateCreated = Date()
        current.dateModified = Date()
        configurations.append(current)
        currentConfiguration = current
        undoManager.registerUndo(.createConfiguration(config: current))
        saveAll()
    }
    
    func saveConfigurationAsCopy(name: String) {
        guard let current = currentConfiguration else { return }
        var copy = current
        copy.id = UUID()
        copy.name = name
        copy.dateCreated = Date()
        copy.dateModified = Date()
        configurations.append(copy)
        undoManager.registerUndo(.createConfiguration(config: copy))
        saveAll()
    }
    
    func deleteConfiguration(_ config: Configuration, registerUndo: Bool = true) {
        if registerUndo {
            undoManager.registerUndo(.deleteConfiguration(config: config))
        }
        configurations.removeAll { $0.id == config.id }
        if currentConfiguration?.id == config.id {
            currentConfiguration = configurations.first
        }
        saveAll()
    }
    
    func restoreConfiguration(_ config: Configuration) {
        configurations.append(config)
        saveAll()
    }
    
    func updateConfigurationDirectly(_ config: Configuration, registerUndo: Bool = true) {
        if let index = configurations.firstIndex(where: { $0.id == config.id }) {
            if registerUndo {
                undoManager.registerUndo(.modifyConfiguration(oldConfig: configurations[index], newConfig: config))
            }
            configurations[index] = config
            if currentConfiguration?.id == config.id {
                currentConfiguration = config
            }
            saveAll()
        }
    }
    
    // MARK: - Patch Management
    
    func loadPatchToEditor(_ patch: Patch) {
        patchEditor = PatchEditor(originalPatch: patch, isNewPatch: false)
    }
    
    func loadPatchToSlot(_ patch: Patch, slot: Int, registerUndo: Bool = true) {
        guard var config = currentConfiguration else { return }
        
        if registerUndo {
            let oldPatch = config.patches[slot]
            undoManager.registerUndo(.loadPatchToSlot(slot: slot, oldPatch: oldPatch, newPatch: patch))
        }
        
        config.setPatch(patch, at: slot)
        currentConfiguration = config
        
        if let index = configurations.firstIndex(where: { $0.id == config.id }) {
            configurations[index] = config
        }
        saveAll()
    }
    
    func clearSlot(_ slot: Int, registerUndo: Bool = true) {
        guard var config = currentConfiguration else { return }
        
        if registerUndo {
            let patch = config.patches[slot]
            undoManager.registerUndo(.clearSlot(slot: slot, patch: patch))
        }
        
        config.clearPatch(at: slot)
        currentConfiguration = config
        
        if let index = configurations.firstIndex(where: { $0.id == config.id }) {
            configurations[index] = config
        }
        saveAll()
    }
    
    func loadPatchesToSlots(_ patches: [Patch], startingAt: Int) {
        guard var config = currentConfiguration else { return }
        for (offset, patch) in patches.enumerated() {
            let slot = startingAt + offset
            guard slot < 20 else { break }
            config.setPatch(patch, at: slot)
        }
        currentConfiguration = config
        
        if let index = configurations.firstIndex(where: { $0.id == config.id }) {
            configurations[index] = config
        }
        saveAll()
    }
    
    func savePatchFromEditor(to slot: Int? = nil) {
        guard let editor = patchEditor else { return }
        var patch = editor.editedPatch
        patch.dateModified = Date()
        
        if editor.isNewPatch || editor.saveAsNew {
            allPatches.append(patch)
        } else {
            if let index = allPatches.firstIndex(where: { $0.id == editor.originalPatch.id }) {
                let oldPatch = allPatches[index]
                allPatches[index] = patch
                undoManager.registerUndo(.modifyPatch(oldPatch: oldPatch, newPatch: patch))
            }
        }
        
        if let slot = slot, var config = currentConfiguration {
            config.setPatch(patch, at: slot)
            currentConfiguration = config
            if let index = configurations.firstIndex(where: { $0.id == config.id }) {
                configurations[index] = config
            }
        }
        
        patchEditor = nil
        saveAll()
    }
    
    func deletePatch(_ patch: Patch, registerUndo: Bool = true) {
        if registerUndo {
            undoManager.registerUndo(.deletePatch(patch: patch))
        }
        
        allPatches.removeAll { $0.id == patch.id }
        
        for i in configurations.indices {
            for j in configurations[i].patches.indices {
                if configurations[i].patches[j]?.id == patch.id {
                    configurations[i].patches[j] = nil
                }
            }
        }
        saveAll()
    }
    
    func restorePatch(_ patch: Patch) {
        allPatches.append(patch)
        saveAll()
    }
    
    func updatePatchDirectly(_ patch: Patch, registerUndo: Bool = true) {
        if let index = allPatches.firstIndex(where: { $0.id == patch.id }) {
            if registerUndo {
                undoManager.registerUndo(.modifyPatch(oldPatch: allPatches[index], newPatch: patch))
            }
            allPatches[index] = patch
            saveAll()
        }
    }
    
    func toggleFavorite(_ patch: Patch) {
        if let index = allPatches.firstIndex(where: { $0.id == patch.id }) {
            let oldPatch = allPatches[index]
            var newPatch = oldPatch
            newPatch.isFavorite.toggle()
            allPatches[index] = newPatch
            undoManager.registerUndo(.modifyPatch(oldPatch: oldPatch, newPatch: newPatch))
            saveAll()
        }
    }
    
    // MARK: - Export/Import
    
    func exportPatches(_ patches: [Patch]) -> Data? {
        let allTags = Set(patches.flatMap { $0.tags })
        let exportFormat = PatchExportFormat(patches: patches, tags: Array(allTags))
        return try? JSONEncoder().encode(exportFormat)
    }
    
    func importPatches(from data: Data) throws -> [Patch] {
        let exportFormat = try JSONDecoder().decode(PatchExportFormat.self, from: data)
        
        // Merge tags
        for tag in exportFormat.tags {
            if !availableTags.contains(where: { $0.id == tag.id }) {
                availableTags.append(tag)
            }
        }
        
        // Add patches
        for patch in exportFormat.patches {
            if !allPatches.contains(where: { $0.id == patch.id }) {
                allPatches.append(patch)
            }
        }
        
        saveAll()
        return exportFormat.patches
    }
    
    func exportConfiguration(_ config: Configuration) -> Data? {
        let patches = config.patches.compactMap { $0 }
        let allTags = Set(patches.flatMap { $0.tags })
        let exportFormat = ConfigurationExportFormat(
            configuration: config,
            patches: patches,
            tags: Array(allTags)
        )
        return try? JSONEncoder().encode(exportFormat)
    }
    
    func importConfiguration(from data: Data) throws -> Configuration {
        let exportFormat = try JSONDecoder().decode(ConfigurationExportFormat.self, from: data)
        
        // Merge tags
        for tag in exportFormat.tags {
            if !availableTags.contains(where: { $0.id == tag.id }) {
                availableTags.append(tag)
            }
        }
        
        // Add patches
        for patch in exportFormat.patches {
            if !allPatches.contains(where: { $0.id == patch.id }) {
                allPatches.append(patch)
            }
        }
        
        // Add configuration
        var config = exportFormat.configuration
        config.id = UUID() // New ID to avoid conflicts
        configurations.append(config)
        
        saveAll()
        return config
    }
    
    // MARK: - Sample Data
    
    static func createSampleTags() -> [Tag] {
        return [
            Tag(name: "Bass", color: .blue),
            Tag(name: "Lead", color: .red),
            Tag(name: "Pad", color: .purple),
            Tag(name: "Pluck", color: .green),
            Tag(name: "FX", color: .orange),
            Tag(name: "Ambient", color: .cyan),
            Tag(name: "Aggressive", color: .pink),
            Tag(name: "Warm", color: .yellow)
        ]
    }
    
    static func createSamplePatches(tags: [Tag]) -> [Patch] {
        return [
            Patch(name: "Deep Bass", tags: [tags[0], tags[7]], category: "Bass", author: "Factory"),
            Patch(name: "Screaming Lead", tags: [tags[1], tags[6]], category: "Lead", author: "Factory"),
            Patch(name: "Warm Pad", tags: [tags[2], tags[7]], category: "Pad", author: "Factory"),
            Patch(name: "Mallet Pluck", tags: [tags[3]], category: "Pluck", author: "Factory"),
            Patch(name: "Ambient Space", tags: [tags[2], tags[5]], category: "Pad", author: "User"),
            Patch(name: "Wobble Bass", tags: [tags[0], tags[6]], category: "Bass", author: "User"),
            Patch(name: "Bright Lead", tags: [tags[1]], category: "Lead", author: "Factory"),
            Patch(name: "Sweep FX", tags: [tags[4]], category: "FX", author: "Factory"),
        ]
    }
    
    static func createSampleConfigurations(patches: [Patch]) -> [Configuration] {
        var config1 = Configuration(name: "Electronic Set")
        config1.setPatch(patches[0], at: 0)
        config1.setPatch(patches[1], at: 1)
        config1.setPatch(patches[2], at: 2)
        
        return [config1]
    }
}

@Observable
class PatchEditor {
    var originalPatch: Patch
    var editedPatch: Patch
    var isNewPatch: Bool
    var saveAsNew: Bool = false
    
    init(originalPatch: Patch, isNewPatch: Bool) {
        self.originalPatch = originalPatch
        self.editedPatch = originalPatch
        self.isNewPatch = isNewPatch
    }
    
    var hasChanges: Bool {
        editedPatch != originalPatch
    }
}

