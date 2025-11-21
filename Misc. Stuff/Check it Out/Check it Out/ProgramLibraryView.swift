//
//  ProgramLibraryView.swift
//  SynthEditor
//
//  SwiftUI UI + view model for managing configurations and patches,
//  wired up to PatchRandomizerEngine so the randomizer is a distinct
//  feature that can create new configurations or add patches to the
//  current configuration.
//

import SwiftUI
import Combine

// MARK: - Sort & Scope enums (UI-level)

enum PatchSortKey: String, CaseIterable, Identifiable {
    case name
    case configuration
    case slotIndex
    case createdAt
    case modifiedAt
    case favorite

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .name:          return "Name"
        case .configuration: return "Configuration"
        case .slotIndex:     return "Slot"
        case .createdAt:     return "Created"
        case .modifiedAt:    return "Modified"
        case .favorite:      return "Favorite"
        }
    }
}

enum PatchScope: String, CaseIterable, Identifiable {
    case all
    case currentConfiguration
    case specificConfiguration

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .all:                  return "All Patches"
        case .currentConfiguration: return "Current Configuration"
        case .specificConfiguration:return "Specific Configuration"
        }
    }
}

// MARK: - View Model

final class ProgramLibraryViewModel: ObservableObject {
//    var objectWillChange: ObservableObjectPublisher
    

    @Published var configurations: [Configuration]
    @Published var currentConfigurationID: Configuration.ID?
    @Published var workingConfiguration: Configuration?
    @Published var editorPatch: Patch? = nil

    // Search / filter
    @Published var searchText: String = ""
    @Published var selectedTags: Set<String> = []
    @Published var sortKey: PatchSortKey = .name
    @Published var sortAscending: Bool = true
    @Published var favoritesOnly: Bool = false

    /// Pluggable randomizer engine (distinct feature).
    private let randomizerEngine: PatchRandomizerEngine
    private var rng: SystemRandomNumberGenerator = SystemRandomNumberGenerator()

    init(
        configurations: [Configuration] = [],
        randomizerEngine: PatchRandomizerEngine = PatchRandomizerEngine()
    ) {
        self.randomizerEngine = randomizerEngine

        if configurations.isEmpty {
            // Seed two demo configurations with basic programs.
            var slotsA: [Patch?] = Array(repeating: nil, count: 20)
            var slotsB: [Patch?] = Array(repeating: nil, count: 20)
            for i in 0..<20 {
                var prog = SynthProgram()
                prog.programNumber = UInt8(i + 1)
                prog.programName = "Patch \(i + 1)"
                var patch = Patch(program: prog)
                patch.tags = i.isMultiple(of: 2) ? ["Pad", "Warm"] : ["Lead", "Bright"]
                patch.originalSlotIndex = i
                slotsA[i] = patch
                slotsB[i] = patch
            }
            let configA = Configuration(
                name: "Factory A",
                description: "Factory presets A",
                globals: .default,
                patchSlots: slotsA
            )
            let configB = Configuration(
                name: "Factory B",
                description: "Factory presets B",
                globals: .default,
                patchSlots: slotsB
            )
            self.configurations = [configA, configB]
            self.currentConfigurationID = configA.id
            self.workingConfiguration = configA
        } else {
            self.configurations = configurations
            self.currentConfigurationID = configurations.first?.id
            self.workingConfiguration = configurations.first
        }
    }

    // MARK: - Derived data

    var currentConfiguration: Configuration? {
        configurations.first(where: { $0.id == currentConfigurationID })
    }

    var allTags: [String] {
        var set = Set<String>()
        for config in configurations {
            for slot in config.patchSlots {
                if let patch = slot {
                    patch.tags.forEach { set.insert($0) }
                }
            }
        }
        return Array(set).sorted()
    }

    var allPatchContexts: [PatchContext] {
        configurations.flatMap { config in
            config.patchSlots.enumerated().compactMap { index, patch in
                guard let patch else { return nil }
                return PatchContext(
                    patch: patch,
                    configurationID: config.id,
                    configurationName: config.name,
                    slotIndex: index
                )
            }
        }
    }

    func visiblePatches(
        scope: PatchScope,
        specificConfigurationID: Configuration.ID?
    ) -> [PatchContext] {
        let base: [PatchContext]
        switch scope {
        case .all:
            base = allPatchContexts
        case .currentConfiguration:
            guard let currentID = currentConfigurationID else { return [] }
            base = allPatchContexts.filter { $0.configurationID == currentID }
        case .specificConfiguration:
            guard let specificConfigurationID else { return [] }
            base = allPatchContexts.filter { $0.configurationID == specificConfigurationID }
        }

        let search = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let searched = base.filter { ctx in
            guard !search.isEmpty else { return true }
            let inName = ctx.patch.name.lowercased().contains(search)
            let tagString = ctx.patch.tags.joined(separator: " ").lowercased()
            let inTags = tagString.contains(search)
            let configName = ctx.configurationName.lowercased().contains(search)
            return inName || inTags || configName
        }

        let tagFiltered: [PatchContext]
        if selectedTags.isEmpty {
            tagFiltered = searched
        } else {
            tagFiltered = searched.filter { ctx in
                selectedTags.isSubset(of: Set(ctx.patch.tags))
            }
        }

        let favoritesFiltered: [PatchContext]
        if favoritesOnly {
            favoritesFiltered = tagFiltered.filter { $0.patch.isFavorite }
        } else {
            favoritesFiltered = tagFiltered
        }

        let sorted = favoritesFiltered.sorted { lhs, rhs in
            let compareResult: ComparisonResult
            switch sortKey {
            case .name:
                compareResult = lhs.patch.name.localizedCaseInsensitiveCompare(rhs.patch.name)
            case .configuration:
                compareResult = lhs.configurationName.localizedCaseInsensitiveCompare(rhs.configurationName)
            case .slotIndex:
                let l = lhs.slotIndex ?? Int.max
                let r = rhs.slotIndex ?? Int.max
                compareResult = l == r ? .orderedSame : (l < r ? .orderedAscending : .orderedDescending)
            case .createdAt:
                compareResult = lhs.patch.createdAt.compare(rhs.patch.createdAt)
            case .modifiedAt:
                compareResult = lhs.patch.modifiedAt.compare(rhs.patch.modifiedAt)
            case .favorite:
                let lf = lhs.patch.isFavorite ? 0 : 1
                let rf = rhs.patch.isFavorite ? 0 : 1
                compareResult = lf == rf ? .orderedSame : (lf < rf ? .orderedAscending : .orderedDescending)
            }
            return sortAscending ? (compareResult == .orderedAscending) : (compareResult == .orderedDescending)
        }

        return sorted
    }

    // MARK: - Configuration management

    func createNewConfiguration(named name: String) {
        let newConfig = Configuration.empty(named: name)
        configurations.append(newConfig)
        currentConfigurationID = newConfig.id
        workingConfiguration = newConfig
    }

    func loadConfiguration(_ config: Configuration) {
        currentConfigurationID = config.id
        workingConfiguration = config
        // TODO: send SysEx to device.
    }

    func loadConfiguration(by id: Configuration.ID) {
        guard let config = configurations.first(where: { $0.id == id }) else { return }
        loadConfiguration(config)
    }

    func saveCurrentConfigurationChanges() {
        guard
            let id = currentConfigurationID,
            let working = workingConfiguration,
            let index = configurations.firstIndex(where: { $0.id == id })
        else { return }

        var updated = working
        updated.modifiedAt = Date()
        configurations[index] = updated
        workingConfiguration = updated
    }

    func saveCurrentConfigurationAsCopy(named newName: String) {
        guard var working = workingConfiguration else { return }
        working = Configuration(
            id: UUID(),
            name: newName,
            description: working.description,
            globals: working.globals,
            patchSlots: working.patchSlots,
            createdAt: Date(),
            modifiedAt: Date()
        )
        configurations.append(working)
        currentConfigurationID = working.id
        workingConfiguration = working
    }

    // MARK: - Patch operations

    private func mutateWorkingConfiguration(_ body: (inout Configuration) -> Void) {
        guard var config = workingConfiguration else { return }
        body(&config)
        config.modifiedAt = Date()
        workingConfiguration = config

        if let currentID = currentConfigurationID,
           let index = configurations.firstIndex(where: { $0.id == currentID }) {
            configurations[index] = config
        }
    }

    func loadPatch(_ patch: Patch, intoSlot slotIndex: Int) {
        guard (0..<20).contains(slotIndex) else { return }
        mutateWorkingConfiguration { config in
            var p = patch
            p.originalSlotIndex = slotIndex
            p.isDirty = true
            p.modifiedAt = Date()
            config.patchSlots[slotIndex] = p
        }
    }

    func loadPatchIntoEditor(_ patch: Patch) {
        var editable = patch
        editable.isDirty = true
        editable.modifiedAt = Date()
        editorPatch = editable
    }

    func commitEditorPatchToSlot(_ slotIndex: Int, asNewPatch: Bool) {
        guard var editorPatch else { return }
        if asNewPatch {
            var newProgram = editorPatch.program
            newProgram.programNumber = UInt8(clamping: slotIndex + 1)
            editorPatch = Patch(
                program: newProgram,
                tags: editorPatch.tags,
                createdAt: Date(),
                modifiedAt: Date(),
                originalSlotIndex: slotIndex,
                isFavorite: editorPatch.isFavorite,
                isDirty: true
            )
        } else {
            editorPatch.originalSlotIndex = slotIndex
            editorPatch.isDirty = true
            editorPatch.modifiedAt = Date()
        }
        loadPatch(editorPatch, intoSlot: slotIndex)
    }

    func saveEditorPatchAsNewPatchInFirstFreeSlot() {
        guard let editorPatch else { return }
        for (configIndex, var config) in configurations.enumerated() {
            if let emptyIndex = config.patchSlots.firstIndex(where: { $0 == nil }) {
                var p = editorPatch
                p.originalSlotIndex = emptyIndex
                p.isDirty = true
                p.modifiedAt = Date()
                config.patchSlots[emptyIndex] = p
                config.modifiedAt = Date()
                configurations[configIndex] = config
                if config.id == workingConfiguration?.id {
                    workingConfiguration = config
                }
                return
            }
        }
    }

    func toggleFavoriteForPatch(configID: Configuration.ID, slotIndex: Int?) {
        guard let slotIndex else { return }
        guard let configIndex = configurations.firstIndex(where: { $0.id == configID }) else { return }
        var config = configurations[configIndex]
        guard var patch = config.patchSlots[slotIndex] else { return }
        patch.isFavorite.toggle()
        patch.isDirty = true
        patch.modifiedAt = Date()
        config.patchSlots[slotIndex] = patch
        config.modifiedAt = Date()
        configurations[configIndex] = config
        if config.id == workingConfiguration?.id {
            workingConfiguration = config
        }
    }

    // MARK: - Randomizer integration (distinct feature talking to manager)

    /// Create a new configuration with random patches from a high-level profile.
    func createRandomConfiguration(
        name: String,
        description: String = "",
        profile: PatchCharacteristicProfile,
        count: Int
    ) {
        let newConfig = randomizerEngine.makeRandomConfiguration(
            name: name,
            description: description,
            profile: profile,
            count: count,
            rng: &rng
        )
        configurations.append(newConfig)
        currentConfigurationID = newConfig.id
        workingConfiguration = newConfig
    }

    /// Add some number of random patches to the currently loaded configuration.
    func addRandomPatchesToCurrentConfiguration(
        profile: PatchCharacteristicProfile,
        count: Int
    ) {
        guard var config = workingConfiguration else { return }
        randomizerEngine.addRandomPatches(
            to: &config,
            profile: profile,
            count: count,
            rng: &rng
        )
        if let idx = configurations.firstIndex(where: { $0.id == config.id }) {
            configurations[idx] = config
        } else {
            configurations.append(config)
        }
        workingConfiguration = config
        currentConfigurationID = config.id
    }

    /// Create a new configuration by hybridizing template patches.
    func createHybridConfiguration(
        name: String,
        description: String = "",
        templates: [Patch],
        strength: RandomizeStrength,
        count: Int
    ) {
        let newConfig = randomizerEngine.makeHybridConfiguration(
            name: name,
            description: description,
            templates: templates,
            strength: strength,
            count: count,
            rng: &rng
        )
        configurations.append(newConfig)
        currentConfigurationID = newConfig.id
        workingConfiguration = newConfig
    }

    /// Add hybridized patches to the current configuration.
    func addHybridPatchesToCurrentConfiguration(
        templates: [Patch],
        strength: RandomizeStrength,
        count: Int
    ) {
        guard var config = workingConfiguration else { return }
        randomizerEngine.addHybridPatches(
            to: &config,
            templates: templates,
            strength: strength,
            count: count,
            rng: &rng
        )
        if let idx = configurations.firstIndex(where: { $0.id == config.id }) {
            configurations[idx] = config
        } else {
            configurations.append(config)
        }
        workingConfiguration = config
        currentConfigurationID = config.id
    }

    /// Randomize the patch currently in the editor.
    func randomizePatchInEditor(strength: RandomizeStrength) {
        guard let current = editorPatch else { return }
        // Treat the editor patch as a single-template set.
        var localRNG: SystemRandomNumberGenerator = rng
        let hybrids = randomizerEngine.generatePatches(
            fromTemplates: [current],
            count: 1,
            strength: strength,
            baseName: current.name,
            startingProgramNumber: current.program.programNumber,
            rng: &localRNG
        )
        if let first = hybrids.first {
            editorPatch = first
        }
        rng = localRNG
    }

    /// Randomize a patch in a specific configuration slot by hybridizing
    /// against one or more template patches.
    func randomizePatchInSlot(
        configID: Configuration.ID,
        slotIndex: Int?,
        templates: [Patch],
        strength: RandomizeStrength
    ) {
        guard let slotIndex else { return }
        guard let configIndex = configurations.firstIndex(where: { $0.id == configID }) else { return }
        var config = configurations[configIndex]
        guard let patch = config.patchSlots[slotIndex] else { return }

        var templateSet = templates
        templateSet.append(patch)

        var localRNG: SystemRandomNumberGenerator = rng
        let hybrids = randomizerEngine.generatePatches(
            fromTemplates: templateSet,
            count: 1,
            strength: strength,
            baseName: patch.name,
            startingProgramNumber: patch.program.programNumber,
            rng: &localRNG
        )
        if let newPatch = hybrids.first {
            var p = newPatch
            p.originalSlotIndex = slotIndex
            config.patchSlots[slotIndex] = p
            config.modifiedAt = Date()
            configurations[configIndex] = config
            if config.id == workingConfiguration?.id {
                workingConfiguration = config
            }
            editorPatch = p     // optional: load into editor
        }
        rng = localRNG
    }
}

// MARK: - SwiftUI View

public struct ProgramLibraryView: View {

    @StateObject private var viewModel = ProgramLibraryViewModel()

    @State private var patchScope: PatchScope = .currentConfiguration
    @State private var specificConfigurationID: Configuration.ID? = nil
    @State private var slotPickerContext: PatchContext? = nil

    // Randomizer UI state
    @State private var showRandomizerSheet = false
    @State private var randomizerModeIsHybrid = false
    @State private var selectedTemplateIDs = Set<Patch.ID>()
    @State private var randomPatchCount: Int = 8
    @State private var randomStrength: RandomizeStrength = .moderate

    public init() {}

    public var body: some View {
        NavigationSplitView {
            configurationSidebar
        } content: {
            patchBrowser
        } detail: {
            editorPanel
        }
        .navigationTitle("Program & Configuration Manager")
        .searchable(
            text: $viewModel.searchText,
            placement: .automatic,
            prompt: Text("Search patches, tags, configurations")
        )
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    randomizerModeIsHybrid = false
                    showRandomizerSheet = true
                } label: {
                    Label("Profile Randomizer", systemImage: "sparkles")
                }
                Button {
                    randomizerModeIsHybrid = true
                    showRandomizerSheet = true
                } label: {
                    Label("Template Randomizer", systemImage: "wand.and.stars")
                }
            }
        }
        .sheet(isPresented: $showRandomizerSheet) {
            RandomizerSheet(
                isHybridMode: $randomizerModeIsHybrid,
                randomPatchCount: $randomPatchCount,
                randomStrength: $randomStrength,
                availablePatchContexts: viewModel.allPatchContexts,
                selectedTemplateIDs: $selectedTemplateIDs,
                onGenerateFromProfile: { profile, count, toNewConfig in
                    if toNewConfig {
                        viewModel.createRandomConfiguration(
                            name: "Random Config",
                            description: "Generated from profile",
                            profile: profile,
                            count: count
                        )
                    } else {
                        viewModel.addRandomPatchesToCurrentConfiguration(
                            profile: profile,
                            count: count
                        )
                    }
                },
                onGenerateFromTemplates: { templateIDs, strength, count, toNewConfig in
                    let templates = viewModel.allPatchContexts
                        .map { $0.patch }
                        .filter { templateIDs.contains($0.id) }

                    guard !templates.isEmpty else { return }

                    if toNewConfig {
                        viewModel.createHybridConfiguration(
                            name: "Hybrid Config",
                            description: "Generated from templates",
                            templates: templates,
                            strength: strength,
                            count: count
                        )
                    } else {
                        viewModel.addHybridPatchesToCurrentConfiguration(
                            templates: templates,
                            strength: strength,
                            count: count
                        )
                    }
                }
            )
        }
    }

    // MARK: - Sidebar

    private var configurationSidebar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Configurations")
                    .font(.headline)
                Spacer()
                Menu {
                    Button("New Empty Configuration") {
                        viewModel.createNewConfiguration(named: "New Configuration")
                    }
                    Button("New Random Warm Pads") {
                        var profile = PatchCharacteristicProfile.warmPad
                        profile.tagHints.append("Random")
                        viewModel.createRandomConfiguration(
                            name: "Warm Pads",
                            description: "Random warm pad-style patches",
                            profile: profile,
                            count: 20
                        )
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
            }
            .padding([.top, .horizontal])

            List(selection: Binding(
                get: { viewModel.currentConfigurationID },
                set: { newID in
                    if let newID {
                        viewModel.loadConfiguration(by: newID)
                    }
                })
            ) {
                ForEach(viewModel.configurations) { config in
                    HStack {
                        VStack(alignment: .leading) {
                            HStack(spacing: 4) {
                                Text(config.name)
                                    .font(.body)
                                    .fontWeight(config.id == viewModel.currentConfigurationID ? .semibold : .regular)
                                if config.isDirty {
                                    Text("●")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                }
                            }
                            Text(config.description.isEmpty ? "No description" : config.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .tag(config.id as Configuration.ID?)
                    .contextMenu {
                        Button("Load Configuration") {
                            viewModel.loadConfiguration(config)
                        }
                        Button("Save Current Changes into This") {
                            if let working = viewModel.workingConfiguration {
                                viewModel.saveCurrentConfigurationChanges()
                                viewModel.loadConfiguration(working)
                            }
                        }
                        Button("Duplicate as New") {
                            viewModel.saveCurrentConfigurationAsCopy(named: config.name + " Copy")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Patch Browser

    private var patchBrowser: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Filters + sort
            HStack {
                Picker("Scope:", selection: $patchScope) {
                    ForEach(PatchScope.allCases) { scope in
                        Text(scope.displayName).tag(scope)
                    }
                }
                .pickerStyle(.segmented)

                if patchScope == .specificConfiguration {
                    Picker("Configuration", selection: Binding(
                        get: { specificConfigurationID ?? viewModel.configurations.first?.id },
                        set: { specificConfigurationID = $0 }
                    )) {
                        ForEach(viewModel.configurations) { config in
                            Text(config.name).tag(config.id as Configuration.ID?)
                        }
                    }
                    .frame(maxWidth: 220)
                }

                Spacer()

                Toggle("Favorites only", isOn: $viewModel.favoritesOnly)
                    .toggleStyle(.switch)
                    .padding(.trailing, 4)

                Picker("Sort by", selection: $viewModel.sortKey) {
                    ForEach(PatchSortKey.allCases) { key in
                        Text(key.displayName).tag(key)
                    }
                }
                .frame(maxWidth: 210)

                Button {
                    viewModel.sortAscending.toggle()
                } label: {
                    Image(systemName: viewModel.sortAscending ? "arrow.up" : "arrow.down")
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // Tag filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    if !viewModel.allTags.isEmpty {
                        Text("Tags:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    ForEach(viewModel.allTags, id: \.self) { tag in
                        let isSelected = viewModel.selectedTags.contains(tag)
                        Button {
                            if isSelected {
                                viewModel.selectedTags.remove(tag)
                            } else {
                                viewModel.selectedTags.insert(tag)
                            }
                        } label: {
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(isSelected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.08))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }

            // Patch list
            let patches = viewModel.visiblePatches(
                scope: patchScope,
                specificConfigurationID: specificConfigurationID
            )

            List(patches) { ctx in
                HStack {
                    // Favorite star
                    if let slotIndex = ctx.slotIndex {
                        Button {
                            viewModel.toggleFavoriteForPatch(
                                configID: ctx.configurationID,
                                slotIndex: slotIndex
                            )
                        } label: {
                            Image(systemName: ctx.patch.isFavorite ? "star.fill" : "star")
                                .foregroundStyle(ctx.patch.isFavorite ? .yellow : .secondary)
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 4)
                    } else {
                        Image(systemName: "star")
                            .foregroundStyle(.clear)
                            .padding(.trailing, 4)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Text(ctx.patch.name)
                                .font(.body)
                                .fontWeight(.medium)
                            if ctx.patch.isDirty {
                                Text("●")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                            }
                            if ctx.configurationID == viewModel.currentConfigurationID {
                                Text("Current Config")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.accentColor.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }

                        HStack(spacing: 6) {
                            Text(ctx.configurationName)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if let slot = ctx.slotIndex {
                                Text(String(format: "Slot %02d", slot + 1))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if !ctx.patch.tags.isEmpty {
                            HStack(spacing: 4) {
                                ForEach(ctx.patch.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.secondary.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    Spacer()

                    Menu {
                        Button("Load into Editor") {
                            viewModel.loadPatchIntoEditor(ctx.patch)
                        }
                        Button("Load into Slot…") {
                            slotPickerContext = ctx
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
        .sheet(item: $slotPickerContext) { ctx in
            SlotPickerSheet(
                context: ctx,
                onSelectSlot: { slotIndex in
                    viewModel.loadPatch(ctx.patch, intoSlot: slotIndex)
                }
            )
        }
    }

    // MARK: - Editor Panel

    private var editorPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Patch Editor")
                .font(.headline)
                .padding(.top)

            if Binding(
                get: { viewModel.editorPatch },
                set: { viewModel.editorPatch = $0 }
            ).wrappedValue == nil {
                Text("No patch loaded. Select a patch and choose “Load into Editor”.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                PatchEditorStub(
                    patch: Binding(
                        get: { viewModel.editorPatch ?? Patch() },
                        set: {
                            var updated = $0
                            updated.isDirty = true
                            updated.modifiedAt = Date()
                            viewModel.editorPatch = updated
                        }
                    ),
                    saveToSlot: { slotIndex, asNew in
                        viewModel.commitEditorPatchToSlot(slotIndex, asNewPatch: asNew)
                    },
                    saveAsNewPatchInFirstFreeSlot: {
                        viewModel.saveEditorPatchAsNewPatchInFirstFreeSlot()
                    },
                    randomizeGentle: {
                        viewModel.randomizePatchInEditor(strength: .gentle)
                    },
                    randomizeExtreme: {
                        viewModel.randomizePatchInEditor(strength: .extreme)
                    }
                )
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Slot Picker Sheet

struct SlotPickerSheet: View {
    let context: PatchContext
    let onSelectSlot: (Int) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Load “\(context.patch.name)” into Slot")
                    .font(.headline)
                    .padding(.top)

                Text("Select a destination slot in the current working configuration. This will overwrite any patch currently in that position.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                    ForEach(0..<20, id: \.self) { index in
                        Button {
                            onSelectSlot(index)
                            dismiss()
                        } label: {
                            Text(String(format: "%02d", index + 1))
                                .frame(maxWidth: .infinity, minHeight: 36)
                                .padding(.vertical, 4)
                                .background(Color.accentColor.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Patch Editor Stub (minimal UI)

struct PatchEditorStub: View {

    @Binding var patch: Patch

    let saveToSlot: (_ slotIndex: Int, _ asNew: Bool) -> Void
    let saveAsNewPatchInFirstFreeSlot: () -> Void
    let randomizeGentle: () -> Void
    let randomizeExtreme: () -> Void

    @State private var chosenSlotIndex: Int = 0
    @State private var asNewPatch: Bool = false

    var body: some View {
        Form {
            Section("Basic Info") {
                TextField("Name", text: Binding(
                    get: { patch.name },
                    set: { patch.name = $0 }
                ))
                Toggle("Favorite", isOn: $patch.isFavorite)
                TagEditor(tags: $patch.tags)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Created: \(patch.createdAt.formatted(date: .abbreviated, time: .shortened))")
                    Text("Modified: \(patch.modifiedAt.formatted(date: .abbreviated, time: .shortened))")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)

                if patch.isDirty {
                    Text("Unsaved changes")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }

            Section("Randomizer") {
                Text("Randomize the current patch based on its own characteristics.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    Button("Gentle Randomize") {
                        randomizeGentle()
                    }
                    Button("Extreme Randomize") {
                        randomizeExtreme()
                    }
                }
            }

            Section("Save to Configuration") {
                Stepper(
                    "Target Slot: \(String(format: "%02d", chosenSlotIndex + 1))",
                    value: $chosenSlotIndex,
                    in: 0...19
                )
                Toggle("Save as New Patch (duplicate)", isOn: $asNewPatch)

                Button("Commit to Slot") {
                    saveToSlot(chosenSlotIndex, asNewPatch)
                }
            }

            Section("Library Actions") {
                Button("Save as New Patch in First Free Slot") {
                    saveAsNewPatchInFirstFreeSlot()
                }
            }
        }
    }
}

// MARK: - Tag Editor & Wrap layout

struct TagEditor: View {
    @Binding var tags: [String]
    @State private var newTagText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Tags")
                Spacer()
            }

            if tags.isEmpty {
                Text("No tags. Add some to make searching and filtering easier.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                WrapHStack(tags, id: \.self) { tag in
                    HStack(spacing: 4) {
                        Text(tag)
                            .font(.caption2)
                        Button {
                            tags.removeAll { $0 == tag }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption2)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Capsule())
                }
            }

            HStack {
                TextField("Add tag", text: $newTagText, onCommit: addTag)
                Button {
                    addTag()
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .buttonStyle(.borderless)
            }
        }
    }

    private func addTag() {
        let trimmed = newTagText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if !tags.contains(trimmed) {
            tags.append(trimmed)
        }
        newTagText = ""
    }
}

struct WrapHStack<Data: RandomAccessCollection, ID: Hashable, Content: View>: View {
    let data: Data
    let id: KeyPath<Data.Element, ID>
    let content: (Data.Element) -> Content

    init(
        _ data: Data,
        id: KeyPath<Data.Element, ID>,

        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.id = id
        self.content = content
    }

    var body: some View {
        GeometryReader { geometry in
            self.generateContent(in: geometry)
        }
        .frame(maxHeight: 80)
    }

    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero

        return ZStack(alignment: .topLeading) {
            ForEach(data, id: id) { element in
                content(element)
                    .alignmentGuide(.leading) { d in
                        if (width + d.width) > geometry.size.width {
                            width = 0
                            height -= d.height
                        }
                        let result = width
                        width += d.width
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        return result
                    }
            }
        }
    }
}

// MARK: - Randomizer Sheet (profile + template modes)

struct RandomizerSheet: View {

    @Binding var isHybridMode: Bool
    @Binding var randomPatchCount: Int
    @Binding var randomStrength: RandomizeStrength

    let availablePatchContexts: [PatchContext]
    @Binding var selectedTemplateIDs: Set<Patch.ID>

    let onGenerateFromProfile: (_ profile: PatchCharacteristicProfile, _ count: Int, _ toNewConfig: Bool) -> Void
    let onGenerateFromTemplates: (_ templateIDs: Set<Patch.ID>, _ strength: RandomizeStrength, _ count: Int, _ toNewConfig: Bool) -> Void

    @Environment(\.dismiss) private var dismiss

    // Simple profile controls
    @State private var brightness: Double = 0.6
    @State private var motion: Double = 0.3
    @State private var snappiness: Double = 0.4
    @State private var stereoWidth: Double = 0.3
    @State private var gateTightness: Double = 0.4
    @State private var targetNewConfiguration: Bool = true

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Mode", selection: $isHybridMode) {
                        Text("Profile-based").tag(false)
                        Text("Template-based").tag(true)
                    }
                    .pickerStyle(.segmented)
                }

                if !isHybridMode {
                    profileControls
                } else {
                    templateControls
                }

                Section("Output") {
                    Stepper("Number of patches: \(randomPatchCount)", value: $randomPatchCount, in: 1...20)
                    Toggle("Create new configuration", isOn: $targetNewConfiguration)
                }
            }
            .navigationTitle(isHybridMode ? "Template Randomizer" : "Profile Randomizer")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Generate") {
                        generate()
                        dismiss()
                    }
                    .disabled(isHybridMode && selectedTemplateIDs.isEmpty)
                }
            }
        }
    }

    private var profileControls: some View {
        Section("Patch Character Profile") {
            HStack {
                Text("Brightness")
                Slider(value: $brightness, in: 0...1)
            }
            HStack {
                Text("Motion")
                Slider(value: $motion, in: 0...1)
            }
            HStack {
                Text("Snappiness")
                Slider(value: $snappiness, in: 0...1)
            }
            HStack {
                Text("Stereo Width")
                Slider(value: $stereoWidth, in: 0...1)
            }
            HStack {
                Text("Gate Tightness")
                Slider(value: $gateTightness, in: 0...1)
            }
        }
    }

    private var templateControls: some View {
        Section("Template Patches") {
            if availablePatchContexts.isEmpty {
                Text("No patches available to use as templates.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                List(availablePatchContexts, id: \.patch.id) { ctx in
                    let isSelected = selectedTemplateIDs.contains(ctx.patch.id)
                    Button {
                        if isSelected {
                            selectedTemplateIDs.remove(ctx.patch.id)
                        } else {
                            selectedTemplateIDs.insert(ctx.patch.id)
                        }
                    } label: {
                        HStack {
                            Image(systemName: isSelected ? "checkmark.square" : "square")
                            VStack(alignment: .leading) {
                                Text(ctx.patch.name)
                                Text("\(ctx.configurationName) – Slot \((ctx.slotIndex ?? 0) + 1)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .frame(minHeight: 150, maxHeight: 240)
            }

            Picker("Variation Strength", selection: $randomStrength) {
                Text("Gentle").tag(RandomizeStrength.gentle)
                Text("Moderate").tag(RandomizeStrength.moderate)
                Text("Extreme").tag(RandomizeStrength.extreme)
            }
            .pickerStyle(.segmented)
        }
    }

    private func generate() {
        if !isHybridMode {
            let profile = PatchCharacteristicProfile(
                brightness: brightness...brightness,
                motion: motion...motion,
                snappiness: snappiness...snappiness,
                stereoWidth: stereoWidth...stereoWidth,
                gateTightness: gateTightness...gateTightness,
                tagHints: []
            )
            onGenerateFromProfile(profile, randomPatchCount, targetNewConfiguration)
        } else {
            onGenerateFromTemplates(selectedTemplateIDs, randomStrength, randomPatchCount, targetNewConfiguration)
        }
    }
}



@main
struct TagSystemApp: App {
    var body: some Scene {
        WindowGroup {
            ProgramLibraryView()
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
    }
}




// MARK: - Preview

struct ProgramLibraryView_Previews: PreviewProvider {
    static var previews: some View {
        ProgramLibraryView()
            .frame(minWidth: 1100, minHeight: 600)
    }
}

