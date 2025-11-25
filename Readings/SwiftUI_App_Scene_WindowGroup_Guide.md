# SwiftUI App Architecture: App, Scene, and WindowGroup

A comprehensive guide to understanding the fundamental building blocks of SwiftUI applications on iOS and macOS.

---

## Table of Contents

1. [Overview](#overview)
2. [The App Protocol](#the-app-protocol)
3. [Scene Protocol](#scene-protocol)
4. [WindowGroup](#windowgroup)
5. [Other Scene Types](#other-scene-types)
6. [Relationships and Architecture](#relationships-and-architecture)
7. [Platform Differences](#platform-differences)
8. [Best Practices and Guidelines](#best-practices-and-guidelines)
9. [Common Patterns](#common-patterns)
10. [Troubleshooting](#troubleshooting)

---

## Overview

SwiftUI introduces a declarative approach to defining your app's structure through three fundamental concepts:

- **App**: The entry point and lifecycle manager for your application
- **Scene**: A container representing a distinct part of your app's user interface
- **WindowGroup**: The most common scene type that manages one or more windows

These components replaced the traditional AppDelegate and SceneDelegate pattern from UIKit, providing a more declarative and SwiftUI-native approach to app architecture.

### Historical Context

Before SwiftUI 2.0 (iOS 14/macOS 11), SwiftUI apps still relied on:
- `UIApplicationDelegate` (iOS) or `NSApplicationDelegate` (macOS)
- `UISceneDelegate` (iOS 13+)
- Manual scene and window configuration

The introduction of `@main`, `App`, and `Scene` protocols modernized this approach, making it fully declarative and type-safe.

---

## The App Protocol

### Purpose

The `App` protocol defines the entry point and overall structure of your SwiftUI application. It replaces the traditional AppDelegate pattern with a declarative approach.

### Core Responsibilities

1. **Application Entry Point**: Marked with `@main` to identify where the app begins
2. **Scene Definition**: Declares what scenes your app contains
3. **App-Wide State**: Manages global state and configuration
4. **Lifecycle Management**: Handles app-level lifecycle events

### Basic Structure

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### Key Components

#### The @main Attribute

```swift
@main  // Tells Swift this is the entry point
struct MyApp: App {
    // ...
}
```

**What it does:**
- Designates this structure as the application's entry point
- Equivalent to providing a `main.swift` file with `@UIApplicationMain` or `@NSApplicationMain`
- Only one `@main` per target is allowed

**Why it's needed:**
Every application needs an entry point where execution begins. In SwiftUI, `@main` marks the `App` conforming type as that entry point.

#### The body Property

```swift
var body: some Scene {
    // Scene composition goes here
}
```

**Purpose:**
- Required property that returns one or more `Scene` instances
- Defines the structure of your app's user interface
- Can compose multiple scenes together

**Return Type:**
The return type `some Scene` is an opaque type that:
- Can return any concrete type conforming to `Scene`
- Allows the compiler to optimize based on the actual type
- Enables composition using scene builders

### Advanced App Features

#### App-Level State Management

```swift
@main
struct MyApp: App {
    @StateObject private var appSettings = AppSettings()
    @State private var selectedTab = 0
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appSettings)
        }
    }
}
```

**Use Cases:**
- Global configuration objects
- Shared data models
- User preferences
- Theme settings
- Network managers

**Why at App Level:**
- Persists across scene lifecycle events
- Single source of truth for the entire app
- Automatically injected into all scenes

#### App Storage

```swift
@main
struct MyApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainView()
            } else {
                OnboardingView()
            }
        }
    }
}
```

**Purpose:**
- Persist simple values across app launches
- Backed by UserDefaults
- Automatically updates UI when values change

#### Lifecycle Callbacks

```swift
@main
struct MyApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                print("App became active")
            case .inactive:
                print("App became inactive")
            case .background:
                print("App moved to background")
            @unknown default:
                break
            }
        }
    }
}
```

**Scene Phases:**
- `.active`: App is in the foreground and receiving events
- `.inactive`: App is in the foreground but not receiving events (e.g., during transitions)
- `.background`: App is in the background

### When to Use App-Level Logic

**Use App for:**
- Application entry point (required)
- Global state that persists across scenes
- App-wide configuration
- Dependency injection setup
- Core Data stack initialization
- Network service initialization

**Don't Use App for:**
- View-specific logic (use Views)
- Scene-specific state (use Scene)
- Window-specific behavior (use WindowGroup modifiers)

### Problem It Solves

**Before SwiftUI App:**
```swift
// UIKit approach - multiple files, delegates
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, 
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UIHostingController(rootView: ContentView())
        window?.makeKeyAndVisible()
        return true
    }
}
```

**With SwiftUI App:**
```swift
// Single declarative structure
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

**Advantages:**
- Declarative and type-safe
- Less boilerplate
- SwiftUI-native lifecycle management
- Easier to understand and maintain
- Better integration with SwiftUI features

---

## Scene Protocol

### Purpose

The `Scene` protocol represents a distinct part of your app's user interface hierarchy. It's an abstract container that can manage one or more windows and their lifecycle.

### Core Concept

A scene is **not** a window or a view. It's a blueprint that describes:
- What content should be displayed
- How windows should be created and managed
- Platform-specific behaviors

Think of a Scene as a "template" for creating and managing windows that display your content.

### Why Scenes Exist

**Problem They Solve:**

1. **Multi-Window Support**: On iPad and macOS, users can open multiple windows of the same app
2. **Platform Abstraction**: Scenes provide a unified API across iOS, iPadOS, and macOS
3. **State Preservation**: Each scene can maintain its own state independently
4. **Lifecycle Management**: Scenes handle their own lifecycle separate from the app

### Scene Protocol Requirements

```swift
protocol Scene {
    associatedtype Body: Scene
    var body: Self.Body { get }
}
```

Like `View`, it has:
- An associated type `Body`
- A computed property `body` that returns scene content

### Scene Composition

You can compose multiple scenes together:

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        
        Settings {
            SettingsView()
        }
        
        #if os(macOS)
        Window("About", id: "about") {
            AboutView()
        }
        #endif
    }
}
```

**How Composition Works:**
- Each scene operates independently
- Multiple scene types can coexist
- Scenes are created on-demand by the system
- Each maintains separate state and lifecycle

### Scene Modifiers

Scenes support modifiers that affect all windows in that scene:

```swift
WindowGroup {
    ContentView()
}
.commands {
    CommandMenu("Custom") {
        Button("Do Something") {
            // Action
        }
    }
}
.defaultSize(width: 800, height: 600)
```

**Common Modifiers:**
- `.commands`: Add menu bar commands (macOS)
- `.defaultSize`: Set default window size
- `.windowStyle`: Customize window appearance
- `.windowToolbarStyle`: Configure toolbar style
- `.handlesExternalEvents`: Handle URL schemes and activities

### Scene Storage

Scenes can maintain state using `@SceneStorage`:

```swift
struct ContentView: View {
    @SceneStorage("selectedTab") private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tabs...
        }
    }
}
```

**Purpose:**
- Persists state per scene instance
- Different windows maintain independent state
- Automatically restored when scene is recreated
- Lost when scene is permanently destroyed

**Differences from @AppStorage:**
- `@AppStorage`: Shared across all scenes and app launches
- `@SceneStorage`: Per-scene, persists across system state restoration

### Scene Lifecycle

**Scene Creation:**
1. User requests new window (macOS) or app launches (iOS)
2. System instantiates the appropriate scene
3. Scene's `body` is evaluated
4. Window(s) are created and displayed

**Scene Phases:**
```swift
struct MyScene: Scene {
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            // React to scene lifecycle changes
        }
    }
}
```

### When to Create Custom Scenes

**Rarely Needed:**
Most apps only use built-in scene types (WindowGroup, Settings, Window). Custom scenes are needed for:

- Specialized window management
- Custom multi-window behavior
- Advanced macOS app integration
- Document-based apps with unique requirements

**Example Custom Scene:**
```swift
struct CustomScene: Scene {
    var body: some Scene {
        WindowGroup {
            // Custom content
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            // Custom commands
        }
    }
}
```

### Relationship to App

```
App (Application Entry Point)
 └─> body: some Scene (Scene Composition)
      ├─> WindowGroup (Scene Type 1)
      ├─> Settings (Scene Type 2)
      └─> Window (Scene Type 3)
```

The `App` is the container, scenes are the content.

---

## WindowGroup

### Purpose

`WindowGroup` is the most common scene type. It manages a group of windows that display the same root view but maintain independent state.

### Core Functionality

**What It Does:**
1. Creates primary app windows
2. Handles multiple window instances (iPad/macOS)
3. Manages window state and restoration
4. Provides automatic window lifecycle management

### Basic Usage

```swift
WindowGroup {
    ContentView()
}
```

This simple declaration:
- Creates a primary window for your app
- On iOS: Single window (iPhone) or multiple windows (iPad)
- On macOS: Users can create multiple windows via File → New Window
- Each window shows `ContentView()` but maintains separate state

### Advanced WindowGroup Features

#### Identity-Based Windows

```swift
WindowGroup(id: "main") {
    MainView()
}

WindowGroup(id: "editor") {
    EditorView()
}
```

**Purpose:**
- Create multiple distinct window types
- Control which windows can be opened
- Reference windows programmatically

**Opening Specific Windows:**
```swift
@Environment(\.openWindow) private var openWindow

Button("Open Editor") {
    openWindow(id: "editor")
}
```

#### Data-Driven Windows

```swift
WindowGroup(for: Document.ID.self) { $documentID in
    if let documentID = documentID {
        DocumentView(documentID: documentID)
    }
}
```

**Use Cases:**
- Document-based apps
- Each window displays different data
- Multiple windows with different content
- State is tied to specific data

**Opening Data-Driven Windows:**
```swift
@Environment(\.openWindow) private var openWindow

Button("Open Document") {
    openWindow(value: document.id)
}
```

#### Window Configuration

```swift
WindowGroup {
    ContentView()
}
.defaultSize(width: 1000, height: 800)
.defaultPosition(.center)
.windowResizability(.contentSize)
.windowStyle(.automatic)
```

**Configuration Options:**

**Size Control:**
- `.defaultSize(width:height:)`: Initial window size
- `.windowResizability()`: How window can be resized
  - `.automatic`: System decides
  - `.contentSize`: Fixed to content
  - `.contentMinSize`: Can grow beyond content

**Position:**
- `.defaultPosition(.center)`: Center on screen
- `.defaultPosition(.topLeading)`: Specific position

**Style:**
- `.windowStyle(.automatic)`: Platform default
- `.windowStyle(.hiddenTitleBar)`: Hide title bar (macOS)
- `.windowStyle(.titleBar)`: Show title bar

**Toolbar:**
- `.windowToolbarStyle(.automatic)`: Platform default
- `.windowToolbarStyle(.unified)`: Unified toolbar (macOS)
- `.windowToolbarStyle(.expanded)`: Expanded toolbar

### Multi-Window Behavior

#### iOS (iPad)

```swift
WindowGroup {
    ContentView()
}
```

**Behavior:**
- Users can create multiple windows via App Switcher
- Each window is an independent scene
- State is preserved per window using `@SceneStorage`
- Windows can be in Split View or Slide Over

#### macOS

```swift
WindowGroup {
    ContentView()
}
.commands {
    CommandGroup(replacing: .newItem) {
        Button("New Window") {
            // Custom new window behavior
        }
        .keyboardShortcut("n", modifiers: .command)
    }
}
```

**Behavior:**
- File → New Window creates additional windows
- Each window is independent
- Cmd+N keyboard shortcut by default
- Can customize via `.commands`

### State Management in WindowGroup

#### Scene-Specific State

```swift
struct ContentView: View {
    @SceneStorage("selectedTab") private var selectedTab = 0
    @State private var searchText = ""
    
    var body: some View {
        TabView(selection: $selectedTab) {
            SearchView(searchText: $searchText)
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
                .tag(0)
            
            FavoritesView()
                .tabItem { Label("Favorites", systemImage: "star") }
                .tag(1)
        }
    }
}
```

**State Persistence:**
- `@SceneStorage("selectedTab")`: Persists per window, survives app relaunch
- `@State private var searchText`: Per window, lost on app termination

#### Shared State Across Windows

```swift
@main
struct MyApp: App {
    @StateObject private var dataModel = DataModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataModel)
        }
    }
}
```

**Result:**
- All windows share the same `dataModel` instance
- Changes in one window affect all windows
- Useful for synchronized data display

### WindowGroup vs Other Scene Types

**Use WindowGroup When:**
- Creating main app windows
- Need multiple windows with same content type
- Want automatic window management
- Building standard document-based apps

**Use Window Instead When:**
- Need auxiliary windows (About, Inspector, etc.)
- Want single-instance windows
- Need more control over window lifecycle

**Use Settings Instead When:**
- Creating preferences window (macOS)
- Platform-specific settings UI

### Common Patterns

#### Single Window App (iOS)

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

**Characteristics:**
- Single window on iPhone
- Multiple windows possible on iPad
- Standard iOS behavior

#### Multi-Window Document App

```swift
@main
struct DocumentApp: App {
    var body: some Scene {
        WindowGroup(for: Document.ID.self) { $documentID in
            DocumentEditor(documentID: documentID)
        }
    }
}

struct ContentView: View {
    @Environment(\.openWindow) private var openWindow
    let documents: [Document]
    
    var body: some View {
        List(documents) { document in
            Button(document.title) {
                openWindow(value: document.id)
            }
        }
    }
}
```

#### macOS App with Multiple Window Types

```swift
@main
struct MyMacApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .defaultSize(width: 1000, height: 800)
        
        Window("Inspector", id: "inspector") {
            InspectorView()
        }
        .defaultSize(width: 300, height: 600)
        .defaultPosition(.trailing)
        
        Settings {
            SettingsView()
        }
    }
}
```

### Problem WindowGroup Solves

**Traditional UIKit Approach:**
```swift
// Multiple files, manual window management
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, 
               willConnectTo session: UISceneSession, 
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIHostingController(rootView: ContentView())
        self.window = window
        window.makeKeyAndVisible()
    }
    
    // More delegate methods...
}
```

**SwiftUI WindowGroup:**
```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

**Benefits:**
- Declarative and concise
- Automatic multi-window support
- Built-in state restoration
- Cross-platform consistency
- Less boilerplate code

---

## Other Scene Types

### Window

**Purpose:** Create single-instance auxiliary windows with explicit control.

```swift
Window("About MyApp", id: "about") {
    AboutView()
}
.defaultSize(width: 400, height: 300)
.windowResizability(.contentSize)
```

**Characteristics:**
- Single instance per window ID
- Must be explicitly opened
- Good for utility windows
- Common on macOS

**Opening:**
```swift
@Environment(\.openWindow) private var openWindow

Button("Show About") {
    openWindow(id: "about")
}
```

**Use Cases:**
- About window
- Inspector panels
- Tool palettes
- Help windows
- Utility windows

**Differences from WindowGroup:**
| WindowGroup | Window |
|-------------|--------|
| Multiple instances possible | Single instance |
| File → New Window | Must open explicitly |
| Primary content | Auxiliary content |
| Auto-managed | Manual control |

### Settings

**Purpose:** Provide a standard settings/preferences window on macOS.

```swift
Settings {
    SettingsView()
}
```

**macOS Behavior:**
- Opens via AppName → Settings (Cmd+,)
- Single instance
- Standard Settings window style
- Automatic menu integration

**iOS Behavior:**
- Typically not used (use iOS Settings app integration instead)
- Can be used but not standard

**Typical Settings Structure:**
```swift
Settings {
    TabView {
        GeneralSettingsView()
            .tabItem {
                Label("General", systemImage: "gearshape")
            }
        
        AppearanceSettingsView()
            .tabItem {
                Label("Appearance", systemImage: "paintbrush")
            }
        
        AdvancedSettingsView()
            .tabItem {
                Label("Advanced", systemImage: "gearshape.2")
            }
    }
    .frame(width: 500)
}
```

### DocumentGroup

**Purpose:** Build document-based apps with automatic file management.

```swift
@main
struct MyDocumentApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: TextDocument()) { file in
            TextEditorView(document: file.$document)
        }
    }
}
```

**Features:**
- Automatic File → Open/Save/New Document
- File browser integration
- Multiple document instances
- Document state management
- Undo/redo support

**Document Protocol:**
```swift
struct TextDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }
    
    var text: String
    
    init(text: String = "") {
        self.text = text
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = string
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8)!
        return .init(regularFileWithContents: data)
    }
}
```

**Use Cases:**
- Text editors
- Image editors
- Data viewers
- Any app that opens/saves files

### MenuBarExtra

**Purpose:** Create menu bar extras (status bar items) on macOS.

```swift
@main
struct MyApp: App {
    var body: some Scene {
        MenuBarExtra("MyApp", systemImage: "star") {
            MenuBarView()
        }
    }
}
```

**Styles:**

**Menu Style:**
```swift
MenuBarExtra("MyApp", systemImage: "star") {
    Button("Action 1") { }
    Button("Action 2") { }
    Divider()
    Button("Quit") { NSApp.terminate(nil) }
}
.menuBarExtraStyle(.menu)
```

**Window Style:**
```swift
MenuBarExtra("MyApp", systemImage: "star") {
    ContentView()
}
.menuBarExtraStyle(.window)
```

**Use Cases:**
- Background apps
- System monitors
- Quick actions
- Always-available controls

---

## Relationships and Architecture

### Hierarchical Structure

```
Application
 └─> @main App (Entry Point)
      └─> body: some Scene (Scene Container)
           ├─> WindowGroup (Scene Type)
           │    └─> View Hierarchy
           │         └─> ContentView
           │              └─> Child Views
           │
           ├─> Window (Scene Type)
           │    └─> View Hierarchy
           │         └─> AboutView
           │
           └─> Settings (Scene Type)
                └─> View Hierarchy
                     └─> SettingsView
```

### Data Flow

```
App Level (@StateObject, @AppStorage)
    ↓ .environmentObject()
Scene Level (@SceneStorage, Scene State)
    ↓ parameters
View Level (@State, @Binding)
    ↓ parameters / bindings
Subviews
```

**Key Principles:**
1. Data flows down through the hierarchy
2. Changes flow up through bindings
3. Environment objects span entire scene
4. Scene storage is isolated per window

### Communication Patterns

#### App → Scene → View

```swift
@main
struct MyApp: App {
    @StateObject private var appData = AppData()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appData)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var appData: AppData
    
    var body: some View {
        Text(appData.value)
    }
}
```

#### View → App (Actions)

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("Custom Action") {
                    performAppAction()
                }
            }
        }
    }
    
    func performAppAction() {
        // App-level logic
    }
}
```

#### Cross-Scene Communication

```swift
@main
struct MyApp: App {
    @StateObject private var sharedData = SharedData()
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(sharedData)
        }
        
        Window("Inspector", id: "inspector") {
            InspectorView()
                .environmentObject(sharedData)
        }
    }
}
```

**Result:** Both windows access same data instance and stay synchronized.

### Lifecycle Coordination

```swift
@main
struct MyApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                appState.resumeOperations()
            case .background:
                appState.suspendOperations()
            default:
                break
            }
        }
    }
}
```

### Environment Propagation

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .environment(\.colorScheme, .dark)  // Affects all views in scene
    }
}
```

**Environment Values Available:**
- `.colorScheme`: Light/dark mode
- `.scenePhase`: Active/inactive/background
- `.openWindow`: Open new windows
- `.dismiss`: Dismiss current window
- Custom environment values

---

## Platform Differences

### iOS Specifics

#### iPhone
- Single window only (WindowGroup creates one window)
- No multi-window support
- Simplified scene management
- Focus on single-task workflow

#### iPad
- Multi-window support via WindowGroup
- App Switcher for managing windows
- Split View and Slide Over
- Drag and drop between windows

**iPad Multi-Window Example:**
```swift
@main
struct MyIPadApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .handlesExternalEvents(matching: Set(arrayLiteral: "*"))
    }
}
```

### macOS Specifics

#### Window Management
- Full multi-window support
- File → New Window
- Window menu automatically managed
- Cmd+N to create windows

#### Menu Bar Integration
```swift
@main
struct MyMacApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandMenu("Edit") {
                Button("Custom Action") { }
                    .keyboardShortcut("k", modifiers: .command)
            }
        }
    }
}
```

#### Settings Window
```swift
Settings {
    Form {
        // Settings controls
    }
    .frame(width: 500)
}
```

**Automatic Integration:**
- AppName → Settings menu item
- Cmd+, keyboard shortcut
- Standard settings window behavior

#### Window Styles
macOS supports additional window customization:
```swift
WindowGroup {
    ContentView()
}
.windowStyle(.hiddenTitleBar)
.windowToolbarStyle(.unified)
```

### Cross-Platform Strategies

#### Conditional Compilation
```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        
        #if os(macOS)
        Settings {
            SettingsView()
        }
        
        Window("About", id: "about") {
            AboutView()
        }
        #endif
    }
}
```

#### Platform-Specific Configuration
```swift
WindowGroup {
    ContentView()
}
#if os(macOS)
.defaultSize(width: 1000, height: 800)
.commands {
    CommandMenu("Tools") {
        // macOS-specific commands
    }
}
#else
.defaultSize(width: 390, height: 844)  // iPhone size
#endif
```

#### Shared Code with Platform Adaptations
```swift
struct ContentView: View {
    var body: some View {
        #if os(macOS)
        NavigationSplitView {
            Sidebar()
        } detail: {
            DetailView()
        }
        #else
        NavigationStack {
            Sidebar()
        }
        #endif
    }
}
```

---

## Best Practices and Guidelines

### App Structure

#### Keep App Simple
```swift
// ✅ Good: Simple app structure
@main
struct MyApp: App {
    @StateObject private var dataModel = DataModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataModel)
        }
    }
}

// ❌ Bad: Too much logic in App
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            if checkCondition() {
                if anotherCheck() {
                    ComplexView()
                } else {
                    OtherView()
                }
            }
        }
    }
    
    func checkCondition() -> Bool { /* complex logic */ }
    func anotherCheck() -> Bool { /* more logic */ }
}
```

**Principle:** App should declare structure, not implement business logic.

#### Initialize Dependencies at App Level
```swift
// ✅ Good: Single initialization
@main
struct MyApp: App {
    @StateObject private var dataStore = DataStore()
    @StateObject private var networkManager = NetworkManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataStore)
                .environmentObject(networkManager)
        }
    }
}

// ❌ Bad: Multiple initializations
struct ContentView: View {
    @StateObject private var dataStore = DataStore()  // Don't do this
    
    var body: some View {
        SubView()
            .environmentObject(dataStore)
    }
}
```

### Scene Organization

#### Use Appropriate Scene Types
```swift
// ✅ Good: Right scene for the job
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
        }
        
        Window("Inspector", id: "inspector") {
            InspectorView()
        }
        
        Settings {
            SettingsView()
        }
    }
}

// ❌ Bad: WindowGroup for everything
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
        }
        
        WindowGroup(id: "inspector") {  // Should be Window
            InspectorView()
        }
    }
}
```

#### Scene Identifiers
```swift
// ✅ Good: Consistent naming
private enum SceneID {
    static let main = "main"
    static let editor = "editor"
    static let inspector = "inspector"
}

WindowGroup(id: SceneID.main) {
    MainView()
}

// Usage
openWindow(id: SceneID.inspector)
```

### State Management

#### Use Correct State Mechanisms
```swift
// App-wide shared state
@main
struct MyApp: App {
    @StateObject private var appData = AppData()  // ✅ Shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appData)
        }
    }
}

// Per-window state
struct ContentView: View {
    @SceneStorage("selectedTab") private var selectedTab = 0  // ✅ Per window
    @State private var searchText = ""  // ✅ Per window, temporary
    
    var body: some View {
        // ...
    }
}
```

#### State Scope Guidelines

| State Type | Scope | Persistence | Use Case |
|------------|-------|-------------|----------|
| `@StateObject` in App | All scenes | Memory only | Shared app services |
| `@AppStorage` in App | All scenes | UserDefaults | Global preferences |
| `@SceneStorage` | Per scene | State restoration | Per-window UI state |
| `@StateObject` in View | View subtree | Memory only | View-specific models |
| `@State` | View subtree | Memory only | Temporary UI state |

### Window Configuration

#### Set Appropriate Defaults
```swift
// ✅ Good: Reasonable defaults
WindowGroup {
    ContentView()
}
.defaultSize(width: 1200, height: 800)  // Good default for content
.windowResizability(.contentSize)  // Allows user control

// ❌ Bad: Overly restrictive
WindowGroup {
    ContentView()
}
.defaultSize(width: 800, height: 600)
.windowResizability(.contentSize)  // Can't resize at all
```

#### Platform-Appropriate Sizing
```swift
WindowGroup {
    ContentView()
}
#if os(macOS)
.defaultSize(width: 1200, height: 800)
#elseif os(iOS)
.defaultSize(width: 390, height: 844)
#endif
```

### Error Handling

#### Handle Scene Errors Gracefully
```swift
WindowGroup(for: Document.ID.self) { $documentID in
    if let documentID = documentID {
        DocumentView(documentID: documentID)
    } else {
        ContentUnavailableView(
            "No Document Selected",
            systemImage: "doc.text",
            description: Text("Select a document to continue")
        )
    }
}
```

### Performance

#### Avoid Heavy Operations in Scene Body
```swift
// ❌ Bad: Heavy operations in scene body
WindowGroup {
    ContentView()
        .onAppear {
            processLargeDataset()  // Don't do this
        }
}

// ✅ Good: Initialize in App or dedicated view
@main
struct MyApp: App {
    @StateObject private var dataProcessor = DataProcessor()
    
    init() {
        // One-time initialization
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataProcessor)
        }
    }
}
```

---

## Common Patterns

### Document-Based Application

```swift
@main
struct MyDocApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: MyDocument()) { file in
            DocumentView(document: file.$document)
        }
        .commands {
            CommandMenu("Document") {
                Button("Export...") {
                    // Export logic
                }
            }
        }
    }
}

struct MyDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }
    
    var text: String
    
    init(text: String = "") {
        self.text = text
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = string
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: text.data(using: .utf8)!)
    }
}
```

### Multi-Window Utility App (macOS)

```swift
@main
struct UtilityApp: App {
    var body: some Scene {
        // Main window
        WindowGroup {
            MainView()
        }
        .defaultSize(width: 800, height: 600)
        
        // Inspector panel
        Window("Inspector", id: "inspector") {
            InspectorView()
        }
        .defaultSize(width: 300, height: 600)
        .defaultPosition(.trailing)
        .keyboardShortcut("i", modifiers: [.command, .option])
        
        // Settings
        Settings {
            SettingsView()
        }
    }
}

struct MainView: View {
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        VStack {
            Button("Show Inspector") {
                openWindow(id: "inspector")
            }
        }
        .toolbar {
            Button(action: { openWindow(id: "inspector") }) {
                Label("Inspector", systemImage: "sidebar.right")
            }
        }
    }
}
```

### Menu Bar App (macOS)

```swift
@main
struct MenuBarApp: App {
    @State private var isEnabled = false
    
    var body: some Scene {
        MenuBarExtra("MyApp", systemImage: "star.fill") {
            Toggle("Enabled", isOn: $isEnabled)
            
            Divider()
            
            Button("Show Main Window") {
                // Open main window if needed
            }
            
            Divider()
            
            Button("Quit") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
    }
}
```

### iPad Multi-Window App

```swift
@main
struct MyIPadApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .handlesExternalEvents(matching: Set(arrayLiteral: "*"))
    }
}

struct ContentView: View {
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        NavigationSplitView {
            List(items) { item in
                Button(item.title) {
                    openWindow(value: item.id)
                }
            }
        } detail: {
            Text("Select an item")
        }
    }
}
```

### Preferences with Multiple Tabs

```swift
Settings {
    TabView {
        GeneralSettings()
            .tabItem {
                Label("General", systemImage: "gearshape")
            }
        
        AppearanceSettings()
            .tabItem {
                Label("Appearance", systemImage: "paintbrush")
            }
        
        PrivacySettings()
            .tabItem {
                Label("Privacy", systemImage: "hand.raised")
            }
        
        AdvancedSettings()
            .tabItem {
                Label("Advanced", systemImage: "gearshape.2")
            }
    }
    .frame(width: 500)
}

struct GeneralSettings: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("defaultPath") private var defaultPath = ""
    
    var body: some View {
        Form {
            Toggle("Launch at Login", isOn: $launchAtLogin)
            TextField("Default Path", text: $defaultPath)
        }
        .padding()
    }
}
```

### Data-Driven Windows

```swift
@main
struct DataDrivenApp: App {
    @StateObject private var projectManager = ProjectManager()
    
    var body: some Scene {
        WindowGroup(for: Project.ID.self) { $projectID in
            if let projectID = projectID,
               let project = projectManager.project(for: projectID) {
                ProjectEditor(project: project)
            } else {
                ContentUnavailableView(
                    "No Project",
                    systemImage: "folder",
                    description: Text("Select or create a project")
                )
            }
        }
        .environmentObject(projectManager)
    }
}

struct ProjectListView: View {
    @EnvironmentObject private var projectManager: ProjectManager
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        List(projectManager.projects) { project in
            Button(project.name) {
                openWindow(value: project.id)
            }
        }
    }
}
```

### Shared State Across Windows

```swift
@main
struct SharedStateApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(appState)
        }
        
        Window("Monitoring", id: "monitor") {
            MonitorView()
                .environmentObject(appState)
        }
    }
}

class AppState: ObservableObject {
    @Published var status: String = "Idle"
    @Published var items: [Item] = []
    
    func performAction() {
        // Changes visible in all windows
        status = "Processing"
        items.append(Item())
    }
}
```

---

## Troubleshooting

### Common Issues

#### Windows Not Appearing

**Problem:**
```swift
WindowGroup(id: "editor") {
    EditorView()
}

Button("Open Editor") {
    openWindow(id: "editor")  // Nothing happens
}
```

**Solutions:**
1. Verify window ID matches exactly
2. Check if window is already open (macOS limits)
3. Ensure `openWindow` environment value is available
4. On iOS, check if device supports multiple windows

**Debugging:**
```swift
@Environment(\.openWindow) private var openWindow

Button("Open Editor") {
    print("Attempting to open window with id: editor")
    openWindow(id: "editor")
}
```

#### State Not Persisting

**Problem:**
```swift
struct ContentView: View {
    @State private var selectedTab = 0  // Lost between launches
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // ...
        }
    }
}
```

**Solution:**
Use `@SceneStorage` or `@AppStorage`:
```swift
struct ContentView: View {
    @SceneStorage("selectedTab") private var selectedTab = 0
    // or
    @AppStorage("selectedTab") private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // ...
        }
    }
}
```

#### Multiple Instances of Shared Object

**Problem:**
```swift
struct ContentView: View {
    @StateObject private var manager = Manager()  // ❌ Creates new instance
    
    var body: some View {
        // ...
    }
}
```

**Solution:**
Initialize in App and inject:
```swift
@main
struct MyApp: App {
    @StateObject private var manager = Manager()  // ✅ Single instance
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(manager)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var manager: Manager  // ✅ Shared instance
}
```

#### Window Size Not Applied

**Problem:**
```swift
WindowGroup {
    ContentView()
        .defaultSize(width: 800, height: 600)  // ❌ Wrong place
}
```

**Solution:**
Apply modifier to scene, not view:
```swift
WindowGroup {
    ContentView()
}
.defaultSize(width: 800, height: 600)  // ✅ Correct
```

#### Scene Commands Not Working

**Problem:**
```swift
struct ContentView: View {
    var body: some View {
        Text("Content")
            .commands {  // ❌ Commands on view
                CommandMenu("Custom") {
                    Button("Action") { }
                }
            }
    }
}
```

**Solution:**
Apply commands to scene:
```swift
WindowGroup {
    ContentView()
}
.commands {  // ✅ Commands on scene
    CommandMenu("Custom") {
        Button("Action") { }
    }
}
```

### Debugging Strategies

#### Print Scene Lifecycle

```swift
@main
struct MyApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            print("Scene phase changed from \(oldPhase) to \(newPhase)")
        }
    }
}
```

#### Track Window Opening

```swift
struct ContentView: View {
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        Button("Open Window") {
            print("Opening window...")
            openWindow(id: "target")
            print("Window opened")
        }
    }
}
```

#### Verify Environment Objects

```swift
struct ContentView: View {
    @EnvironmentObject private var manager: Manager
    
    var body: some View {
        Text("Manager available")
            .onAppear {
                print("Manager instance: \(ObjectIdentifier(manager))")
            }
    }
}
```

### Performance Issues

#### Scene Body Evaluated Too Often

**Problem:**
```swift
@main
struct MyApp: App {
    @State private var counter = 0
    
    var body: some Scene {
        print("Scene body evaluated: \(counter)")  // Prints frequently
        counter += 1
        
        return WindowGroup {
            ContentView()
        }
    }
}
```

**Solution:**
Minimize state changes in App:
```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

#### Heavy Initialization in Scene

**Problem:**
```swift
WindowGroup {
    ContentView()
        .onAppear {
            processLargeFile()  // Blocks UI
        }
}
```

**Solution:**
Use background initialization:
```swift
@main
struct MyApp: App {
    @StateObject private var dataProcessor = DataProcessor()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataProcessor)
        }
    }
}

class DataProcessor: ObservableObject {
    init() {
        Task {
            await loadData()
        }
    }
    
    func loadData() async {
        // Heavy processing
    }
}
```

---

## Summary

### Key Takeaways

**App Protocol:**
- Entry point for SwiftUI applications
- Manages app-wide state and configuration
- Declares the scene structure
- Handles application lifecycle

**Scene Protocol:**
- Represents distinct UI containers
- Abstract blueprint for window management
- Supports composition and configuration
- Platform-agnostic interface

**WindowGroup:**
- Most common scene type
- Manages multiple window instances
- Automatic window lifecycle
- Built-in state restoration

### Decision Matrix

**Choose App for:**
- Application entry point (required)
- Global state and services
- Dependency injection
- App-wide configuration

**Choose Scene (built-in types) for:**
- WindowGroup: Main content windows
- Window: Auxiliary/utility windows
- Settings: Preferences (macOS)
- DocumentGroup: Document-based apps
- MenuBarExtra: Menu bar apps (macOS)

**Choose State Mechanism:**
- `@StateObject` in App: Shared services
- `@AppStorage`: Global preferences
- `@SceneStorage`: Per-window UI state
- `@State`: Temporary view state

### Quick Reference

```swift
// Minimal app
@main
struct MinimalApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// Full-featured app
@main
struct FullApp: App {
    @StateObject private var appData = AppData()
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(appData)
        }
        .defaultSize(width: 1200, height: 800)
        .commands {
            CommandMenu("Custom") {
                Button("Action") { }
            }
        }
        
        #if os(macOS)
        Settings {
            SettingsView()
        }
        
        Window("About", id: "about") {
            AboutView()
        }
        #endif
    }
}
```

---

## Additional Resources

### Official Documentation
- [App Protocol - Apple Developer](https://developer.apple.com/documentation/swiftui/app)
- [Scene Protocol - Apple Developer](https://developer.apple.com/documentation/swiftui/scene)
- [WindowGroup - Apple Developer](https://developer.apple.com/documentation/swiftui/windowgroup)

### Related Topics
- SwiftUI App Lifecycle
- State and Data Flow
- Scene Management
- Window Management
- Multi-Window Support
- Document-Based Apps

### Best Practices
- SwiftUI Design Patterns
- Cross-Platform Development
- State Management Strategies
- Performance Optimization

---

*Document created for SwiftUI developers working on iOS and macOS applications.*