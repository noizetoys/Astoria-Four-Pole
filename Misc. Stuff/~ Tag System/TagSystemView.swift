import SwiftUI
#if os(macOS)
import AppKit
#endif

// MARK: - Extensions

extension Color {
    static var controlBackground: Color {
        #if os(macOS)
        Color.controlBackground
        #else
        Color(uiColor: .systemBackground)
        #endif
    }
}

// MARK: - Models

enum TagShape: String, CaseIterable, Codable {
    case capsule = "Capsule"
    case roundedRectangle = "Rounded"
    case circle = "Circle"
    case diamond = "Diamond"
    
    var iconName: String {
        switch self {
        case .capsule: return "capsule"
        case .roundedRectangle: return "square"
        case .circle: return "circle"
        case .diamond: return "diamond"
        }
    }
}

struct Tag: Identifiable, Hashable, Codable {
    var id = UUID()
    var name: String
    var color: Color
    var shape: TagShape
    
    enum CodingKeys: String, CodingKey {
        case id, name, colorComponents, shape
    }
    
    init(name: String, color: Color, shape: TagShape = .capsule) {
        self.name = name
        self.color = color
        self.shape = shape
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        shape = try container.decode(TagShape.self, forKey: .shape)
        let components = try container.decode([Double].self, forKey: .colorComponents)
        color = Color(red: components[0], green: components[1], blue: components[2], opacity: components[3])
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(shape, forKey: .shape)
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
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let components = [Double(red), Double(green), Double(blue), Double(alpha)]
        #endif
        try container.encode(components, forKey: .colorComponents)
    }
    
    static let sampleTags: [Tag] = [
        Tag(name: "Work", color: .blue, shape: .capsule),
        Tag(name: "Personal", color: .green, shape: .roundedRectangle),
        Tag(name: "Urgent", color: .red, shape: .diamond),
        Tag(name: "Ideas", color: .purple, shape: .circle),
        Tag(name: "Home", color: .orange, shape: .capsule),
        Tag(name: "Finance", color: .yellow, shape: .roundedRectangle),
        Tag(name: "Health", color: .pink, shape: .circle),
        Tag(name: "Travel", color: .cyan, shape: .capsule),
        Tag(name: "Shopping", color: .indigo, shape: .diamond),
        Tag(name: "Learning", color: .teal, shape: .roundedRectangle)
    ]
}

struct TaggedItem: Identifiable {
    var id = UUID()
    var title: String
    var description: String
    var tags: Set<Tag>
    
    static let sampleItems: [TaggedItem] = [
        TaggedItem(
            title: "Quarterly Review",
            description: "Prepare presentation for Q4 review meeting",
            tags: [Tag.sampleTags[0], Tag.sampleTags[2]] // Work, Urgent
        ),
        TaggedItem(
            title: "Vacation Planning",
            description: "Research destinations for summer vacation",
            tags: [Tag.sampleTags[1], Tag.sampleTags[7]] // Personal, Travel
        ),
        TaggedItem(
            title: "Budget Review",
            description: "Review monthly expenses and update budget",
            tags: [Tag.sampleTags[5], Tag.sampleTags[1]] // Finance, Personal
        ),
        TaggedItem(
            title: "New Project Ideas",
            description: "Brainstorm features for the next app version",
            tags: [Tag.sampleTags[0], Tag.sampleTags[3]] // Work, Ideas
        ),
        TaggedItem(
            title: "Grocery Shopping",
            description: "Buy groceries for the week",
            tags: [Tag.sampleTags[4], Tag.sampleTags[8]] // Home, Shopping
        ),
        TaggedItem(
            title: "SwiftUI Course",
            description: "Complete advanced SwiftUI course on AsyncStream",
            tags: [Tag.sampleTags[9], Tag.sampleTags[1]] // Learning, Personal
        ),
        TaggedItem(
            title: "Doctor Appointment",
            description: "Annual checkup scheduled for next week",
            tags: [Tag.sampleTags[6], Tag.sampleTags[2]] // Health, Urgent
        )
    ]
}

// MARK: - View Model

@Observable
class TagSystemViewModel {
    var items: [TaggedItem]
    var availableTags: [Tag]
    var selectedItem: TaggedItem?
    var searchTags: Set<Tag> = []
    var searchText: String = ""
    
    init() {
        self.items = TaggedItem.sampleItems
        self.availableTags = Tag.sampleTags
    }
    
    var filteredItems: [TaggedItem] {
        if searchTags.isEmpty && searchText.isEmpty {
            return items
        }
        
        return items.filter { item in
            let matchesTags = searchTags.isEmpty || searchTags.isSubset(of: item.tags)
            let matchesText = searchText.isEmpty || 
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.description.localizedCaseInsensitiveContains(searchText)
            return matchesTags && matchesText
        }
    }
    
    func updateItemTags(_ item: TaggedItem, tags: Set<Tag>) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].tags = tags
        }
    }
    
    func addTag(_ tag: Tag) {
        availableTags.append(tag)
    }
    
    func updateTag(_ tag: Tag) {
        if let index = availableTags.firstIndex(where: { $0.id == tag.id }) {
            let oldTag = availableTags[index]
            availableTags[index] = tag
            
            // Update the tag in all items that use it
            for itemIndex in items.indices {
                if items[itemIndex].tags.contains(oldTag) {
                    items[itemIndex].tags.remove(oldTag)
                    items[itemIndex].tags.insert(tag)
                }
            }
            
            // Update search tags if the old tag was selected
            if searchTags.contains(oldTag) {
                searchTags.remove(oldTag)
                searchTags.insert(tag)
            }
        }
    }
    
    func deleteTag(_ tag: Tag) {
        availableTags.removeAll { $0.id == tag.id }
        
        // Remove the tag from all items
        for index in items.indices {
            items[index].tags.remove(tag)
        }
        
        // Remove from search tags
        searchTags.remove(tag)
    }
}

// MARK: - Tag Display View

struct TagView: View {
    let tag: Tag
    var isSelected: Bool = false
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        Text(tag.name)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                tagShape
                    .fill(isSelected ? tag.color : tag.color.opacity(0.2))
            )
            .foregroundStyle(isSelected ? .white : tag.color)
            .overlay(
                tagShape
                    .strokeBorder(tag.color.opacity(0.3), lineWidth: isSelected ? 0 : 1)
            )
            .onTapGesture {
                onTap?()
            }
    }
    
    @ViewBuilder
    private var tagShape: some InsettableShape {
        switch tag.shape {
        case .capsule:
            Capsule()
        case .roundedRectangle:
            RoundedRectangle(cornerRadius: 6)
        case .circle:
            Circle()
        case .diamond:
            // Use a rotated square for diamond shape
            RoundedRectangle(cornerRadius: 2)
                .rotation(.degrees(45))
        }
    }
}

// MARK: - Tag Collection View

struct TagCollectionView: View {
    let tags: [Tag]
    var selectedTags: Set<Tag> = []
    var onTagTap: ((Tag) -> Void)? = nil
    
    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(tags) { tag in
                TagView(
                    tag: tag,
                    isSelected: selectedTags.contains(tag),
                    onTap: { onTagTap?(tag) }
                )
            }
        }
    }
}

// MARK: - Flow Layout for Tags

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

// MARK: - Item Card View

struct ItemCardView: View {
    let item: TaggedItem
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                
                Text(item.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            if !item.tags.isEmpty {
                TagCollectionView(tags: Array(item.tags))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .onTapGesture {
            onTap?()
        }
    }
}

// MARK: - Tag Editor View

struct TagEditorView: View {
    @Binding var selectedTags: Set<Tag>
    let availableTags: [Tag]
    var onCreateTag: (() -> Void)? = nil
    var onManageTags: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Select Tags")
                    .font(.headline)
                
                Spacer()
                
                if let onManageTags = onManageTags {
                    Button {
                        onManageTags()
                    } label: {
                        Label("Manage", systemImage: "gear")
                            .font(.caption)
                    }
                }
                
                if let onCreateTag = onCreateTag {
                    Button {
                        onCreateTag()
                    } label: {
                        Label("New", systemImage: "plus")
                            .font(.caption)
                    }
                }
            }
            
            if availableTags.isEmpty {
                ContentUnavailableView(
                    "No Tags Available",
                    systemImage: "tag.slash",
                    description: Text("Create a tag to get started")
                )
            } else {
                TagCollectionView(
                    tags: availableTags,
                    selectedTags: selectedTags,
                    onTagTap: { tag in
                        if selectedTags.contains(tag) {
                            selectedTags.remove(tag)
                        } else {
                            selectedTags.insert(tag)
                        }
                    }
                )
            }
        }
    }
}

// MARK: - Item Editor View

struct ItemEditorView: View {
    @Binding var item: TaggedItem
    let availableTags: [Tag]
    let onSave: (TaggedItem) -> Void
    let onCancel: () -> Void
    var onCreateTag: (() -> Void)? = nil
    var onManageTags: (() -> Void)? = nil
    
    @State private var editedItem: TaggedItem
    
    init(
        item: Binding<TaggedItem>,
        availableTags: [Tag],
        onSave: @escaping (TaggedItem) -> Void,
        onCancel: @escaping () -> Void,
        onCreateTag: (() -> Void)? = nil,
        onManageTags: (() -> Void)? = nil
    ) {
        self._item = item
        self.availableTags = availableTags
        self.onSave = onSave
        self.onCancel = onCancel
        self.onCreateTag = onCreateTag
        self.onManageTags = onManageTags
        self._editedItem = State(initialValue: item.wrappedValue)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Edit Item")
                    .font(.headline)
                
                Spacer()
                
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Save") {
                    onSave(editedItem)
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color.controlBackground)
            
            Divider()
            
            // Content
            Form {
                Section("Details") {
                    TextField("Title", text: $editedItem.title)
                    TextField("Description", text: $editedItem.description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Tags") {
                    TagEditorView(
                        selectedTags: $editedItem.tags,
                        availableTags: availableTags,
                        onCreateTag: onCreateTag,
                        onManageTags: onManageTags
                    )
                }
            }
            .formStyle(.grouped)
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}

// MARK: - Tag Creator/Editor View

struct TagCreatorView: View {
    let tag: Tag?
    let onSave: (Tag) -> Void
    let onCancel: () -> Void
    
    @State private var name: String
    @State private var selectedColor: Color
    @State private var selectedShape: TagShape
    
    private let predefinedColors: [Color] = [
        .red, .orange, .yellow, .green, .mint, .teal,
        .cyan, .blue, .indigo, .purple, .pink, .brown
    ]
    
    init(tag: Tag? = nil, onSave: @escaping (Tag) -> Void, onCancel: @escaping () -> Void) {
        self.tag = tag
        self.onSave = onSave
        self.onCancel = onCancel
        
        _name = State(initialValue: tag?.name ?? "")
        _selectedColor = State(initialValue: tag?.color ?? .blue)
        _selectedShape = State(initialValue: tag?.shape ?? .capsule)
    }
    
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(tag == nil ? "Create Tag" : "Edit Tag")
                    .font(.headline)
                
                Spacer()
                
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)
                
                Button(tag == nil ? "Create" : "Save") {
                    let newTag = Tag(
                        name: name.trimmingCharacters(in: .whitespaces),
                        color: selectedColor,
                        shape: selectedShape
                    )
                    var tagToSave = newTag
                    if let existingTag = tag {
                        tagToSave.id = existingTag.id
                    }
                    onSave(tagToSave)
                }
                .disabled(!isValid)
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color.controlBackground)
            
            Divider()
            
            // Content
            Form {
                Section("Tag Name") {
                    TextField("Enter tag name", text: $name)
                }
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(predefinedColors, id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color.primary.opacity(0.2), lineWidth: 1)
                                )
                                .overlay(
                                    Group {
                                        if selectedColor == color {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.white)
                                                .fontWeight(.bold)
                                        }
                                    }
                                )
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                    .padding(.vertical, 8)
                    
                    ColorPicker("Custom Color", selection: $selectedColor)
                }
                
                Section("Shape") {
                    HStack(spacing: 16) {
                        ForEach(TagShape.allCases, id: \.self) { shape in
                            VStack(spacing: 8) {
                                Image(systemName: shape.iconName)
                                    .font(.title2)
                                    .frame(width: 50, height: 50)
                                    .background(selectedShape == shape ? Color.accentColor.opacity(0.2) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .strokeBorder(selectedShape == shape ? Color.accentColor : Color.clear, lineWidth: 2)
                                    )
                                    .onTapGesture {
                                        selectedShape = shape
                                    }
                                
                                Text(shape.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                
                Section("Preview") {
                    HStack {
                        Spacer()
                        TagView(tag: Tag(name: name.isEmpty ? "Tag Name" : name, color: selectedColor, shape: selectedShape))
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
            .formStyle(.grouped)
        }
        .frame(minWidth: 400, minHeight: 500)
    }
}

// MARK: - Tag Management View

struct TagManagementView: View {
    let tags: [Tag]
    let onEdit: (Tag) -> Void
    let onDelete: (Tag) -> Void
    let onCreate: () -> Void
    let onDone: () -> Void
    
    @State private var tagToDelete: Tag?
    @State private var showDeleteAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Manage Tags")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    onCreate()
                } label: {
                    Label("New Tag", systemImage: "plus")
                }
                
                Button("Done") {
                    onDone()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color.controlBackground)
            
            Divider()
            
            // Content
            if tags.isEmpty {
                ContentUnavailableView(
                    "No Tags",
                    systemImage: "tag.slash",
                    description: Text("Create a tag to get started")
                )
            } else {
                List {
                    ForEach(tags) { tag in
                        HStack(spacing: 12) {
                            TagView(tag: tag)
                            
                            Spacer()
                            
                            Button {
                                onEdit(tag)
                            } label: {
                                Image(systemName: "pencil")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            
                            Button {
                                tagToDelete = tag
                                showDeleteAlert = true
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
        .alert("Delete Tag", isPresented: $showDeleteAlert, presenting: tagToDelete) { tag in
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete(tag)
            }
        } message: { tag in
            Text("Are you sure you want to delete '\(tag.name)'? This will remove it from all items.")
        }
    }
}

// MARK: - Search Bar View

struct SearchBarView: View {
    @Binding var searchText: String
    @Binding var selectedTags: Set<Tag>
    let availableTags: [Tag]
    @State private var isTagFilterExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                
                TextField("Search items...", text: $searchText)
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            Button {
                withAnimation {
                    isTagFilterExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "tag")
                    Text("Filter by Tags")
                    Spacer()
                    if !selectedTags.isEmpty {
                        Text("\(selectedTags.count)")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                    Image(systemName: isTagFilterExpanded ? "chevron.up" : "chevron.down")
                }
                .font(.subheadline)
                .foregroundStyle(.primary)
                .padding(10)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            if isTagFilterExpanded {
                TagCollectionView(
                    tags: availableTags,
                    selectedTags: selectedTags,
                    onTagTap: { tag in
                        if selectedTags.contains(tag) {
                            selectedTags.remove(tag)
                        } else {
                            selectedTags.insert(tag)
                        }
                    }
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Main Content View

enum ActiveSheet: Identifiable {
    case editItem(TaggedItem)
    case createTag
    case editTag(Tag)
    case manageTags
    
    var id: String {
        switch self {
        case .editItem(let item): return "editItem-\(item.id)"
        case .createTag: return "createTag"
        case .editTag(let tag): return "editTag-\(tag.id)"
        case .manageTags: return "manageTags"
        }
    }
}

struct TagSystemView: View {
    @State private var viewModel = TagSystemViewModel()
    @State private var activeSheet: ActiveSheet?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    SearchBarView(
                        searchText: $viewModel.searchText,
                        selectedTags: $viewModel.searchTags,
                        availableTags: viewModel.availableTags
                    )
                    .padding(.horizontal)
                    
                    if viewModel.filteredItems.isEmpty {
                        ContentUnavailableView(
                            "No Items Found",
                            systemImage: "magnifyingglass",
                            description: Text("Try adjusting your search or filters")
                        )
                        .padding(.top, 40)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.filteredItems) { item in
                                ItemCardView(item: item) {
                                    activeSheet = .editItem(item)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Tagged Items")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        activeSheet = .manageTags
                    } label: {
                        Label("Manage Tags", systemImage: "tag")
                    }
                }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            sheetContent(for: sheet)
        }
    }
    
    @ViewBuilder
    private func sheetContent(for sheet: ActiveSheet) -> some View {
        switch sheet {
        case .editItem(let item):
            if let binding = Binding(
                get: { viewModel.items.first { $0.id == item.id } ?? item },
                set: { _ in }
            ) {
                ItemEditorView(
                    item: binding,
                    availableTags: viewModel.availableTags,
                    onSave: { updatedItem in
                        viewModel.updateItemTags(updatedItem, tags: updatedItem.tags)
                        activeSheet = nil
                    },
                    onCancel: {
                        activeSheet = nil
                    },
                    onCreateTag: {
                        activeSheet = .createTag
                    },
                    onManageTags: {
                        activeSheet = .manageTags
                    }
                )
            }
            
        case .createTag:
            TagCreatorView(
                onSave: { newTag in
                    viewModel.addTag(newTag)
                    activeSheet = nil
                },
                onCancel: {
                    activeSheet = nil
                }
            )
            
        case .editTag(let tag):
            TagCreatorView(
                tag: tag,
                onSave: { updatedTag in
                    viewModel.updateTag(updatedTag)
                    activeSheet = nil
                },
                onCancel: {
                    activeSheet = nil
                }
            )
            
        case .manageTags:
            TagManagementView(
                tags: viewModel.availableTags,
                onEdit: { tag in
                    activeSheet = .editTag(tag)
                },
                onDelete: { tag in
                    viewModel.deleteTag(tag)
                },
                onCreate: {
                    activeSheet = .createTag
                },
                onDone: {
                    activeSheet = nil
                }
            )
        }
    }
}

// MARK: - Preview

#Preview {
    TagSystemView()
}
