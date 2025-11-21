# Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        TagSystemView                            │
│                     (Main Container)                            │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              TagSystemViewModel                          │  │
│  │              (@Observable)                               │  │
│  │                                                          │  │
│  │  • items: [TaggedItem]                                  │  │
│  │  • availableTags: [Tag]                                 │  │
│  │  • searchTags: Set<Tag>                                 │  │
│  │  • searchText: String                                   │  │
│  │                                                          │  │
│  │  Methods:                                               │  │
│  │  • addTag(_:)                                           │  │
│  │  • updateTag(_:)      ← Propagates to all items        │  │
│  │  • deleteTag(_:)      ← Removes from all items         │  │
│  │  • updateItemTags(_:tags:)                             │  │
│  │  • filteredItems      ← Computed property              │  │
│  └──────────────────────────────────────────────────────────┘  │
│                          │                                      │
│                          ▼                                      │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                  Navigation Layer                        │  │
│  │                                                          │  │
│  │  ActiveSheet (enum):                                    │  │
│  │  • editItem(TaggedItem)                                 │  │
│  │  • createTag                                            │  │
│  │  • editTag(Tag)                                         │  │
│  │  • manageTags                                           │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        ▼                 ▼                 ▼
┌────────────────┐ ┌────────────────┐ ┌────────────────┐
│ Search & List  │ │  Modal Views   │ │   Components   │
└────────────────┘ └────────────────┘ └────────────────┘
        │                 │                 │
        │                 │                 │
        ▼                 ▼                 ▼

┌─────────────────────────────────────────────────────────────────┐
│                         Search & List                           │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ SearchBarView                                            │  │
│  │ • Text search input                                      │  │
│  │ • Expandable tag filter                                  │  │
│  │ • Active filter count badge                              │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ LazyVStack of ItemCardView                               │  │
│  │                                                          │  │
│  │  ┌────────────────────────────────────────────────────┐ │  │
│  │  │ ItemCardView                                       │ │  │
│  │  │ • Title & Description                              │ │  │
│  │  │ • TagCollectionView (display only)                 │ │  │
│  │  │ • Tap gesture → Opens ItemEditorView               │ │  │
│  │  └────────────────────────────────────────────────────┘ │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                         Modal Views                             │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ ItemEditorView                                           │  │
│  │ • Title & Description fields                             │  │
│  │ • TagEditorView (select/deselect tags)                   │  │
│  │ • Buttons: Create Tag, Manage Tags, Cancel, Save         │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ TagCreatorView                                           │  │
│  │ • Name text field                                        │  │
│  │ • Color picker (12 presets + custom)                     │  │
│  │ • Shape selector (4 options)                             │  │
│  │ • Live preview                                           │  │
│  │ • Buttons: Cancel, Create/Save                           │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ TagManagementView                                        │  │
│  │ • List of all tags                                       │  │
│  │ • Edit button (per tag)                                  │  │
│  │ • Delete button with confirmation (per tag)              │  │
│  │ • Buttons: New Tag, Done                                 │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                         Components                              │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ TagView                                                  │  │
│  │ • Renders single tag with shape                          │  │
│  │ • Selected/unselected states                             │  │
│  │ • Optional tap gesture                                   │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ TagCollectionView                                        │  │
│  │ • Uses FlowLayout for wrapping                           │  │
│  │ • Displays multiple TagViews                             │  │
│  │ • Optional selection handling                            │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ TagEditorView                                            │  │
│  │ • TagCollectionView with selection                       │  │
│  │ • Buttons: New Tag, Manage Tags                          │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ FlowLayout (Custom Layout)                               │  │
│  │ • Implements Layout protocol                             │  │
│  │ • Wraps tags naturally across lines                      │  │
│  │ • Efficient size calculation                             │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                          Models                                 │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Tag                                                      │  │
│  │ • id: UUID                                               │  │
│  │ • name: String                                           │  │
│  │ • color: Color                                           │  │
│  │ • shape: TagShape                                        │  │
│  │                                                          │  │
│  │ Conforms to:                                             │  │
│  │ • Identifiable                                           │  │
│  │ • Hashable (for Set operations)                          │  │
│  │ • Codable (for persistence)                              │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ TagShape (enum)                                          │  │
│  │ • capsule                                                │  │
│  │ • roundedRectangle                                       │  │
│  │ • circle                                                 │  │
│  │ • diamond                                                │  │
│  │                                                          │  │
│  │ Conforms to:                                             │  │
│  │ • String, CaseIterable, Codable                          │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ TaggedItem                                               │  │
│  │ • id: UUID                                               │  │
│  │ • title: String                                          │  │
│  │ • description: String                                    │  │
│  │ • tags: Set<Tag>                                         │  │
│  │                                                          │  │
│  │ Conforms to:                                             │  │
│  │ • Identifiable                                           │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow

### Tag Creation Flow
```
User → TagCreatorView → viewModel.addTag() 
     → availableTags updated 
     → UI refreshes automatically (@Observable)
```

### Tag Update Flow
```
User → TagCreatorView → viewModel.updateTag()
     → Update in availableTags
     → Update in all items' tag sets
     → Update in searchTags if present
     → UI refreshes everywhere (@Observable)
```

### Tag Deletion Flow
```
User → TagManagementView → Confirmation Alert → viewModel.deleteTag()
     → Remove from availableTags
     → Remove from all items
     → Remove from searchTags
     → UI refreshes (@Observable)
```

### Search/Filter Flow
```
User types → searchText binding updates
User selects tag → searchTags Set updates
     → viewModel.filteredItems recomputes
     → List updates with filtered results
```

### Item Tag Attachment Flow
```
User → ItemEditorView → TagEditorView → Toggle tag
     → editedItem.tags Set updates
User saves → viewModel.updateItemTags()
     → items array updated
     → UI refreshes
```

## Key Design Patterns

1. **MVVM**: ViewModel manages all business logic
2. **Observer Pattern**: @Observable for reactive updates
3. **Value Types**: Structs for models, efficient copying
4. **Set Operations**: O(1) tag membership checks
5. **Enum Navigation**: Type-safe sheet presentation
6. **Composition**: Small, reusable view components
7. **Protocol-Oriented**: Custom Layout protocol
8. **Unidirectional Flow**: Data flows from ViewModel to Views
