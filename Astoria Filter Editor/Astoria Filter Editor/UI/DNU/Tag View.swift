import SwiftUI


    // MARK: - Models

struct TaggedItem: Identifiable {
    let id = UUID()
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
                Capsule()
                    .fill(isSelected ? tag.color : tag.color.opacity(0.2))
            )
            .foregroundStyle(isSelected ? .white : tag.color)
            .overlay(
                Capsule()
                    .strokeBorder(tag.color.opacity(0.3), lineWidth: isSelected ? 0 : 1)
            )
            .onTapGesture {
                onTap?()
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
        .background(.primary)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Tags")
                .font(.headline)
            
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

// MARK: - Item Editor Sheet

struct ItemEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var item: TaggedItem
    let availableTags: [Tag]
    let onSave: (TaggedItem) -> Void
    
    @State private var editedItem: TaggedItem
    
    init(item: Binding<TaggedItem>, availableTags: [Tag], onSave: @escaping (TaggedItem) -> Void) {
        self._item = item
        self.availableTags = availableTags
        self.onSave = onSave
        self._editedItem = State(initialValue: item.wrappedValue)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $editedItem.title)
                    TextField("Description", text: $editedItem.description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Tags") {
                    TagEditorView(
                        selectedTags: $editedItem.tags,
                        availableTags: availableTags
                    )
                }
            }
            .navigationTitle("Edit Item")
//            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(editedItem)
                        dismiss()
                    }
                }
            }
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
            .background(.secondary)
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
                .background(.secondary)
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

struct TagSystemView: View {
    @State private var viewModel = TagSystemViewModel()
    @State private var selectedItem: TaggedItem?
    @State private var showingEditor = false
    
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
                                    selectedItem = item
                                    showingEditor = true
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Tagged Items")
            .sheet(isPresented: $showingEditor) {
                if let selectedItem = selectedItem {
//                   let binding = Binding(
//                    get: { selectedItem },
//                    set: { self.selectedItem = $0 }
//                   ) {
                    ItemEditorSheet(
                        item: Binding(
                            get: { selectedItem },
                            set: { self.selectedItem = $0 }
                        ),
                        availableTags: viewModel.availableTags,
                        onSave: { updatedItem in
                            viewModel.updateItemTags(updatedItem, tags: updatedItem.tags)
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    TagSystemView()
}
