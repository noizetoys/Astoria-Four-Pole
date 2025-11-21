import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - SwiftData Models

@Model
final class PersistedTag {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorRed: Double
    var colorGreen: Double
    var colorBlue: Double
    var colorAlpha: Double
    
    init(id: UUID, name: String, colorRed: Double, colorGreen: Double, colorBlue: Double, colorAlpha: Double) {
        self.id = id
        self.name = name
        self.colorRed = colorRed
        self.colorGreen = colorGreen
        self.colorBlue = colorBlue
        self.colorAlpha = colorAlpha
    }
    
    convenience init(from tag: Tag) {
        #if os(macOS)
        let nsColor = NSColor(tag.color)
        self.init(
            id: tag.id,
            name: tag.name,
            colorRed: Double(nsColor.redComponent),
            colorGreen: Double(nsColor.greenComponent),
            colorBlue: Double(nsColor.blueComponent),
            colorAlpha: Double(nsColor.alphaComponent)
        )
        #else
        let uiColor = UIColor(tag.color)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        self.init(
            id: tag.id,
            name: tag.name,
            colorRed: Double(red),
            colorGreen: Double(green),
            colorBlue: Double(blue),
            colorAlpha: Double(alpha)
        )
        #endif
    }
    
    func toTag() -> Tag {
        Tag(
            id: id,
            name: name,
            color: Color(red: colorRed, green: colorGreen, blue: colorBlue, opacity: colorAlpha)
        )
    }
}

@Model
final class PersistedPatch {
    @Attribute(.unique) var id: UUID
    var name: String
    var tagIDs: [UUID]
    var category: String
    var author: String
    var dateCreated: Date
    var dateModified: Date
    var notes: String
    var isFavorite: Bool
    var parametersData: Data?
    
    init(id: UUID, name: String, tagIDs: [UUID], category: String, author: String,
         dateCreated: Date, dateModified: Date, notes: String, isFavorite: Bool, parametersData: Data?) {
        self.id = id
        self.name = name
        self.tagIDs = tagIDs
        self.category = category
        self.author = author
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.notes = notes
        self.isFavorite = isFavorite
        self.parametersData = parametersData
    }
    
    convenience init(from patch: Patch) {
        let parametersData = try? JSONEncoder().encode(patch.parameters)
        self.init(
            id: patch.id,
            name: patch.name,
            tagIDs: patch.tags.map { $0.id },
            category: patch.category,
            author: patch.author,
            dateCreated: patch.dateCreated,
            dateModified: patch.dateModified,
            notes: patch.notes,
            isFavorite: patch.isFavorite,
            parametersData: parametersData
        )
    }
    
    func toPatch(availableTags: [Tag]) -> Patch {
        let tags = Set(availableTags.filter { tagIDs.contains($0.id) })
        let parameters: [String: Double]
        if let data = parametersData,
           let decoded = try? JSONDecoder().decode([String: Double].self, from: data) {
            parameters = decoded
        } else {
            parameters = Patch.defaultParameters()
        }
        
        return Patch(
            id: id,
            name: name,
            tags: tags,
            category: category,
            author: author,
            dateCreated: dateCreated,
            dateModified: dateModified,
            notes: notes,
            isFavorite: isFavorite,
            parameters: parameters
        )
    }
}

@Model
final class PersistedConfiguration {
    @Attribute(.unique) var id: UUID
    var name: String
    var dateCreated: Date
    var dateModified: Date
    var notes: String
    var patchIDs: [UUID?]  // Array of 20 optional patch IDs
    
    // Global data
    var masterVolume: Double
    var masterTuning: Double
    var midiChannel: Int
    var velocityCurveRaw: String
    var transpose: Int
    
    init(id: UUID, name: String, dateCreated: Date, dateModified: Date, notes: String,
         patchIDs: [UUID?], masterVolume: Double, masterTuning: Double, midiChannel: Int,
         velocityCurveRaw: String, transpose: Int) {
        self.id = id
        self.name = name
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.notes = notes
        self.patchIDs = patchIDs
        self.masterVolume = masterVolume
        self.masterTuning = masterTuning
        self.midiChannel = midiChannel
        self.velocityCurveRaw = velocityCurveRaw
        self.transpose = transpose
    }
    
    convenience init(from config: Configuration) {
        self.init(
            id: config.id,
            name: config.name,
            dateCreated: config.dateCreated,
            dateModified: config.dateModified,
            notes: config.notes,
            patchIDs: config.patches.map { $0?.id },
            masterVolume: config.globalData.masterVolume,
            masterTuning: config.globalData.masterTuning,
            midiChannel: config.globalData.midiChannel,
            velocityCurveRaw: config.globalData.velocityCurve.rawValue,
            transpose: config.globalData.transpose
        )
    }
    
    func toConfiguration(availablePatches: [Patch]) -> Configuration {
        let patchDict = Dictionary(uniqueKeysWithValues: availablePatches.map { ($0.id, $0) })
        let patches = patchIDs.map { id -> Patch? in
            guard let id = id else { return nil }
            return patchDict[id]
        }
        
        let globalData = GlobalData(
            masterVolume: masterVolume,
            masterTuning: masterTuning,
            midiChannel: midiChannel,
            velocityCurve: GlobalData.VelocityCurve(rawValue: velocityCurveRaw) ?? .linear,
            transpose: transpose
        )
        
        return Configuration(
            id: id,
            name: name,
            dateCreated: dateCreated,
            dateModified: dateModified,
            notes: notes,
            patches: patches,
            globalData: globalData
        )
    }
}

// MARK: - Value Type Models (for UI)

struct Tag: Identifiable, Hashable, Codable {
    var id: UUID
    var name: String
    var color: Color
    
    init(id: UUID = UUID(), name: String, color: Color) {
        self.id = id
        self.name = name
        self.color = color
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, colorComponents
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        let components = try container.decode([Double].self, forKey: .colorComponents)
        color = Color(red: components[0], green: components[1], blue: components[2], opacity: components[3])
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        #if os(macOS)
        let nsColor = NSColor(color)
        let components = [
            Double(nsColor.redComponent),
            Double(nsColor.greenComponent),
            Double(nsColor.blueComponent),
            Double(nsColor.alphaComponent)
        ]
        #else
        let uiColor = UIColor(color)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let components = [Double(red), Double(green), Double(blue), Double(alpha)]
        #endif
        try container.encode(components, forKey: .colorComponents)
    }
}

struct GlobalData: Codable, Equatable {
    var masterVolume: Double = 0.8
    var masterTuning: Double = 0.0
    var midiChannel: Int = 1
    var velocityCurve: VelocityCurve = .linear
    var transpose: Int = 0
    
    enum VelocityCurve: String, Codable, CaseIterable {
        case soft = "Soft"
        case linear = "Linear"
        case hard = "Hard"
        case fixed = "Fixed"
    }
}

struct Patch: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var tags: Set<Tag>
    var category: String
    var author: String
    var dateCreated: Date
    var dateModified: Date
    var notes: String
    var isFavorite: Bool
    var parameters: [String: Double]
    
    init(
        id: UUID = UUID(),
        name: String,
        tags: Set<Tag> = [],
        category: String = "Uncategorized",
        author: String = "",
        dateCreated: Date = Date(),
        dateModified: Date = Date(),
        notes: String = "",
        isFavorite: Bool = false,
        parameters: [String: Double] = [:]
    ) {
        self.id = id
        self.name = name
        self.tags = tags
        self.category = category
        self.author = author
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.notes = notes
        self.isFavorite = isFavorite
        self.parameters = parameters.isEmpty ? Self.defaultParameters() : parameters
    }
    
    static func defaultParameters() -> [String: Double] {
        return [
            "oscillator1_waveform": 0.0,
            "oscillator1_level": 0.5,
            "filter_cutoff": 0.7,
            "filter_resonance": 0.3,
            "envelope_attack": 0.01,
            "envelope_decay": 0.3,
            "envelope_sustain": 0.7,
            "envelope_release": 0.5
        ]
    }
}

struct Configuration: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var dateCreated: Date
    var dateModified: Date
    var globalData: GlobalData
    var patches: [Patch?]
    var notes: String
    
    init(
        id: UUID = UUID(),
        name: String,
        dateCreated: Date = Date(),
        dateModified: Date = Date(),
        notes: String = "",
        patches: [Patch?] = Array(repeating: nil, count: 20),
        globalData: GlobalData = GlobalData()
    ) {
        self.id = id
        self.name = name
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.globalData = globalData
        self.patches = patches
        self.notes = notes
    }
    
    var patchCount: Int {
        patches.compactMap { $0 }.count
    }
    
    mutating func setPatch(_ patch: Patch, at position: Int) {
        guard position >= 0 && position < 20 else { return }
        patches[position] = patch
        dateModified = Date()
    }
    
    mutating func clearPatch(at position: Int) {
        guard position >= 0 && position < 20 else { return }
        patches[position] = nil
        dateModified = Date()
    }
}

// MARK: - Undo Manager

enum UndoAction {
    case loadPatchToSlot(slot: Int, oldPatch: Patch?, newPatch: Patch?)
    case clearSlot(slot: Int, patch: Patch?)
    case deletePatch(patch: Patch)
    case deleteConfiguration(config: Configuration)
    case modifyPatch(oldPatch: Patch, newPatch: Patch)
    case createConfiguration(config: Configuration)
    case modifyConfiguration(oldConfig: Configuration, newConfig: Configuration)
}

@Observable
class UndoManager {
    private var undoStack: [UndoAction] = []
    private var redoStack: [UndoAction] = []
    private let maxStackSize = 50
    
    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }
    
    func registerUndo(_ action: UndoAction) {
        undoStack.append(action)
        if undoStack.count > maxStackSize {
            undoStack.removeFirst()
        }
        redoStack.removeAll()
    }
    
    func undo(viewModel: PatchLibraryViewModel) {
        guard let action = undoStack.popLast() else { return }
        
        switch action {
        case .loadPatchToSlot(let slot, let oldPatch, _):
            if let old = oldPatch {
                viewModel.loadPatchToSlot(old, slot: slot, registerUndo: false)
            } else {
                viewModel.clearSlot(slot, registerUndo: false)
            }
            
        case .clearSlot(let slot, let patch):
            if let patch = patch {
                viewModel.loadPatchToSlot(patch, slot: slot, registerUndo: false)
            }
            
        case .deletePatch(let patch):
            viewModel.restorePatch(patch)
            
        case .deleteConfiguration(let config):
            viewModel.restoreConfiguration(config)
            
        case .modifyPatch(let oldPatch, _):
            viewModel.updatePatchDirectly(oldPatch, registerUndo: false)
            
        case .createConfiguration(let config):
            viewModel.deleteConfiguration(config, registerUndo: false)
            
        case .modifyConfiguration(let oldConfig, _):
            viewModel.updateConfigurationDirectly(oldConfig, registerUndo: false)
        }
        
        redoStack.append(action)
    }
    
    func redo(viewModel: PatchLibraryViewModel) {
        guard let action = redoStack.popLast() else { return }
        
        switch action {
        case .loadPatchToSlot(let slot, _, let newPatch):
            if let new = newPatch {
                viewModel.loadPatchToSlot(new, slot: slot, registerUndo: false)
            } else {
                viewModel.clearSlot(slot, registerUndo: false)
            }
            
        case .clearSlot(let slot, _):
            viewModel.clearSlot(slot, registerUndo: false)
            
        case .deletePatch(let patch):
            viewModel.deletePatch(patch, registerUndo: false)
            
        case .deleteConfiguration(let config):
            viewModel.deleteConfiguration(config, registerUndo: false)
            
        case .modifyPatch(_, let newPatch):
            viewModel.updatePatchDirectly(newPatch, registerUndo: false)
            
        case .createConfiguration(let config):
            viewModel.restoreConfiguration(config)
            
        case .modifyConfiguration(_, let newConfig):
            viewModel.updateConfigurationDirectly(newConfig, registerUndo: false)
        }
        
        undoStack.append(action)
    }
    
    func clear() {
        undoStack.removeAll()
        redoStack.removeAll()
    }
}

// MARK: - Export/Import

struct PatchExportFormat: Codable {
    var version: String = "1.0"
    var patches: [Patch]
    var tags: [Tag]
    var exportDate: Date = Date()
}

struct ConfigurationExportFormat: Codable {
    var version: String = "1.0"
    var configuration: Configuration
    var patches: [Patch]
    var tags: [Tag]
    var exportDate: Date = Date()
}

extension UTType {
    static let patchLibrary = UTType(exportedAs: "com.patchmanager.patches")
    static let configurationFile = UTType(exportedAs: "com.patchmanager.configuration")
}

// MARK: - Persistence Manager

@Observable
class PersistenceManager {
    var modelContainer: ModelContainer?
    var modelContext: ModelContext?
    
    init() {
        setupContainer()
    }
    
    private func setupContainer() {
        let schema = Schema([
            PersistedTag.self,
            PersistedPatch.self,
            PersistedConfiguration.self
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            modelContext = ModelContext(modelContainer!)
        } catch {
            print("Failed to create model container: \(error)")
        }
    }
    
    // MARK: - Save Operations
    
    func saveTags(_ tags: [Tag]) throws {
        guard let context = modelContext else { return }
        
        // Delete existing tags
        try context.delete(model: PersistedTag.self)
        
        // Save new tags
        for tag in tags {
            let persistedTag = PersistedTag(from: tag)
            context.insert(persistedTag)
        }
        
        try context.save()
    }
    
    func savePatches(_ patches: [Patch]) throws {
        guard let context = modelContext else { return }
        
        // Delete existing patches
        try context.delete(model: PersistedPatch.self)
        
        // Save new patches
        for patch in patches {
            let persistedPatch = PersistedPatch(from: patch)
            context.insert(persistedPatch)
        }
        
        try context.save()
    }
    
    func saveConfigurations(_ configurations: [Configuration]) throws {
        guard let context = modelContext else { return }
        
        // Delete existing configurations
        try context.delete(model: PersistedConfiguration.self)
        
        // Save new configurations
        for config in configurations {
            let persistedConfig = PersistedConfiguration(from: config)
            context.insert(persistedConfig)
        }
        
        try context.save()
    }
    
    // MARK: - Load Operations
    
    func loadTags() throws -> [Tag] {
        guard let context = modelContext else { return [] }
        
        let descriptor = FetchDescriptor<PersistedTag>()
        let persistedTags = try context.fetch(descriptor)
        return persistedTags.map { $0.toTag() }
    }
    
    func loadPatches(availableTags: [Tag]) throws -> [Patch] {
        guard let context = modelContext else { return [] }
        
        let descriptor = FetchDescriptor<PersistedPatch>()
        let persistedPatches = try context.fetch(descriptor)
        return persistedPatches.map { $0.toPatch(availableTags: availableTags) }
    }
    
    func loadConfigurations(availablePatches: [Patch]) throws -> [Configuration] {
        guard let context = modelContext else { return [] }
        
        let descriptor = FetchDescriptor<PersistedConfiguration>()
        let persistedConfigs = try context.fetch(descriptor)
        return persistedConfigs.map { $0.toConfiguration(availablePatches: availablePatches) }
    }
}

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
    var configurations: [Configuration]
    var allPatches: [Patch]
    var availableTags: [Tag]
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
        
        // Try to load from persistence
        do {
            let tags = try persistenceManager.loadTags()
            self.availableTags = tags.isEmpty ? Self.createSampleTags() : tags
            
            let patches = try persistenceManager.loadPatches(availableTags: availableTags)
            self.allPatches = patches.isEmpty ? Self.createSamplePatches(tags: availableTags) : patches
            
            let configs = try persistenceManager.loadConfigurations(availablePatches: allPatches)
            self.configurations = configs.isEmpty ? Self.createSampleConfigurations(patches: allPatches) : configs
            
            self.currentConfiguration = configurations.first
        } catch {
            print("Failed to load from persistence: \(error)")
            // Fall back to sample data
            self.availableTags = Self.createSampleTags()
            self.allPatches = Self.createSamplePatches(tags: availableTags)
            self.configurations = Self.createSampleConfigurations(patches: allPatches)
            self.currentConfiguration = configurations.first
        }
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

// MARK: - Transferable for Drag & Drop

extension Patch: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .json)
    }
}

// MARK: - Main View (continued in next file due to length)

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

// Continue in next message due to length...
