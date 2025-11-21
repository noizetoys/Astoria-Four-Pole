# Integration Guide

This guide shows how to integrate the Tag System into your existing SwiftUI project.

## Quick Integration

### 1. Add the Tag System Files
Copy `TagSystemView.swift` to your project.

### 2. Use in Your App
```swift
import SwiftUI

@main
struct YourApp: App {
    var body: some Scene {
        WindowGroup {
            TagSystemView()
        }
    }
}
```

## Custom Integration

### Using Your Own Models

You can adapt the tag system to work with your existing models:

```swift
// Your existing model
struct YourModel: Identifiable {
    var id = UUID()
    var title: String
    var tags: Set<Tag>  // Add this property
}

// Adapt the view model
@Observable
class YourViewModel {
    var items: [YourModel]
    var availableTags: [Tag]
    
    // Add tag management methods
    func addTag(_ tag: Tag) {
        availableTags.append(tag)
    }
    
    func updateTag(_ tag: Tag) {
        if let index = availableTags.firstIndex(where: { $0.id == tag.id }) {
            let oldTag = availableTags[index]
            availableTags[index] = tag
            
            // Update in all items
            for itemIndex in items.indices {
                if items[itemIndex].tags.contains(oldTag) {
                    items[itemIndex].tags.remove(oldTag)
                    items[itemIndex].tags.insert(tag)
                }
            }
        }
    }
    
    func deleteTag(_ tag: Tag) {
        availableTags.removeAll { $0.id == tag.id }
        for index in items.indices {
            items[index].tags.remove(tag)
        }
    }
}
```

### Persisting Tags

To persist tags using SwiftData or Core Data:

#### SwiftData Example
```swift
import SwiftData

@Model
class PersistedTag {
    var id: UUID
    var name: String
    var colorComponents: [Double]
    var shape: TagShape
    
    init(from tag: Tag) {
        self.id = tag.id
        self.name = tag.name
        self.shape = tag.shape
        
        #if os(macOS)
        let nsColor = NSColor(tag.color)
        self.colorComponents = [
            Double(nsColor.redComponent),
            Double(nsColor.greenComponent),
            Double(nsColor.blueComponent),
            Double(nsColor.alphaComponent)
        ]
        #else
        let uiColor = UIColor(tag.color)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        self.colorComponents = [Double(red), Double(green), Double(blue), Double(alpha)]
        #endif
    }
    
    func toTag() -> Tag {
        Tag(
            name: name,
            color: Color(
                red: colorComponents[0],
                green: colorComponents[1],
                blue: colorComponents[2],
                opacity: colorComponents[3]
            ),
            shape: shape
        )
    }
}

@Model
class PersistedItem {
    var id: UUID
    var title: String
    var tagIDs: [UUID]  // Store tag IDs, not tags directly
    
    // Resolve tags from a tag list
    func tags(from availableTags: [Tag]) -> Set<Tag> {
        Set(availableTags.filter { tagIDs.contains($0.id) })
    }
}
```

#### UserDefaults Example (Simple)
```swift
extension Tag {
    // Already Codable, so can use directly
    static func loadTags() -> [Tag] {
        guard let data = UserDefaults.standard.data(forKey: "tags"),
              let tags = try? JSONDecoder().decode([Tag].self, from: data) else {
            return Tag.sampleTags
        }
        return tags
    }
    
    static func saveTags(_ tags: [Tag]) {
        if let data = try? JSONEncoder().encode(tags) {
            UserDefaults.standard.set(data, forKey: "tags")
        }
    }
}

// In your view model
@Observable
class TagSystemViewModel {
    var availableTags: [Tag] {
        didSet {
            Tag.saveTags(availableTags)
        }
    }
    
    init() {
        self.availableTags = Tag.loadTags()
        // ... rest of init
    }
}
```

### Using Individual Components

You can use components independently:

#### Just Display Tags
```swift
struct MyView: View {
    let tags: [Tag]
    
    var body: some View {
        TagCollectionView(tags: tags)
    }
}
```

#### Tag Selection
```swift
struct MyView: View {
    @State private var selectedTags: Set<Tag> = []
    let availableTags: [Tag]
    
    var body: some View {
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
```

#### Tag Editor in Your Form
```swift
struct MyFormView: View {
    @State private var selectedTags: Set<Tag> = []
    let availableTags: [Tag]
    
    var body: some View {
        Form {
            Section("Your Fields") {
                // Your form fields
            }
            
            Section("Tags") {
                TagEditorView(
                    selectedTags: $selectedTags,
                    availableTags: availableTags
                )
            }
        }
    }
}
```

## iOS Compatibility

To make the system work on iOS, replace the sheet presentations:

```swift
// Instead of custom views with headers, use NavigationStack
struct ItemEditorView: View {
    // ... properties
    
    var body: some View {
        NavigationStack {
            Form {
                // ... form content
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: { onSave(editedItem) })
                }
            }
        }
    }
}
```

## Customization

### Custom Tag Shapes
Add new shapes to the `TagShape` enum:

```swift
enum TagShape: String, CaseIterable, Codable {
    case capsule = "Capsule"
    case roundedRectangle = "Rounded"
    case circle = "Circle"
    case diamond = "Diamond"
    case hexagon = "Hexagon"  // New!
    
    var iconName: String {
        switch self {
        case .capsule: return "capsule"
        case .roundedRectangle: return "square"
        case .circle: return "circle"
        case .diamond: return "diamond"
        case .hexagon: return "hexagon"
        }
    }
}

// Update TagView to handle the new shape
```

### Custom Colors
Modify the predefined colors in `TagCreatorView`:

```swift
private let predefinedColors: [Color] = [
    .red, .orange, .yellow, .green, .mint, .teal,
    .cyan, .blue, .indigo, .purple, .pink, .brown,
    // Add your brand colors
    Color(hex: "#FF6B6B"),
    Color(hex: "#4ECDC4"),
    // etc.
]
```

### Custom Tag Display
Create variations of `TagView` for different contexts:

```swift
struct CompactTagView: View {
    let tag: Tag
    
    var body: some View {
        Text(tag.name)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Capsule().fill(tag.color.opacity(0.2)))
            .foregroundStyle(tag.color)
    }
}

struct LargeTagView: View {
    let tag: Tag
    
    var body: some View {
        Text(tag.name)
            .font(.title3)
            .fontWeight(.semibold)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Capsule().fill(tag.color))
            .foregroundStyle(.white)
    }
}
```

## Tips

1. **Tag Limits**: Consider adding a maximum number of tags per item to prevent UI clutter
2. **Tag Validation**: Add duplicate name checking when creating tags
3. **Sorting**: Sort tags alphabetically or by usage frequency
4. **Tag Icons**: Extend Tag to include SF Symbol names for visual categorization
5. **Tag Groups**: Create hierarchical tag categories for better organization
6. **Shortcuts**: Add keyboard shortcuts for quick tag application
7. **Recently Used**: Track and display recently used tags for quick access

## Performance Considerations

- Tags use `Set<Tag>` for O(1) membership checking
- The `FlowLayout` efficiently wraps tags without nested VStacks
- `@Observable` minimizes unnecessary view updates
- Consider pagination for very large tag lists (100+)
