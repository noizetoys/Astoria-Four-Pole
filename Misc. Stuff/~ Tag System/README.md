# SwiftUI Tag Management System

A comprehensive tag management system built with SwiftUI, optimized for macOS with cross-platform support.

## Features

### Tag Management
- **Create Tags**: Create new tags with custom names, colors, and shapes
- **Edit Tags**: Update existing tags (changes propagate to all items using that tag)
- **Delete Tags**: Remove tags (automatically removed from all items)
- **Tag Properties**:
  - Name (customizable)
  - Color (12 preset colors + custom color picker)
  - Shape (Capsule, Rounded Rectangle, Circle, Diamond)

### Item Management
- **View Items**: Browse all items with their associated tags
- **Edit Items**: Modify item details and attach/detach tags
- **Search & Filter**:
  - Text search across item titles and descriptions
  - Multi-tag filtering (find items containing specific tags)
  - Expandable tag filter UI

### UI/UX Features
- **Native macOS Design**: Uses sheets optimized for macOS presentation
- **FlowLayout**: Tags automatically wrap to fit available width
- **Visual Feedback**: Selected/unselected states for tags
- **Keyboard Shortcuts**:
  - Return/Enter to save
  - Escape to cancel
- **Confirmation Dialogs**: Safe deletion with confirmation alerts

## Architecture

### Models
- `Tag`: Codable model with id, name, color, and shape
- `TaggedItem`: Items that can have multiple tags attached
- `TagSystemViewModel`: Observable state management for the entire system

### Views
- `TagView`: Individual tag display with shape support
- `TagCollectionView`: Flowing collection of tags
- `ItemCardView`: Card showing item with tags
- `TagEditorView`: Interface for attaching tags to items
- `ItemEditorView`: Full item editor
- `TagCreatorView`: Create/edit individual tags
- `TagManagementView`: List view for managing all tags
- `SearchBarView`: Search and filter interface

### Custom Layouts
- `FlowLayout`: Custom Layout protocol implementation for wrapping tags

## Usage

### Running the App
```swift
import SwiftUI

@main
struct TagSystemApp: App {
    var body: some Scene {
        WindowGroup {
            TagSystemView()
        }
    }
}
```

### Managing Tags
1. Click "Manage Tags" in the toolbar
2. Click "New Tag" to create a tag
3. Choose name, color, and shape
4. Click "Save" or "Create"
5. Edit existing tags by clicking the pencil icon
6. Delete tags by clicking the trash icon (with confirmation)

### Tagging Items
1. Click any item card
2. Select/deselect tags by clicking them
3. Create new tags from within the editor
4. Access tag management from the editor
5. Click "Save" to apply changes

### Searching
1. Enter text in the search bar to filter by title/description
2. Click "Filter by Tags" to expand tag filters
3. Click tags to filter items (multiple tags = AND logic)
4. Badge shows count of active tag filters

## Sample Data

The app includes 7 sample items with various tag combinations:
- Quarterly Review (Work, Urgent)
- Vacation Planning (Personal, Travel)
- Budget Review (Finance, Personal)
- New Project Ideas (Work, Ideas)
- Grocery Shopping (Home, Shopping)
- SwiftUI Course (Learning, Personal)
- Doctor Appointment (Health, Urgent)

10 preset tags with different colors and shapes are included.

## Key Implementation Details

### Observable Macro
Uses SwiftUI's `@Observable` macro for efficient state management without manual `@Published` declarations.

### Tag Identity & Equality
Tags use `Hashable` conformance for Set operations, with UUID-based identity and value-based equality for proper update propagation.

### Cross-Platform Colors
Custom `Color.controlBackground` extension handles platform differences between macOS (NSColor) and iOS (UIColor).

### Sheet Navigation
Uses enum-based `ActiveSheet` with `Identifiable` conformance for clean sheet navigation and state management.

### Tag Update Propagation
When a tag is updated, the view model automatically updates it in all items and search filters, maintaining referential integrity throughout the app.

## Requirements

- macOS 14.0+ (for @Observable and modern SwiftUI features)
- Xcode 15.0+
- Swift 5.9+

## License

Sample code for educational purposes.
