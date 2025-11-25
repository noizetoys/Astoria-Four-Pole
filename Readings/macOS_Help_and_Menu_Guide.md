# macOS Help System & SwiftUI Menu Management Guide

## Table of Contents
1. [Creating macOS Help Systems](#creating-macos-help-systems)
2. [SwiftUI Menu Commands Cheatsheet](#swiftui-menu-commands-cheatsheet)
3. [Basic Menu Creation](#basic-menu-creation)
4. [Nested Menus](#nested-menus)
5. [Dynamic Menus](#dynamic-menus)
6. [State-Based Menu Updates](#state-based-menu-updates)
7. [Adding and Removing Menu Items](#adding-and-removing-menu-items)
8. [Complete Examples](#complete-examples)

---

## Creating macOS Help Systems

### Overview
macOS applications can integrate help content that appears under the Help menu. There are several approaches to implementing help functionality.

### 1. Apple Help Books (Traditional Approach)

Apple Help Books are HTML-based help systems that integrate with macOS Spotlight search.

#### Setup Steps

**Create the Help Book folder structure:**
```
YourApp.app/
└── Contents/
    └── Resources/
        └── YourApp.help/
            └── Contents/
                ├── Info.plist
                └── Resources/
                    ├── English.lproj/
                    │   ├── index.html
                    │   ├── page1.html
                    │   └── shrd/
                    │       └── style.css
                    └── Images/
                        └── icon.png
```

**Info.plist for Help Book:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" 
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.yourcompany.yourapp.help</string>
    <key>CFBundleName</key>
    <string>YourApp Help</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>HPDBookAccessPath</key>
    <string>index.html</string>
    <key>HPDBookIconPath</key>
    <string>Images/icon.png</string>
    <key>HPDBookIndexPath</key>
    <string>index.html</string>
    <key>HPDBookTitle</key>
    <string>YourApp Help</string>
    <key>HPDBookType</key>
    <string>3</string>
</dict>
</plist>
```

**Main App Info.plist entry:**
```xml
<key>CFBundleHelpBookFolder</key>
<string>YourApp.help</string>
<key>CFBundleHelpBookName</key>
<string>com.yourcompany.yourapp.help</string>
```

**Sample Help HTML:**
```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="AppleTitle" content="YourApp Help">
    <meta name="AppleIcon" content="Images/icon.png">
    <title>YourApp Help</title>
    <link rel="stylesheet" href="shrd/style.css">
</head>
<body>
    <h1>YourApp Help</h1>
    <p>Welcome to YourApp help documentation.</p>
    
    <h2>Getting Started</h2>
    <p>Learn the basics of using YourApp.</p>
    
    <h2>Common Tasks</h2>
    <ul>
        <li><a href="task1.html">How to do Task 1</a></li>
        <li><a href="task2.html">How to do Task 2</a></li>
    </ul>
</body>
</html>
```

**Opening Help from SwiftUI:**
```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        Button("Open Help") {
            NSHelpManager.shared.openHelpAnchor(
                nil, 
                inBook: NSHelpManager.shared.helpBookName
            )
        }
    }
}
```

**Opening specific help pages:**
```swift
// Open help to a specific anchor
NSHelpManager.shared.openHelpAnchor(
    "getting_started",
    inBook: NSHelpManager.shared.helpBookName
)

// Search help for a specific term
NSHelpManager.shared.find("filter", in: nil)
```

### 2. Modern Approach: Web-Based Help

Many modern apps now use web-based help hosted online or shown in a WKWebView.

**SwiftUI with WKWebView:**
```swift
import SwiftUI
import WebKit

struct WebHelpView: View {
    let url: URL
    
    var body: some View {
        WebView(url: url)
            .frame(minWidth: 800, minHeight: 600)
    }
}

struct WebView: NSViewRepresentable {
    let url: URL
    
    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(URLRequest(url: url))
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        // Update if needed
    }
}

// Usage in menu command
.commands {
    CommandGroup(replacing: .help) {
        Button("YourApp Help") {
            if let url = URL(string: "https://yourapp.com/help") {
                NSWorkspace.shared.open(url)
            }
        }
        .keyboardShortcut("?", modifiers: .command)
    }
}
```

### 3. In-App Help Window

**Create a dedicated help window:**
```swift
import SwiftUI

class HelpWindowController: NSWindowController {
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "YourApp Help"
        window.contentView = NSHostingView(rootView: HelpContentView())
        
        self.init(window: window)
    }
}

struct HelpContentView: View {
    var body: some View {
        NavigationSplitView {
            List {
                NavigationLink("Getting Started") {
                    GettingStartedHelp()
                }
                NavigationLink("Features") {
                    FeaturesHelp()
                }
                NavigationLink("Troubleshooting") {
                    TroubleshootingHelp()
                }
            }
            .navigationTitle("Help Topics")
        } detail: {
            Text("Select a help topic")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

struct GettingStartedHelp: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Getting Started")
                    .font(.largeTitle)
                
                Text("Welcome to YourApp! Here's how to get started...")
                    .font(.body)
                
                // Add more help content
            }
            .padding()
        }
    }
}

// App struct with help window
@main
struct YourApp: App {
    @State private var helpWindow: NSWindow?
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandGroup(replacing: .help) {
                Button("YourApp Help") {
                    showHelp()
                }
                .keyboardShortcut("?", modifiers: .command)
            }
        }
    }
    
    func showHelp() {
        if let window = helpWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
        } else {
            let controller = HelpWindowController()
            controller.showWindow(nil)
            helpWindow = controller.window
        }
    }
}
```

### 4. Context-Sensitive Help

**Using Help Buttons:**
```swift
struct FeatureView: View {
    @State private var showingHelp = false
    
    var body: some View {
        VStack {
            HStack {
                Text("Complex Feature")
                    .font(.headline)
                
                Button {
                    showingHelp = true
                } label: {
                    Image(systemName: "questionmark.circle")
                }
                .buttonStyle(.plain)
                .help("Learn more about this feature")
            }
            
            // Feature content
        }
        .popover(isPresented: $showingHelp) {
            HelpPopoverView(topic: "complex_feature")
                .frame(width: 300, height: 200)
        }
    }
}

struct HelpPopoverView: View {
    let topic: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(helpTitle(for: topic))
                .font(.headline)
            
            Text(helpContent(for: topic))
                .font(.body)
            
            Button("Learn More") {
                openDetailedHelp(for: topic)
            }
        }
        .padding()
    }
    
    func helpTitle(for topic: String) -> String {
        // Return appropriate title
        "Feature Help"
    }
    
    func helpContent(for topic: String) -> String {
        // Return appropriate content
        "This feature allows you to..."
    }
    
    func openDetailedHelp(for topic: String) {
        // Open full help documentation
    }
}
```

---

## SwiftUI Menu Commands Cheatsheet

### Quick Reference Table

| Operation | Modifier | Example |
|-----------|----------|---------|
| Add new menu | `CommandMenu` | `CommandMenu("Tools") { }` |
| Replace existing menu | `CommandGroup(replacing:)` | `CommandGroup(replacing: .help) { }` |
| Add to existing menu | `CommandGroup(after:)` | `CommandGroup(after: .sidebar) { }` |
| Add before existing | `CommandGroup(before:)` | `CommandGroup(before: .help) { }` |
| Keyboard shortcut | `.keyboardShortcut()` | `.keyboardShortcut("n", modifiers: .command)` |
| Disable menu item | `.disabled()` | `.disabled(condition)` |
| Menu separator | `Divider()` | `Divider()` |
| Conditional item | `if` statement | `if condition { Button(...) }` |

### Standard Menu Placement IDs

```swift
.newItem          // File > New
.appInfo          // App menu items
.appSettings      // App > Settings
.appTermination   // App > Quit
.toolbar          // View > Toolbar items
.sidebar          // View > Sidebar items
.help             // Help menu
.systemServices   // Services menu
.textEditing      // Edit > Text operations
.textFormatting   // Format menu items
.undoRedo         // Edit > Undo/Redo
.standardEdit     // Edit > Cut/Copy/Paste
.printItem        // File > Print
.saveItem         // File > Save
```

---

## Basic Menu Creation

### 1. Creating a New Menu

```swift
import SwiftUI

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            // Create a new top-level menu
            CommandMenu("Tools") {
                Button("Process Data") {
                    processData()
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])
                
                Button("Export Results") {
                    exportResults()
                }
                .keyboardShortcut("e", modifiers: [.command, .option])
            }
        }
    }
    
    func processData() {
        print("Processing data...")
    }
    
    func exportResults() {
        print("Exporting results...")
    }
}
```

### 2. Adding to Existing Menus

```swift
.commands {
    // Add items after the New Item in File menu
    CommandGroup(after: .newItem) {
        Button("Open Recent") {
            openRecent()
        }
        .keyboardShortcut("r", modifiers: [.command, .shift])
        
        Divider()
    }
    
    // Add items before Help menu
    CommandGroup(before: .help) {
        Button("Check for Updates...") {
            checkForUpdates()
        }
    }
}
```

### 3. Replacing Existing Menus

```swift
.commands {
    // Replace the entire Help menu
    CommandGroup(replacing: .help) {
        Button("MyApp Help") {
            openHelp()
        }
        .keyboardShortcut("?", modifiers: .command)
        
        Button("Video Tutorials") {
            openTutorials()
        }
        
        Divider()
        
        Button("Report a Bug") {
            reportBug()
        }
        
        Button("Contact Support") {
            contactSupport()
        }
    }
}
```

### 4. Removing Menu Items

```swift
.commands {
    // Remove the New Item command
    CommandGroup(replacing: .newItem) {
        // Empty - effectively removes the item
    }
    
    // Or keep some items but remove others
    CommandGroup(replacing: .newItem) {
        Button("New Document") {
            createNewDocument()
        }
        .keyboardShortcut("n", modifiers: .command)
        // Other default new items are removed
    }
}
```

---

## Nested Menus

### 1. Basic Nested Menu

```swift
.commands {
    CommandMenu("Export") {
        // First level items
        Button("Export as PDF") {
            exportPDF()
        }
        
        Button("Export as Image") {
            exportImage()
        }
        
        Divider()
        
        // Nested submenu
        Menu("Export for Web") {
            Button("Export as HTML") {
                exportHTML()
            }
            
            Button("Export as SVG") {
                exportSVG()
            }
            
            Button("Export as PNG") {
                exportPNGForWeb()
            }
        }
        
        // Another nested submenu
        Menu("Export for Print") {
            Button("Export High-Res PDF") {
                exportHighResPDF()
            }
            
            Button("Export TIFF") {
                exportTIFF()
            }
            
            Menu("Professional Formats") {
                Button("Export as EPS") {
                    exportEPS()
                }
                
                Button("Export as AI") {
                    exportAI()
                }
            }
        }
    }
}
```

### 2. Deep Nesting Example

```swift
.commands {
    CommandMenu("View") {
        Menu("Zoom") {
            Button("Zoom In") {
                zoomIn()
            }
            .keyboardShortcut("+", modifiers: .command)
            
            Button("Zoom Out") {
                zoomOut()
            }
            .keyboardShortcut("-", modifiers: .command)
            
            Button("Actual Size") {
                actualSize()
            }
            .keyboardShortcut("0", modifiers: .command)
            
            Divider()
            
            Menu("Preset Zoom Levels") {
                Button("25%") { setZoom(0.25) }
                Button("50%") { setZoom(0.5) }
                Button("75%") { setZoom(0.75) }
                Button("100%") { setZoom(1.0) }
                Button("150%") { setZoom(1.5) }
                Button("200%") { setZoom(2.0) }
            }
        }
        
        Menu("Layout") {
            Button("Show Grid") {
                toggleGrid()
            }
            
            Button("Show Rulers") {
                toggleRulers()
            }
            
            Divider()
            
            Menu("Grid Settings") {
                Button("Fine Grid") { setGrid(.fine) }
                Button("Normal Grid") { setGrid(.normal) }
                Button("Coarse Grid") { setGrid(.coarse) }
            }
        }
    }
}
```

### 3. Nested Menus with State

```swift
@main
struct MyApp: App {
    @StateObject private var viewModel = AppViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
        .commands {
            CommandMenu("Display") {
                Menu("Theme") {
                    Button("Light") {
                        viewModel.theme = .light
                    }
                    .keyboardShortcut("l", modifiers: [.command, .option])
                    
                    Button("Dark") {
                        viewModel.theme = .dark
                    }
                    .keyboardShortcut("d", modifiers: [.command, .option])
                    
                    Button("Auto") {
                        viewModel.theme = .auto
                    }
                }
                
                Menu("Font Size") {
                    Button("Small") { viewModel.fontSize = .small }
                    Button("Medium") { viewModel.fontSize = .medium }
                    Button("Large") { viewModel.fontSize = .large }
                    Button("Extra Large") { viewModel.fontSize = .extraLarge }
                }
            }
        }
    }
}

class AppViewModel: ObservableObject {
    @Published var theme: Theme = .auto
    @Published var fontSize: FontSize = .medium
}

enum Theme {
    case light, dark, auto
}

enum FontSize {
    case small, medium, large, extraLarge
}
```

---

## Dynamic Menus

### 1. Menu Items Based on Array Data

```swift
@main
struct DocumentApp: App {
    @StateObject private var documentManager = DocumentManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(documentManager)
        }
        .commands {
            CommandMenu("Documents") {
                // Dynamic menu items from array
                ForEach(documentManager.recentDocuments) { document in
                    Button(document.name) {
                        documentManager.open(document)
                    }
                }
                
                if !documentManager.recentDocuments.isEmpty {
                    Divider()
                }
                
                Button("Clear Recent") {
                    documentManager.clearRecent()
                }
                .disabled(documentManager.recentDocuments.isEmpty)
            }
        }
    }
}

class DocumentManager: ObservableObject {
    @Published var recentDocuments: [Document] = []
    
    func open(_ document: Document) {
        print("Opening: \(document.name)")
    }
    
    func clearRecent() {
        recentDocuments.removeAll()
    }
}

struct Document: Identifiable {
    let id = UUID()
    let name: String
    let url: URL
}
```

### 2. Nested Dynamic Menus

```swift
.commands {
    CommandMenu("Presets") {
        ForEach(presetCategories) { category in
            Menu(category.name) {
                ForEach(category.presets) { preset in
                    Button(preset.name) {
                        applyPreset(preset)
                    }
                }
            }
        }
    }
}

struct PresetCategory: Identifiable {
    let id = UUID()
    let name: String
    let presets: [Preset]
}

struct Preset: Identifiable {
    let id = UUID()
    let name: String
    let settings: [String: Any]
}
```

### 3. Dynamic Menu with Conditional Items

```swift
@main
struct MyApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandMenu("Project") {
                // Show different items based on project state
                if let project = appState.currentProject {
                    Button("Close Project") {
                        appState.closeProject()
                    }
                    .keyboardShortcut("w", modifiers: [.command, .shift])
                    
                    Divider()
                    
                    Button("Project Settings") {
                        appState.showProjectSettings()
                    }
                    
                    Menu("Export Project") {
                        ForEach(project.availableExportFormats, id: \.self) { format in
                            Button("Export as \(format)") {
                                appState.export(format: format)
                            }
                        }
                    }
                    
                } else {
                    Button("Open Project...") {
                        appState.openProject()
                    }
                    .keyboardShortcut("o", modifiers: .command)
                    
                    Button("New Project...") {
                        appState.newProject()
                    }
                    .keyboardShortcut("n", modifiers: .command)
                    
                    if !appState.recentProjects.isEmpty {
                        Divider()
                        
                        Menu("Open Recent") {
                            ForEach(appState.recentProjects) { project in
                                Button(project.name) {
                                    appState.open(project)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

class AppState: ObservableObject {
    @Published var currentProject: Project?
    @Published var recentProjects: [ProjectInfo] = []
    
    func closeProject() { }
    func showProjectSettings() { }
    func export(format: String) { }
    func openProject() { }
    func newProject() { }
    func open(_ project: ProjectInfo) { }
}

struct Project {
    let availableExportFormats: [String]
}

struct ProjectInfo: Identifiable {
    let id = UUID()
    let name: String
}
```

---

## State-Based Menu Updates

### 1. Using @FocusedValue for Context-Aware Menus

```swift
// Define the focused value key
struct DocumentFocusedValueKey: FocusedValueKey {
    typealias Value = DocumentController
}

extension FocusedValues {
    var documentController: DocumentFocusedValueKey.Value? {
        get { self[DocumentFocusedValueKey.self] }
        set { self[DocumentFocusedValueKey.self] = newValue }
    }
}

// Document controller
class DocumentController: ObservableObject {
    @Published var canUndo = false
    @Published var canRedo = false
    @Published var hasSelection = false
    
    func undo() {
        print("Undo")
    }
    
    func redo() {
        print("Redo")
    }
    
    func cut() {
        print("Cut")
    }
    
    func copy() {
        print("Copy")
    }
    
    func paste() {
        print("Paste")
    }
}

// View with focused value
struct DocumentView: View {
    @StateObject private var controller = DocumentController()
    
    var body: some View {
        Text("Document Content")
            .focusedValue(\.documentController, controller)
    }
}

// App with focused value commands
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            DocumentView()
        }
        .commands {
            CommandGroup(replacing: .undoRedo) {
                Button("Undo") {
                    focusedDocument?.undo()
                }
                .keyboardShortcut("z", modifiers: .command)
                .disabled(focusedDocument?.canUndo != true)
                
                Button("Redo") {
                    focusedDocument?.redo()
                }
                .keyboardShortcut("z", modifiers: [.command, .shift])
                .disabled(focusedDocument?.canRedo != true)
            }
            
            CommandGroup(after: .standardEdit) {
                Button("Cut") {
                    focusedDocument?.cut()
                }
                .keyboardShortcut("x", modifiers: .command)
                .disabled(focusedDocument?.hasSelection != true)
                
                Button("Copy") {
                    focusedDocument?.copy()
                }
                .keyboardShortcut("c", modifiers: .command)
                .disabled(focusedDocument?.hasSelection != true)
                
                Button("Paste") {
                    focusedDocument?.paste()
                }
                .keyboardShortcut("v", modifiers: .command)
            }
        }
    }
    
    @FocusedValue(\.documentController) private var focusedDocument: DocumentController?
}
```

### 2. Selection-Based Menu States

```swift
@main
struct EditorApp: App {
    @StateObject private var selectionManager = SelectionManager()
    
    var body: some Scene {
        WindowGroup {
            EditorView()
                .environmentObject(selectionManager)
        }
        .commands {
            CommandMenu("Selection") {
                Button("Select All") {
                    selectionManager.selectAll()
                }
                .keyboardShortcut("a", modifiers: .command)
                
                Button("Deselect All") {
                    selectionManager.deselectAll()
                }
                .keyboardShortcut("d", modifiers: .command)
                .disabled(!selectionManager.hasSelection)
                
                Button("Invert Selection") {
                    selectionManager.invertSelection()
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])
                .disabled(selectionManager.isEmpty)
                
                Divider()
                
                Button("Delete Selected") {
                    selectionManager.deleteSelected()
                }
                .keyboardShortcut(.delete, modifiers: [])
                .disabled(!selectionManager.hasSelection)
                
                if selectionManager.selectionCount > 0 {
                    Divider()
                    
                    Text("Selected: \(selectionManager.selectionCount) items")
                        .disabled(true)
                }
            }
        }
    }
}

class SelectionManager: ObservableObject {
    @Published var selectedItems: Set<UUID> = []
    @Published var totalItems = 0
    
    var hasSelection: Bool {
        !selectedItems.isEmpty
    }
    
    var isEmpty: Bool {
        totalItems == 0
    }
    
    var selectionCount: Int {
        selectedItems.count
    }
    
    func selectAll() { }
    func deselectAll() { }
    func invertSelection() { }
    func deleteSelected() { }
}
```

### 3. Checkmark Menu Items (Toggle States)

```swift
@main
struct MyApp: App {
    @StateObject private var preferences = Preferences()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(preferences)
        }
        .commands {
            CommandMenu("View") {
                Toggle("Show Toolbar", isOn: $preferences.showToolbar)
                    .keyboardShortcut("t", modifiers: [.command, .option])
                
                Toggle("Show Sidebar", isOn: $preferences.showSidebar)
                    .keyboardShortcut("s", modifiers: [.command, .option])
                
                Toggle("Show Inspector", isOn: $preferences.showInspector)
                    .keyboardShortcut("i", modifiers: [.command, .option])
                
                Divider()
                
                Toggle("Show Line Numbers", isOn: $preferences.showLineNumbers)
                
                Toggle("Show Invisibles", isOn: $preferences.showInvisibles)
                
                Toggle("Wrap Text", isOn: $preferences.wrapText)
                    .keyboardShortcut("w", modifiers: [.command, .option])
            }
        }
    }
}

class Preferences: ObservableObject {
    @Published var showToolbar = true
    @Published var showSidebar = true
    @Published var showInspector = false
    @Published var showLineNumbers = true
    @Published var showInvisibles = false
    @Published var wrapText = true
}
```

### 4. Radio Button Menu Groups

```swift
@main
struct MyApp: App {
    @StateObject private var viewSettings = ViewSettings()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewSettings)
        }
        .commands {
            CommandMenu("View") {
                Menu("Sort By") {
                    Picker("Sort By", selection: $viewSettings.sortOrder) {
                        Text("Name").tag(SortOrder.name)
                        Text("Date Modified").tag(SortOrder.dateModified)
                        Text("Size").tag(SortOrder.size)
                        Text("Type").tag(SortOrder.type)
                    }
                    .pickerStyle(.inline)
                }
                
                Divider()
                
                Menu("View Mode") {
                    Picker("View Mode", selection: $viewSettings.viewMode) {
                        Label("Icon View", systemImage: "square.grid.2x2")
                            .tag(ViewMode.icon)
                        
                        Label("List View", systemImage: "list.bullet")
                            .tag(ViewMode.list)
                        
                        Label("Column View", systemImage: "rectangle.split.3x1")
                            .tag(ViewMode.column)
                    }
                    .pickerStyle(.inline)
                }
            }
        }
    }
}

class ViewSettings: ObservableObject {
    @Published var sortOrder: SortOrder = .name
    @Published var viewMode: ViewMode = .list
}

enum SortOrder {
    case name, dateModified, size, type
}

enum ViewMode {
    case icon, list, column
}
```

---

## Adding and Removing Menu Items

### 1. Conditionally Adding Menu Items

```swift
@main
struct MyApp: App {
    @StateObject private var appState = AppState()
    @AppStorage("showDebugMenu") private var showDebugMenu = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            // Add debug menu only if enabled
            if showDebugMenu {
                CommandMenu("Debug") {
                    Button("Print State") {
                        appState.printState()
                    }
                    
                    Button("Reset to Defaults") {
                        appState.reset()
                    }
                    
                    Button("Simulate Error") {
                        appState.simulateError()
                    }
                    
                    Divider()
                    
                    Button("Hide Debug Menu") {
                        showDebugMenu = false
                    }
                }
            }
            
            // Standard menu with conditional items
            CommandMenu("Tools") {
                Button("Tool 1") {
                    print("Tool 1")
                }
                
                // Show this item only when conditions are met
                if appState.isAdvancedMode {
                    Button("Advanced Tool") {
                        print("Advanced Tool")
                    }
                }
                
                // Show different items based on state
                if appState.isProcessing {
                    Button("Cancel Processing") {
                        appState.cancelProcessing()
                    }
                } else {
                    Button("Start Processing") {
                        appState.startProcessing()
                    }
                }
            }
        }
    }
}

class AppState: ObservableObject {
    @Published var isAdvancedMode = false
    @Published var isProcessing = false
    
    func printState() { }
    func reset() { }
    func simulateError() { }
    func startProcessing() { }
    func cancelProcessing() { }
}
```

### 2. Dynamically Building Menu Structures

```swift
@main
struct PluginApp: App {
    @StateObject private var pluginManager = PluginManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            // Dynamically create menus for each plugin
            ForEach(pluginManager.plugins) { plugin in
                CommandMenu(plugin.name) {
                    ForEach(plugin.menuItems) { item in
                        Button(item.title) {
                            plugin.execute(item)
                        }
                        .keyboardShortcut(item.shortcut)
                        .disabled(!item.isEnabled)
                    }
                    
                    if plugin.hasSettings {
                        Divider()
                        
                        Button("\(plugin.name) Settings...") {
                            plugin.showSettings()
                        }
                    }
                }
            }
            
            // Menu to manage plugins
            CommandMenu("Plugins") {
                Button("Manage Plugins...") {
                    pluginManager.showManager()
                }
                
                Divider()
                
                if pluginManager.plugins.isEmpty {
                    Text("No plugins installed")
                        .disabled(true)
                } else {
                    ForEach(pluginManager.plugins) { plugin in
                        Toggle(plugin.name, isOn: binding(for: plugin))
                    }
                }
            }
        }
    }
    
    private func binding(for plugin: Plugin) -> Binding<Bool> {
        Binding(
            get: { plugin.isEnabled },
            set: { pluginManager.setEnabled($0, for: plugin) }
        )
    }
}

class PluginManager: ObservableObject {
    @Published var plugins: [Plugin] = []
    
    func showManager() { }
    func setEnabled(_ enabled: Bool, for plugin: Plugin) { }
}

struct Plugin: Identifiable {
    let id = UUID()
    let name: String
    let menuItems: [PluginMenuItem]
    let hasSettings: Bool
    var isEnabled: Bool
    
    func execute(_ item: PluginMenuItem) { }
    func showSettings() { }
}

struct PluginMenuItem: Identifiable {
    let id = UUID()
    let title: String
    let shortcut: KeyEquivalent?
    let isEnabled: Bool
    
    init(title: String, shortcut: KeyEquivalent? = nil, isEnabled: Bool = true) {
        self.title = title
        self.shortcut = shortcut
        self.isEnabled = isEnabled
    }
}
```

### 3. Programmatically Removing and Restoring Menus

```swift
@main
struct CustomizableApp: App {
    @StateObject private var menuConfiguration = MenuConfiguration()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            // File menu customization
            if menuConfiguration.showFileMenu {
                CommandGroup(after: .newItem) {
                    Button("Import...") {
                        print("Import")
                    }
                }
            } else {
                // Replace with minimal version
                CommandGroup(replacing: .newItem) {
                    Button("Open...") {
                        print("Open")
                    }
                    .keyboardShortcut("o", modifiers: .command)
                }
            }
            
            // Edit menu customization
            if !menuConfiguration.showEditMenu {
                CommandGroup(replacing: .standardEdit) {
                    // Empty - removes edit menu
                }
            }
            
            // View menu - only show if enabled
            if menuConfiguration.showViewMenu {
                CommandMenu("View") {
                    ForEach(menuConfiguration.viewMenuItems) { item in
                        Button(item.title) {
                            item.action()
                        }
                    }
                }
            }
            
            // Menu configuration menu
            CommandMenu("Customize") {
                Toggle("Show File Menu", isOn: $menuConfiguration.showFileMenu)
                Toggle("Show Edit Menu", isOn: $menuConfiguration.showEditMenu)
                Toggle("Show View Menu", isOn: $menuConfiguration.showViewMenu)
                
                Divider()
                
                Button("Reset to Defaults") {
                    menuConfiguration.resetToDefaults()
                }
            }
        }
    }
}

class MenuConfiguration: ObservableObject {
    @Published var showFileMenu = true
    @Published var showEditMenu = true
    @Published var showViewMenu = true
    @Published var viewMenuItems: [MenuItem] = []
    
    init() {
        resetToDefaults()
    }
    
    func resetToDefaults() {
        showFileMenu = true
        showEditMenu = true
        showViewMenu = true
        viewMenuItems = [
            MenuItem(title: "Zoom In") { print("Zoom In") },
            MenuItem(title: "Zoom Out") { print("Zoom Out") },
            MenuItem(title: "Actual Size") { print("Actual Size") }
        ]
    }
}

struct MenuItem: Identifiable {
    let id = UUID()
    let title: String
    let action: () -> Void
}
```

---

## Complete Examples

### Example 1: Full-Featured Text Editor

```swift
import SwiftUI

@main
struct TextEditorApp: App {
    @StateObject private var editorState = EditorState()
    
    var body: some Scene {
        WindowGroup {
            EditorView()
                .environmentObject(editorState)
        }
        .commands {
            // File menu additions
            CommandGroup(after: .newItem) {
                Button("Open Recent") {
                    editorState.showRecentFiles()
                }
                
                Divider()
                
                Button("Save All") {
                    editorState.saveAll()
                }
                .keyboardShortcut("s", modifiers: [.command, .option])
                .disabled(editorState.openDocuments.isEmpty)
            }
            
            // Edit menu with dynamic states
            CommandGroup(after: .standardEdit) {
                Divider()
                
                Button("Find...") {
                    editorState.showFind()
                }
                .keyboardShortcut("f", modifiers: .command)
                
                Button("Find Next") {
                    editorState.findNext()
                }
                .keyboardShortcut("g", modifiers: .command)
                .disabled(!editorState.hasFindResults)
                
                Button("Replace...") {
                    editorState.showReplace()
                }
                .keyboardShortcut("f", modifiers: [.command, .option])
            }
            
            // Format menu
            CommandMenu("Format") {
                Menu("Font") {
                    Button("Bigger") {
                        editorState.increaseFontSize()
                    }
                    .keyboardShortcut("+", modifiers: .command)
                    
                    Button("Smaller") {
                        editorState.decreaseFontSize()
                    }
                    .keyboardShortcut("-", modifiers: .command)
                    
                    Divider()
                    
                    ForEach(editorState.availableFonts, id: \.self) { font in
                        Button(font) {
                            editorState.setFont(font)
                        }
                    }
                }
                
                Divider()
                
                Toggle("Bold", isOn: $editorState.isBold)
                    .keyboardShortcut("b", modifiers: .command)
                
                Toggle("Italic", isOn: $editorState.isItalic)
                    .keyboardShortcut("i", modifiers: .command)
                
                Toggle("Underline", isOn: $editorState.isUnderline)
                    .keyboardShortcut("u", modifiers: .command)
            }
            
            // View menu
            CommandMenu("View") {
                Toggle("Show Toolbar", isOn: $editorState.showToolbar)
                Toggle("Show Line Numbers", isOn: $editorState.showLineNumbers)
                Toggle("Show Invisibles", isOn: $editorState.showInvisibles)
                
                Divider()
                
                Menu("Syntax Highlighting") {
                    ForEach(SyntaxMode.allCases, id: \.self) { mode in
                        Button(mode.rawValue) {
                            editorState.syntaxMode = mode
                        }
                    }
                }
                
                Menu("Theme") {
                    ForEach(Theme.allCases, id: \.self) { theme in
                        Button(theme.rawValue) {
                            editorState.theme = theme
                        }
                    }
                }
            }
            
            // Replace Help menu
            CommandGroup(replacing: .help) {
                Button("Text Editor Help") {
                    editorState.showHelp()
                }
                .keyboardShortcut("?", modifiers: .command)
                
                Button("Keyboard Shortcuts") {
                    editorState.showKeyboardShortcuts()
                }
                
                Divider()
                
                Button("Check for Updates...") {
                    editorState.checkForUpdates()
                }
            }
        }
    }
}

class EditorState: ObservableObject {
    @Published var openDocuments: [Document] = []
    @Published var hasFindResults = false
    @Published var showToolbar = true
    @Published var showLineNumbers = true
    @Published var showInvisibles = false
    @Published var isBold = false
    @Published var isItalic = false
    @Published var isUnderline = false
    @Published var syntaxMode: SyntaxMode = .plainText
    @Published var theme: Theme = .light
    
    let availableFonts = ["SF Mono", "Menlo", "Monaco", "Courier"]
    
    func showRecentFiles() { }
    func saveAll() { }
    func showFind() { }
    func findNext() { }
    func showReplace() { }
    func increaseFontSize() { }
    func decreaseFontSize() { }
    func setFont(_ font: String) { }
    func showHelp() { }
    func showKeyboardShortcuts() { }
    func checkForUpdates() { }
}

enum SyntaxMode: String, CaseIterable {
    case plainText = "Plain Text"
    case swift = "Swift"
    case python = "Python"
    case javascript = "JavaScript"
    case markdown = "Markdown"
}

enum Theme: String, CaseIterable {
    case light = "Light"
    case dark = "Dark"
    case auto = "Auto"
}

struct EditorView: View {
    var body: some View {
        Text("Editor Content")
    }
}
```

### Example 2: MIDI Application with Contextual Menus

```swift
import SwiftUI

@main
struct MIDIApp: App {
    @StateObject private var midiManager = MIDIManager()
    
    var body: some Scene {
        WindowGroup {
            MIDIEditorView()
                .environmentObject(midiManager)
        }
        .commands {
            // MIDI menu
            CommandMenu("MIDI") {
                Menu("Input Device") {
                    if midiManager.availableInputs.isEmpty {
                        Text("No MIDI inputs available")
                            .disabled(true)
                    } else {
                        ForEach(midiManager.availableInputs) { input in
                            Button(input.name) {
                                midiManager.selectInput(input)
                            }
                        }
                    }
                    
                    Divider()
                    
                    Button("Refresh Devices") {
                        midiManager.refreshDevices()
                    }
                }
                
                Menu("Output Device") {
                    if midiManager.availableOutputs.isEmpty {
                        Text("No MIDI outputs available")
                            .disabled(true)
                    } else {
                        ForEach(midiManager.availableOutputs) { output in
                            Button(output.name) {
                                midiManager.selectOutput(output)
                            }
                        }
                    }
                }
                
                Divider()
                
                Toggle("MIDI Monitor", isOn: $midiManager.showMonitor)
                    .keyboardShortcut("m", modifiers: [.command, .shift])
                
                Toggle("MIDI Thru", isOn: $midiManager.midiThru)
            }
            
            // Patch menu
            CommandMenu("Patch") {
                Button("New Patch") {
                    midiManager.newPatch()
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Button("Load Patch...") {
                    midiManager.loadPatch()
                }
                .keyboardShortcut("o", modifiers: .command)
                
                Button("Save Patch") {
                    midiManager.savePatch()
                }
                .keyboardShortcut("s", modifiers: .command)
                .disabled(midiManager.currentPatch == nil)
                
                Button("Save Patch As...") {
                    midiManager.savePatchAs()
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
                .disabled(midiManager.currentPatch == nil)
                
                if !midiManager.recentPatches.isEmpty {
                    Divider()
                    
                    Menu("Recent Patches") {
                        ForEach(midiManager.recentPatches) { patch in
                            Button(patch.name) {
                                midiManager.load(patch)
                            }
                        }
                        
                        Divider()
                        
                        Button("Clear Recent") {
                            midiManager.clearRecentPatches()
                        }
                    }
                }
                
                Divider()
                
                Button("Send to Device") {
                    midiManager.sendPatchToDevice()
                }
                .keyboardShortcut("t", modifiers: .command)
                .disabled(midiManager.currentPatch == nil || midiManager.selectedOutput == nil)
                
                Button("Request from Device") {
                    midiManager.requestPatchFromDevice()
                }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(midiManager.selectedInput == nil)
            }
            
            // Transport menu
            CommandMenu("Transport") {
                if midiManager.isPlaying {
                    Button("Stop") {
                        midiManager.stop()
                    }
                    .keyboardShortcut(.space, modifiers: [])
                } else {
                    Button("Play") {
                        midiManager.play()
                    }
                    .keyboardShortcut(.space, modifiers: [])
                }
                
                Button("Record") {
                    midiManager.record()
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
                
                Divider()
                
                Button("Go to Start") {
                    midiManager.goToStart()
                }
                .keyboardShortcut(.return, modifiers: [])
                
                Button("Panic (All Notes Off)") {
                    midiManager.panic()
                }
                .keyboardShortcut(.escape, modifiers: [])
            }
        }
    }
}

class MIDIManager: ObservableObject {
    @Published var availableInputs: [MIDIDevice] = []
    @Published var availableOutputs: [MIDIDevice] = []
    @Published var selectedInput: MIDIDevice?
    @Published var selectedOutput: MIDIDevice?
    @Published var showMonitor = false
    @Published var midiThru = false
    @Published var currentPatch: Patch?
    @Published var recentPatches: [PatchInfo] = []
    @Published var isPlaying = false
    
    func selectInput(_ device: MIDIDevice) { }
    func selectOutput(_ device: MIDIDevice) { }
    func refreshDevices() { }
    func newPatch() { }
    func loadPatch() { }
    func savePatch() { }
    func savePatchAs() { }
    func load(_ patch: PatchInfo) { }
    func clearRecentPatches() { }
    func sendPatchToDevice() { }
    func requestPatchFromDevice() { }
    func play() { isPlaying = true }
    func stop() { isPlaying = false }
    func record() { }
    func goToStart() { }
    func panic() { }
}

struct MIDIDevice: Identifiable {
    let id = UUID()
    let name: String
}

struct Patch {
    let parameters: [String: Any]
}

struct PatchInfo: Identifiable {
    let id = UUID()
    let name: String
    let url: URL
}

struct MIDIEditorView: View {
    var body: some View {
        Text("MIDI Editor")
    }
}
```

---

## Best Practices

### 1. Keyboard Shortcuts

```swift
// Standard shortcuts
.keyboardShortcut("n", modifiers: .command)                    // ⌘N
.keyboardShortcut("s", modifiers: [.command, .shift])          // ⌘⇧S
.keyboardShortcut("f", modifiers: [.command, .option])         // ⌘⌥F
.keyboardShortcut("z", modifiers: [.command, .shift, .option]) // ⌘⇧⌥Z

// Special keys
.keyboardShortcut(.space, modifiers: [])
.keyboardShortcut(.return, modifiers: .command)
.keyboardShortcut(.delete, modifiers: [])
.keyboardShortcut(.escape, modifiers: [])
.keyboardShortcut(.leftArrow, modifiers: .command)
.keyboardShortcut(.rightArrow, modifiers: .command)

// Function keys
.keyboardShortcut(.f1, modifiers: [])
.keyboardShortcut(.f5, modifiers: .command)
```

### 2. Menu Organization

- Group related commands together
- Use dividers to separate logical sections
- Place frequently used items near the top
- Use submenus for related options (but don't nest too deeply)
- Follow macOS Human Interface Guidelines for standard menu placement

### 3. Enabling/Disabling Items

```swift
// Disable based on conditions
.disabled(document == nil)
.disabled(!hasSelection)
.disabled(isProcessing)

// Use conditional logic
if canPerformAction {
    Button("Action") { performAction() }
} else {
    Button("Action") { }
        .disabled(true)
}
```

### 4. Performance Considerations

- Use `@StateObject` for shared state across menus
- Avoid heavy computations in menu builders
- Use `@FocusedValue` for context-aware menus
- Cache expensive operations

---

## Troubleshooting

### Common Issues

**Issue**: Menu items not appearing
- Check that `.commands` is attached to the Scene, not a View
- Verify that conditional logic isn't hiding items unexpectedly

**Issue**: Keyboard shortcuts not working
- Ensure shortcuts don't conflict with system shortcuts
- Check that the focused view isn't capturing the key events

**Issue**: Menu state not updating
- Use `@Published` properties in ObservableObject
- Ensure state changes trigger view updates
- Check that the correct binding is being used

**Issue**: Dynamic menus not refreshing
- Verify that ForEach has stable, unique identifiers
- Check that the data source is @Published
- Ensure the menu commands have access to the updated state

---

## Additional Resources

### Apple Documentation
- [App and Scene Structure](https://developer.apple.com/documentation/swiftui/app-structure)
- [Menus and Commands](https://developer.apple.com/documentation/swiftui/commands)
- [Human Interface Guidelines - Menus](https://developer.apple.com/design/human-interface-guidelines/menus)
- [Apple Help Programming Guide](https://developer.apple.com/library/archive/documentation/Carbon/Conceptual/ProvidingUserAssitAppleHelp/)

### Key Types to Know
- `CommandMenu`: Create a new top-level menu
- `CommandGroup`: Modify existing menus
- `Menu`: Create nested submenus
- `Button`: Menu action items
- `Toggle`: Menu items with checkmarks
- `Picker`: Radio button groups in menus
- `Divider`: Menu separators

---

*Created for SwiftUI macOS development - Updated for latest SwiftUI APIs*
