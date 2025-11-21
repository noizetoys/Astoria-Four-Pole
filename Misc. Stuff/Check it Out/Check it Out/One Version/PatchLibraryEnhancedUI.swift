import SwiftUI
import UniformTypeIdentifiers

// MARK: - Search and Filter Bar

struct SearchFilterBar: View {
    @Bindable var viewModel: PatchLibraryViewModel
    @State private var showTagFilter = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                
                TextField("Search patches...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                
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

// MARK: - Patch List View with Drag & Drop and Keyboard Navigation

struct PatchListView: View {
    let patches: [Patch]
    @Binding var selectedIndex: Int?
    let onSelect: (Patch) -> Void
    let onEdit: (Patch) -> Void
    let onToggleFavorite: (Patch) -> Void
    let onDelete: (Patch) -> Void
    let onDragStart: (Patch) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(patches.enumerated()), id: \.element.id) { index, patch in
                    PatchCard(
                        patch: patch,
                        isSelected: selectedIndex == index,
                        onSelect: { onSelect(patch) },
                        onEdit: { onEdit(patch) },
                        onToggleFavorite: { onToggleFavorite(patch) },
                        onDelete: { onDelete(patch) }
                    )
                    .onTapGesture {
                        selectedIndex = index
                    }
                    .draggable(patch) {
                        PatchDragPreview(patch: patch)
                    }
                }
            }
            .padding()
        }
    }
}

struct PatchCard: View {
    let patch: Patch
    var isSelected: Bool = false
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
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
    }
}

struct PatchDragPreview: View {
    let patch: Patch
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(patch.name)
                .font(.headline)
            Text(patch.category)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(radius: 8)
    }
}

// MARK: - Configuration Slots View with Drop Support

struct ConfigurationSlotsView: View {
    @Binding var configuration: Configuration
    var viewModel: PatchLibraryViewModel
    let onLoadPatch: (Patch) -> Void
    
    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 12)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
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
                
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(0..<20, id: \.self) { index in
                        PatchSlotView(
                            slotNumber: index + 1,
                            patch: configuration.patches[index],
                            onTap: {
                                if let patch = configuration.patches[index] {
                                    onLoadPatch(patch)
                                }
                            },
                            onClear: {
                                viewModel.clearSlot(index)
                            }
                        )
                        .dropDestination(for: Patch.self) { patches, _ in
                            if let patch = patches.first {
                                viewModel.loadPatchToSlot(patch, slot: index)
                                return true
                            }
                            return false
                        }
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
    let onClear: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(slotNumber)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 30, alignment: .leading)
                
                Spacer()
                
                if let patch = patch {
                    HStack(spacing: 4) {
                        if patch.isFavorite {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                                .font(.caption2)
                        }
                        
                        if isHovered {
                            Button {
                                onClear()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                        }
                    }
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
                HStack {
                    Spacer()
                    VStack {
                        Image(systemName: "tray")
                            .font(.title2)
                            .foregroundStyle(.tertiary)
                        Text("Drop here")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(patch != nil ? Color(.controlBackgroundColor) : Color(.controlBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    isHovered ? Color.accentColor.opacity(0.5) : (patch != nil ? Color.clear : Color(.separatorColor)),
                    lineWidth: isHovered ? 2 : 1
                )
        )
        .onTapGesture(perform: onTap)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Export Views

struct ExportPatchesView: View {
    let patches: [Patch]
    let viewModel: PatchLibraryViewModel
    let onDone: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Export \(patches.count) Patches")
                    .font(.headline)
                
                Spacer()
                
                Button("Cancel", action: onDone)
                    .keyboardShortcut(.cancelAction)
                
                Button("Export") {
                    exportPatches()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            
            Divider()
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Export \(patches.count) patches to a JSON file that can be imported into another library.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                
                HStack {
                    Image(systemName: "doc.badge.arrow.up")
                        .font(.title)
                        .foregroundStyle(.blue)
                    
                    VStack(alignment: .leading) {
                        Text("Patches: \(patches.count)")
                        Text("Tags: \(Set(patches.flatMap { $0.tags }).count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minWidth: 400, minHeight: 200)
    }
    
    private func exportPatches() {
        guard let data = viewModel.exportPatches(patches) else { return }
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "patches_export.json"
        
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            
            do {
                try data.write(to: url)
                onDone()
            } catch {
                print("Export failed: \(error)")
            }
        }
    }
}

struct ExportConfigurationView: View {
    let configuration: Configuration
    let viewModel: PatchLibraryViewModel
    let onDone: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Export Configuration")
                    .font(.headline)
                
                Spacer()
                
                Button("Cancel", action: onDone)
                    .keyboardShortcut(.cancelAction)
                
                Button("Export") {
                    exportConfiguration()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            
            Divider()
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Export the complete configuration including all patches and settings to a JSON file.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                
                HStack {
                    Image(systemName: "square.stack.3d.up")
                        .font(.title)
                        .foregroundStyle(.blue)
                    
                    VStack(alignment: .leading) {
                        Text(configuration.name)
                            .font(.headline)
                        Text("Patches: \(configuration.patchCount)/20")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minWidth: 400, minHeight: 200)
    }
    
    private func exportConfiguration() {
        guard let data = viewModel.exportConfiguration(configuration) else { return }
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "\(configuration.name).json"
        
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            
            do {
                try data.write(to: url)
                onDone()
            } catch {
                print("Export failed: \(error)")
            }
        }
    }
}

// MARK: - Other Editor Views (simplified versions)

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

struct PatchEditorView: View {
    @Bindable var editor: PatchEditor
    let availableTags: [Tag]
    let onSave: (Int?) -> Void
    let onCancel: () -> Void
    
    @State private var saveToSlot: Int?
    
    var body: some View {
        VStack(spacing: 0) {
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

struct GlobalDataEditorView: View {
    @Binding var globalData: GlobalData
    let onDone: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
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
            }
            .formStyle(.grouped)
        }
        .frame(minWidth: 400, minHeight: 250)
    }
}

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

#Preview {
    PatchLibraryView()
        .frame(minWidth: 1200, minHeight: 800)
}
