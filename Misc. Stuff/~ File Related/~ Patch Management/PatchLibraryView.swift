import SwiftUI

// MARK: - Models

struct Tag: Identifiable, Hashable, Codable {
    var id = UUID()
    var name: String
    var color: Color
    
    enum CodingKeys: String, CodingKey {
        case id, name, colorComponents
    }
    
    init(name: String, color: Color) {
        self.name = name
        self.color = color
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
    var masterTuning: Double = 0.0  // -50 to +50 cents
    var midiChannel: Int = 1
    var velocityCurve: VelocityCurve = .linear
    var transpose: Int = 0  // -24 to +24 semitones
    
    enum VelocityCurve: String, Codable, CaseIterable {
        case soft = "Soft"
        case linear = "Linear"
        case hard = "Hard"
        case fixed = "Fixed"
    }
}

struct Patch: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var tags: Set<Tag>
    var category: String
    var author: String
    var dateCreated: Date
    var dateModified: Date
    var notes: String
    var isFavorite: Bool
    
    // Simplified patch parameters (in real implementation, this would be much more complex)
    var parameters: [String: Double]
    
    init(
        name: String,
        tags: Set<Tag> = [],
        category: String = "Uncategorized",
        author: String = "",
        notes: String = "",
        isFavorite: Bool = false,
        parameters: [String: Double] = [:]
    ) {
        self.id = UUID()
        self.name = name
        self.tags = tags
        self.category = category
        self.author = author
        self.dateCreated = Date()
        self.dateModified = Date()
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
    var id = UUID()
    var name: String
    var dateCreated: Date
    var dateModified: Date
    var globalData: GlobalData
    var patches: [Patch?]  // Array of 20 optional patches
    var notes: String
    
    init(name: String, notes: String = "") {
        self.id = UUID()
        self.name = name
        self.dateCreated = Date()
        self.dateModified = Date()
        self.globalData = GlobalData()
        self.patches = Array(repeating: nil, count: 20)
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

// MARK: - View Models

enum PatchViewMode {
    case allPatches
    case configuration(Configuration)
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
    
    init() {
        // Initialize with sample data
        self.availableTags = [
            Tag(name: "Bass", color: .blue),
            Tag(name: "Lead", color: .red),
            Tag(name: "Pad", color: .purple),
            Tag(name: "Pluck", color: .green),
            Tag(name: "FX", color: .orange),
            Tag(name: "Ambient", color: .cyan),
            Tag(name: "Aggressive", color: .pink),
            Tag(name: "Warm", color: .yellow)
        ]
        
        // Create sample patches
        self.allPatches = Self.createSamplePatches(tags: availableTags)
        
        // Create sample configurations
        self.configurations = Self.createSampleConfigurations(patches: allPatches)
        
        self.currentConfiguration = configurations.first
    }
    
    var filteredPatches: [Patch] {
        var patches: [Patch]
        
        // Determine source patches
        switch viewMode {
        case .allPatches:
            patches = allPatches
        case .configuration(let config):
            patches = config.patches.compactMap { $0 }
        }
        
        // Apply filters
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
        
        // Apply sorting
        patches = sortPatches(patches)
        
        return patches
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
    
    // MARK: - Configuration Management
    
    func loadConfiguration(_ config: Configuration) {
        currentConfiguration = config
    }
    
    func saveCurrentConfiguration() {
        guard let current = currentConfiguration else { return }
        if let index = configurations.firstIndex(where: { $0.id == current.id }) {
            var updatedConfig = current
            updatedConfig.dateModified = Date()
            configurations[index] = updatedConfig
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
    }
    
    func saveConfigurationAsCopy(name: String) {
        guard let current = currentConfiguration else { return }
        var copy = current
        copy.id = UUID()
        copy.name = name
        copy.dateCreated = Date()
        copy.dateModified = Date()
        configurations.append(copy)
    }
    
    func deleteConfiguration(_ config: Configuration) {
        configurations.removeAll { $0.id == config.id }
        if currentConfiguration?.id == config.id {
            currentConfiguration = configurations.first
        }
    }
    
    // MARK: - Patch Management
    
    func loadPatchToEditor(_ patch: Patch) {
        patchEditor = PatchEditor(originalPatch: patch, isNewPatch: false)
    }
    
    func loadPatchToSlot(_ patch: Patch, slot: Int) {
        guard var config = currentConfiguration else { return }
        config.setPatch(patch, at: slot)
        currentConfiguration = config
        
        // Update in configurations array
        if let index = configurations.firstIndex(where: { $0.id == config.id }) {
            configurations[index] = config
        }
    }
    
    func loadPatchesToSlots(_ patches: [Patch], startingAt: Int) {
        guard var config = currentConfiguration else { return }
        for (offset, patch) in patches.enumerated() {
            let slot = startingAt + offset
            guard slot < 20 else { break }
            config.setPatch(patch, at: slot)
        }
        currentConfiguration = config
        
        // Update in configurations array
        if let index = configurations.firstIndex(where: { $0.id == config.id }) {
            configurations[index] = config
        }
    }
    
    func savePatchFromEditor(to slot: Int? = nil) {
        guard let editor = patchEditor else { return }
        var patch = editor.editedPatch
        patch.dateModified = Date()
        
        if editor.isNewPatch || editor.saveAsNew {
            // Add to all patches
            allPatches.append(patch)
        } else {
            // Update existing patch
            if let index = allPatches.firstIndex(where: { $0.id == editor.originalPatch.id }) {
                allPatches[index] = patch
            }
        }
        
        // If slot specified, also add to current configuration
        if let slot = slot, var config = currentConfiguration {
            config.setPatch(patch, at: slot)
            currentConfiguration = config
            if let index = configurations.firstIndex(where: { $0.id == config.id }) {
                configurations[index] = config
            }
        }
        
        patchEditor = nil
    }
    
    func deletePatch(_ patch: Patch) {
        allPatches.removeAll { $0.id == patch.id }
        
        // Remove from all configurations
        for i in configurations.indices {
            for j in configurations[i].patches.indices {
                if configurations[i].patches[j]?.id == patch.id {
                    configurations[i].patches[j] = nil
                }
            }
        }
    }
    
    func toggleFavorite(_ patch: Patch) {
        if let index = allPatches.firstIndex(where: { $0.id == patch.id }) {
            allPatches[index].isFavorite.toggle()
        }
    }
    
    // MARK: - Sample Data
    
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
            Patch(name: "Sub Bass", tags: [tags[0]], category: "Bass", author: "User"),
            Patch(name: "Ethereal Pad", tags: [tags[2], tags[5], tags[7]], category: "Pad", author: "User"),
            Patch(name: "Synth Brass", tags: [tags[1], tags[6]], category: "Lead", author: "Factory"),
            Patch(name: "Bell Pluck", tags: [tags[3]], category: "Pluck", author: "Factory"),
            Patch(name: "Riser FX", tags: [tags[4]], category: "FX", author: "User"),
            Patch(name: "Fat Bass", tags: [tags[0], tags[7]], category: "Bass", author: "Factory"),
            Patch(name: "Soft Lead", tags: [tags[1], tags[7]], category: "Lead", author: "User"),
        ]
    }
    
    static func createSampleConfigurations(patches: [Patch]) -> [Configuration] {
        var config1 = Configuration(name: "Electronic Set")
        config1.setPatch(patches[0], at: 0)
        config1.setPatch(patches[1], at: 1)
        config1.setPatch(patches[2], at: 2)
        config1.setPatch(patches[7], at: 3)
        
        var config2 = Configuration(name: "Performance Set")
        config2.setPatch(patches[6], at: 0)
        config2.setPatch(patches[13], at: 1)
        config2.setPatch(patches[9], at: 2)
        
        return [config1, config2]
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

// MARK: - Views

struct PatchLibraryView: View {
    @State private var viewModel = PatchLibraryViewModel()
    @State private var activeSheet: SheetType?
    @State private var selectedPatchForSlot: Patch?
    @State private var showSlotPicker = false
    
    enum SheetType: Identifiable {
        case configurationList
        case configurationEditor(Configuration?)
        case patchEditor
        case globalDataEditor
        case saveOptions
        case loadPatchOptions(Patch)
        
        var id: String {
            switch self {
            case .configurationList: return "configList"
            case .configurationEditor(let config): return "configEdit-\(config?.id.uuidString ?? "new")"
            case .patchEditor: return "patchEdit"
            case .globalDataEditor: return "globalData"
            case .saveOptions: return "saveOptions"
            case .loadPatchOptions(let patch): return "loadOptions-\(patch.id)"
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            List {
                Section("View") {
                    Button {
                        viewModel.viewMode = .allPatches
                    } label: {
                        Label("All Patches", systemImage: "square.grid.2x2")
                    }
                    
                    if let config = viewModel.currentConfiguration {
                        Button {
                            viewModel.viewMode = .configuration(config)
                        } label: {
                            Label("Current Configuration", systemImage: "square.stack.3d.up")
                        }
                    }
                }
                
                Section("Configurations") {
                    ForEach(viewModel.configurations) { config in
                        Button {
                            viewModel.viewMode = .configuration(config)
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
                                viewModel.viewMode = .configuration(config)
                            }
                            Button("Edit") {
                                activeSheet = .configurationEditor(config)
                            }
                            Divider()
                            Button("Delete", role: .destructive) {
                                viewModel.deleteConfiguration(config)
                            }
                        }
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
                        
                        Button("Save As...") {
                            activeSheet = .saveOptions
                        }
                        .disabled(viewModel.currentConfiguration == nil)
                        
                        Divider()
                        
                        Button("Global Settings") {
                            activeSheet = .globalDataEditor
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        } detail: {
            // Main content
            VStack(spacing: 0) {
                // Search and filter bar
                SearchFilterBar(viewModel: viewModel)
                    .padding()
                
                Divider()
                
                // Patch list or configuration view
                if case .configuration(let config) = viewModel.viewMode {
                    ConfigurationSlotsView(
                        configuration: Binding(
                            get: { viewModel.currentConfiguration ?? config },
                            set: { viewModel.currentConfiguration = $0 }
                        ),
                        onLoadPatch: { patch in
                            selectedPatchForSlot = patch
                            activeSheet = .loadPatchOptions(patch)
                        }
                    )
                } else {
                    PatchListView(
                        patches: viewModel.filteredPatches,
                        onSelect: { patch in
                            selectedPatchForSlot = patch
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
                        }
                    )
                }
            }
            .navigationTitle(viewModeTitle)
        }
        .sheet(item: $activeSheet) { sheet in
            sheetContent(for: sheet)
        }
    }
    
    var viewModeTitle: String {
        switch viewModel.viewMode {
        case .allPatches:
            return "All Patches (\(viewModel.filteredPatches.count))"
        case .configuration(let config):
            return config.name
        }
    }
    
    @ViewBuilder
    private func sheetContent(for sheet: SheetType) -> some View {
        switch sheet {
        case .configurationList:
            Text("Configuration List")
            
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
                    activeSheet = nil
                },
                onCancel: {
                    activeSheet = nil
                }
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
                            }
                        }
                    ),
                    onDone: {
                        activeSheet = nil
                    }
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
                onCancel: {
                    activeSheet = nil
                }
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
                onCancel: {
                    activeSheet = nil
                }
            )
        }
    }
}

// MARK: - Search and Filter

struct SearchFilterBar: View {
    @Bindable var viewModel: PatchLibraryViewModel
    @State private var showTagFilter = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                
                TextField("Search patches...", text: $viewModel.searchText)
                
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            HStack {
                Button {
                    showTagFilter.toggle()
                } label: {
                    HStack {
                        Image(systemName: "tag")
                        Text("Filter by Tags")
                        if !viewModel.selectedTags.isEmpty {
                            Text("(\(viewModel.selectedTags.count))")
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: showTagFilter ? "chevron.up" : "chevron.down")
                    }
                }
                .buttonStyle(.plain)
                
                Divider()
                    .frame(height: 20)
                
                Toggle("Favorites", isOn: $viewModel.showFavoritesOnly)
                    .toggleStyle(.switch)
                
                Divider()
                    .frame(height: 20)
                
                Picker("Sort", selection: $viewModel.sortOption) {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 150)
                
                Button {
                    viewModel.sortAscending.toggle()
                } label: {
                    Image(systemName: viewModel.sortAscending ? "arrow.up" : "arrow.down")
                }
                .buttonStyle(.plain)
            }
            .padding(8)
            .background(Color(.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            if showTagFilter {
                TagFilterView(
                    tags: viewModel.availableTags,
                    selectedTags: $viewModel.selectedTags
                )
                .transition(.opacity)
            }
        }
    }
}

struct TagFilterView: View {
    let tags: [Tag]
    @Binding var selectedTags: Set<Tag>
    
    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(tags) { tag in
                TagChip(
                    tag: tag,
                    isSelected: selectedTags.contains(tag)
                ) {
                    if selectedTags.contains(tag) {
                        selectedTags.remove(tag)
                    } else {
                        selectedTags.insert(tag)
                    }
                }
            }
        }
        .padding(12)
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct TagChip: View {
    let tag: Tag
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Text(tag.name)
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isSelected ? tag.color : tag.color.opacity(0.2))
            .foregroundStyle(isSelected ? .white : tag.color)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(tag.color.opacity(0.3), lineWidth: isSelected ? 0 : 1)
            )
            .onTapGesture(perform: action)
    }
}

// MARK: - Patch List View

struct PatchListView: View {
    let patches: [Patch]
    let onSelect: (Patch) -> Void
    let onEdit: (Patch) -> Void
    let onToggleFavorite: (Patch) -> Void
    let onDelete: (Patch) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(patches) { patch in
                    PatchCard(
                        patch: patch,
                        onSelect: { onSelect(patch) },
                        onEdit: { onEdit(patch) },
                        onToggleFavorite: { onToggleFavorite(patch) },
                        onDelete: { onDelete(patch) }
                    )
                }
            }
            .padding()
        }
    }
}

struct PatchCard: View {
    let patch: Patch
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onToggleFavorite: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(patch.name)
                            .font(.headline)
                        
                        if patch.isFavorite {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                                .font(.caption)
                        }
                    }
                    
                    HStack {
                        Text(patch.category)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text("•")
                            .foregroundStyle(.secondary)
                        
                        Text(patch.author)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                Menu {
                    Button("Load to Slot...") {
                        onSelect()
                    }
                    
                    Button("Edit") {
                        onEdit()
                    }
                    
                    Button(patch.isFavorite ? "Remove from Favorites" : "Add to Favorites") {
                        onToggleFavorite()
                    }
                    
                    Divider()
                    
                    Button("Delete", role: .destructive) {
                        onDelete()
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            if !patch.tags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(Array(patch.tags)) { tag in
                        TagChip(tag: tag, isSelected: false) { }
                    }
                }
            }
            
            if !patch.notes.isEmpty {
                Text(patch.notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Configuration Slots View

struct ConfigurationSlotsView: View {
    @Binding var configuration: Configuration
    let onLoadPatch: (Patch) -> Void
    
    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 12)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Configuration info
                VStack(alignment: .leading, spacing: 8) {
                    Text(configuration.name)
                        .font(.title2)
                        .bold()
                    
                    Text("\(configuration.patchCount) of 20 patches loaded")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                
                // Patch slots
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(0..<20, id: \.self) { index in
                        PatchSlotView(
                            slotNumber: index + 1,
                            patch: configuration.patches[index],
                            onTap: {
                                if let patch = configuration.patches[index] {
                                    onLoadPatch(patch)
                                }
                            }
                        )
                    }
                }
                .padding()
            }
        }
    }
}

struct PatchSlotView: View {
    let slotNumber: Int
    let patch: Patch?
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(slotNumber)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 30, alignment: .leading)
                
                Spacer()
                
                if let patch = patch, patch.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption2)
                }
            }
            
            if let patch = patch {
                VStack(alignment: .leading, spacing: 4) {
                    Text(patch.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(2)
                    
                    Text(patch.category)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Empty")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .italic()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(patch != nil ? Color(.controlBackgroundColor) : Color(.controlBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(patch != nil ? Color.clear : Color(.separatorColor), lineWidth: 1)
        )
        .onTapGesture(perform: onTap)
    }
}

// MARK: - Configuration Editor

struct ConfigurationEditorView: View {
    let configuration: Configuration?
    let onSave: (Configuration) -> Void
    let onCancel: () -> Void
    
    @State private var editedConfig: Configuration
    
    init(configuration: Configuration?, onSave: @escaping (Configuration) -> Void, onCancel: @escaping () -> Void) {
        self.configuration = configuration
        self.onSave = onSave
        self.onCancel = onCancel
        _editedConfig = State(initialValue: configuration ?? Configuration(name: "New Configuration"))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(configuration == nil ? "New Configuration" : "Edit Configuration")
                    .font(.headline)
                
                Spacer()
                
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                
                Button("Save") {
                    onSave(editedConfig)
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            
            Divider()
            
            // Content
            Form {
                Section("Details") {
                    TextField("Name", text: $editedConfig.name)
                    TextField("Notes", text: $editedConfig.notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .formStyle(.grouped)
        }
        .frame(minWidth: 400, minHeight: 300)
    }
}

// MARK: - Patch Editor

struct PatchEditorView: View {
    @Bindable var editor: PatchEditor
    let availableTags: [Tag]
    let onSave: (Int?) -> Void
    let onCancel: () -> Void
    
    @State private var saveToSlot: Int?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(editor.isNewPatch ? "New Patch" : "Edit Patch")
                    .font(.headline)
                
                Spacer()
                
                if !editor.isNewPatch {
                    Toggle("Save as New", isOn: $editor.saveAsNew)
                }
                
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                
                Button("Save") {
                    onSave(saveToSlot)
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            
            Divider()
            
            // Content
            Form {
                Section("Details") {
                    TextField("Name", text: $editor.editedPatch.name)
                    
                    Picker("Category", selection: $editor.editedPatch.category) {
                        Text("Bass").tag("Bass")
                        Text("Lead").tag("Lead")
                        Text("Pad").tag("Pad")
                        Text("Pluck").tag("Pluck")
                        Text("FX").tag("FX")
                    }
                    
                    TextField("Author", text: $editor.editedPatch.author)
                    
                    TextField("Notes", text: $editor.editedPatch.notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Tags") {
                    TagSelectorView(
                        availableTags: availableTags,
                        selectedTags: $editor.editedPatch.tags
                    )
                }
                
                Section("Save to Slot") {
                    Picker("Slot", selection: $saveToSlot) {
                        Text("Don't add to configuration").tag(nil as Int?)
                        ForEach(1...20, id: \.self) { slot in
                            Text("Slot \(slot)").tag(slot - 1 as Int?)
                        }
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(minWidth: 500, minHeight: 500)
    }
}

struct TagSelectorView: View {
    let availableTags: [Tag]
    @Binding var selectedTags: Set<Tag>
    
    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(availableTags) { tag in
                TagChip(
                    tag: tag,
                    isSelected: selectedTags.contains(tag)
                ) {
                    if selectedTags.contains(tag) {
                        selectedTags.remove(tag)
                    } else {
                        selectedTags.insert(tag)
                    }
                }
            }
        }
    }
}

// MARK: - Global Data Editor

struct GlobalDataEditorView: View {
    @Binding var globalData: GlobalData
    let onDone: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Global Settings")
                    .font(.headline)
                
                Spacer()
                
                Button("Done", action: onDone)
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            
            Divider()
            
            // Content
            Form {
                Section("Audio") {
                    HStack {
                        Text("Master Volume")
                        Slider(value: $globalData.masterVolume, in: 0...1)
                        Text("\(Int(globalData.masterVolume * 100))%")
                            .frame(width: 50, alignment: .trailing)
                    }
                    
                    HStack {
                        Text("Master Tuning")
                        Slider(value: $globalData.masterTuning, in: -50...50)
                        Text("\(Int(globalData.masterTuning)) cents")
                            .frame(width: 70, alignment: .trailing)
                    }
                    
                    Stepper("Transpose: \(globalData.transpose) semitones",
                            value: $globalData.transpose,
                            in: -24...24)
                }
                
                Section("MIDI") {
                    Stepper("MIDI Channel: \(globalData.midiChannel)",
                            value: $globalData.midiChannel,
                            in: 1...16)
                    
                    Picker("Velocity Curve", selection: $globalData.velocityCurve) {
                        ForEach(GlobalData.VelocityCurve.allCases, id: \.self) { curve in
                            Text(curve.rawValue).tag(curve)
                        }
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(minWidth: 450, minHeight: 400)
    }
}

// MARK: - Save Options

struct SaveOptionsView: View {
    let onSave: () -> Void
    let onSaveAsNew: (String) -> Void
    let onSaveAsCopy: (String) -> Void
    let onCancel: () -> Void
    
    @State private var newName = ""
    @State private var selectedOption: SaveOption = .update
    
    enum SaveOption {
        case update
        case new
        case copy
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Save Configuration")
                    .font(.headline)
                
                Spacer()
                
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                
                Button("Save") {
                    switch selectedOption {
                    case .update:
                        onSave()
                    case .new:
                        onSaveAsNew(newName)
                    case .copy:
                        onSaveAsCopy(newName)
                    }
                }
                .disabled(selectedOption != .update && newName.isEmpty)
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            
            Divider()
            
            // Content
            Form {
                Picker("Save Option", selection: $selectedOption) {
                    Text("Update Current").tag(SaveOption.update)
                    Text("Save As New").tag(SaveOption.new)
                    Text("Save As Copy").tag(SaveOption.copy)
                }
                .pickerStyle(.radioGroup)
                
                if selectedOption != .update {
                    TextField("Name", text: $newName)
                }
                
                Section {
                    switch selectedOption {
                    case .update:
                        Text("Updates the current configuration with any changes made.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    case .new:
                        Text("Saves as a new configuration and makes it current. The original is preserved.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    case .copy:
                        Text("Creates a copy of the current configuration. Current configuration remains active.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(minWidth: 400, minHeight: 300)
    }
}

// MARK: - Load Patch Options

struct LoadPatchOptionsView: View {
    let patch: Patch
    let onLoadToEditor: () -> Void
    let onLoadToSlot: (Int) -> Void
    let onCancel: () -> Void
    
    @State private var selectedSlot: Int = 0
    @State private var selectedOption: LoadOption = .editor
    
    enum LoadOption {
        case editor
        case slot
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Load Patch")
                    .font(.headline)
                
                Spacer()
                
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                
                Button("Load") {
                    switch selectedOption {
                    case .editor:
                        onLoadToEditor()
                    case .slot:
                        onLoadToSlot(selectedSlot)
                    }
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            
            Divider()
            
            // Content
            Form {
                Section("Patch") {
                    Text(patch.name)
                        .font(.headline)
                    Text(patch.category)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Picker("Load to", selection: $selectedOption) {
                    Text("Editor (for editing)").tag(LoadOption.editor)
                    Text("Configuration Slot").tag(LoadOption.slot)
                }
                .pickerStyle(.radioGroup)
                
                if selectedOption == .slot {
                    Picker("Slot", selection: $selectedSlot) {
                        ForEach(0..<20, id: \.self) { slot in
                            Text("Slot \(slot + 1)").tag(slot)
                        }
                    }
                }
                
                Section {
                    switch selectedOption {
                    case .editor:
                        Text("Opens the patch in the editor where you can modify it and save to a slot or as a new patch.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    case .slot:
                        Text("Loads the patch directly into the selected slot, overwriting any existing patch.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(minWidth: 400, minHeight: 350)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowLayoutResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowLayoutResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        
        for (index, subview) in subviews.enumerated() {
            subview.place(
                at: CGPoint(
                    x: bounds.minX + result.positions[index].x,
                    y: bounds.minY + result.positions[index].y
                ),
                proposal: ProposedViewSize(result.sizes[index])
            )
        }
    }
    
    struct FlowLayoutResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        var sizes: [CGSize] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: currentX, y: currentY))
                sizes.append(size)
                
                currentX += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }
            
            self.size = CGSize(
                width: maxWidth,
                height: currentY + lineHeight
            )
        }
    }
}

// MARK: - Preview

#Preview {
    PatchLibraryView()
        .frame(minWidth: 1000, minHeight: 700)
}
