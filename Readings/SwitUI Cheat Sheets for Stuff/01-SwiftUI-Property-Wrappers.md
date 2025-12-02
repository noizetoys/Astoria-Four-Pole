# SwiftUI Property Wrappers Cheatsheet

## Overview

Property wrappers in SwiftUI are special attributes that manage state and data flow. They encapsulate common patterns for reading and writing values, automatically triggering view updates when data changes.

---

## Core Property Wrappers

### @State

**Purpose**: Manages simple value types owned by the view  
**Scope**: Private to the view  
**Use When**: View owns the data and it's a simple value type

```swift
struct CounterView: View {
    @State private var count = 0
    
    var body: some View {
        VStack {
            Text("Count: \(count)")
            Button("Increment") {
                count += 1  // Triggers view update
            }
        }
    }
}
```

**Key Points**:
- Always mark as `private` - state should be owned by the view
- For value types only (Int, String, Bool, structs, etc.)
- Stored in special heap memory, not on the view's stack
- SwiftUI manages lifecycle and persistence across view updates

### @Binding

**Purpose**: Creates a two-way connection to a value owned elsewhere  
**Scope**: References external data  
**Use When**: Child view needs to read and write parent's data

```swift
struct VolumeControl: View {
    @Binding var volume: Double
    
    var body: some View {
        Slider(value: $volume, in: 0...100)
    }
}

struct ParentView: View {
    @State private var volume: Double = 50
    
    var body: some View {
        VolumeControl(volume: $volume)  // Pass binding with $
    }
}
```

**Key Points**:
- Use `$` prefix to pass a binding
- Changes propagate to the original source
- No initial value in declaration
- Enables data flow down and back up the view hierarchy

**Creating Custom Bindings**:
```swift
struct CustomBindingExample: View {
    @State private var celsius: Double = 0
    
    var fahrenheitBinding: Binding<Double> {
        Binding(
            get: { celsius * 9/5 + 32 },
            set: { celsius = ($0 - 32) * 5/9 }
        )
    }
    
    var body: some View {
        VStack {
            TextField("Celsius", value: $celsius, format: .number)
            TextField("Fahrenheit", value: fahrenheitBinding, format: .number)
        }
    }
}
```

### @StateObject

**Purpose**: Creates and owns a reference type (ObservableObject)  
**Scope**: View owns the object's lifecycle  
**Use When**: View creates and owns an observable object

```swift
class ViewModel: ObservableObject {
    @Published var items: [String] = []
    
    func addItem(_ item: String) {
        items.append(item)
    }
}

struct ContentView: View {
    @StateObject private var viewModel = ViewModel()
    
    var body: some View {
        List(viewModel.items, id: \.self) { item in
            Text(item)
        }
    }
}
```

**Key Points**:
- Object persists across view updates
- View is responsible for creating the instance
- Object is created only once, even if view is recreated
- Use for the initial creation point of observable objects

### @ObservedObject

**Purpose**: Observes a reference type created elsewhere  
**Scope**: View watches but doesn't own  
**Use When**: Object is created by parent or passed in

```swift
struct DetailView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        Text("Items: \(viewModel.items.count)")
    }
}

struct ParentView: View {
    @StateObject private var viewModel = ViewModel()
    
    var body: some View {
        DetailView(viewModel: viewModel)  // Pass as regular parameter
    }
}
```

**Key Points**:
- Doesn't manage object lifecycle
- Object can be recreated if view is recreated
- Use when object is injected from outside
- Automatically subscribes to `@Published` changes

### @EnvironmentObject

**Purpose**: Shares observable objects deep in view hierarchy  
**Scope**: Available to view and all descendants  
**Use When**: Many views need access to shared data

```swift
class AppSettings: ObservableObject {
    @Published var isDarkMode = false
    @Published var fontSize: Double = 16
}

struct RootView: View {
    @StateObject private var settings = AppSettings()
    
    var body: some View {
        ContentView()
            .environmentObject(settings)
    }
}

struct ContentView: View {
    var body: some View {
        DeepNestedView()
    }
}

struct DeepNestedView: View {
    @EnvironmentObject var settings: AppSettings
    
    var body: some View {
        Toggle("Dark Mode", isOn: $settings.isDarkMode)
    }
}
```

**Key Points**:
- Injected with `.environmentObject()`
- Available to all child views
- App crashes if environment object not provided
- Great for app-wide settings or themes

### @Environment

**Purpose**: Reads system or custom environment values  
**Scope**: Available from environment  
**Use When**: Need system settings or custom environment values

**System Values**:
```swift
struct AdaptiveView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.sizeCategory) var sizeCategory
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    
    var body: some View {
        VStack {
            Text("Mode: \(colorScheme == .dark ? "Dark" : "Light")")
            
            Button("Close") {
                dismiss()
            }
            
            Button("Open Website") {
                openURL(URL(string: "https://apple.com")!)
            }
        }
    }
}
```

**Custom Environment Values**:
```swift
private struct CustomValueKey: EnvironmentKey {
    static let defaultValue: String = "Default"
}

extension EnvironmentValues {
    var customValue: String {
        get { self[CustomValueKey.self] }
        set { self[CustomValueKey.self] = newValue }
    }
}

struct ParentView: View {
    var body: some View {
        ChildView()
            .environment(\.customValue, "Custom!")
    }
}

struct ChildView: View {
    @Environment(\.customValue) var value
    
    var body: some View {
        Text(value)
    }
}
```

**Key Points**:
- Read-only by default
- Automatically propagates through view hierarchy
- Can be overridden at any level
- System values adapt to user preferences

### @Published (for ObservableObject)

**Purpose**: Marks properties that trigger view updates  
**Scope**: Inside ObservableObject classes  
**Use When**: Property changes should update observing views

```swift
class DataModel: ObservableObject {
    @Published var username = ""
    @Published var isLoading = false
    @Published var items: [Item] = []
    
    // Non-published properties don't trigger updates
    var cache: [String: Any] = [:]
}
```

**Key Points**:
- Only for `class` types conforming to `ObservableObject`
- Automatically sends `objectWillChange` notification
- Can use with custom `willSet`/`didSet` observers
- Publishers can be combined with Combine framework

---

## Modern Observable Macro (@Observable)

### @Observable (iOS 17+)

**Purpose**: Modern replacement for ObservableObject  
**Scope**: Automatic observation without property wrappers  
**Use When**: Targeting iOS 17+ for cleaner syntax

```swift
@Observable
class ModernViewModel {
    var name = ""
    var count = 0
    var items: [String] = []
    
    // No @Published needed!
}

struct ModernView: View {
    var viewModel = ModernViewModel()  // No @StateObject needed!
    
    var body: some View {
        VStack {
            Text(viewModel.name)
            TextField("Name", text: $viewModel.name)  // $ still works!
            Text("Count: \(viewModel.count)")
        }
    }
}
```

**Key Points**:
- No `@Published` required
- No `@StateObject` or `@ObservedObject` required
- Automatically tracks which properties are accessed
- Only updates views that actually use changed properties
- More efficient than ObservableObject
- Can use `@Bindable` for bindings to properties

**Using @Bindable**:
```swift
@Observable
class Settings {
    var userName = ""
    var volume: Double = 50
}

struct SettingsView: View {
    @Bindable var settings: Settings
    
    var body: some View {
        Form {
            TextField("Name", text: $settings.userName)
            Slider(value: $settings.volume, in: 0...100)
        }
    }
}
```

---

## Specialized Property Wrappers

### @AppStorage

**Purpose**: Persists simple values to UserDefaults  
**Use When**: Need persistent user preferences

```swift
struct SettingsView: View {
    @AppStorage("username") private var username = ""
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("fontSize") private var fontSize: Double = 16
    
    var body: some View {
        Form {
            TextField("Username", text: $username)
            Toggle("Dark Mode", isOn: $isDarkMode)
            Slider(value: $fontSize, in: 10...30)
        }
    }
}
```

**Key Points**:
- Automatically syncs with UserDefaults
- Works with basic types (String, Int, Double, Bool, Data, URL)
- Can specify custom UserDefaults suite
- Updates all views using the same key

### @SceneStorage

**Purpose**: Preserves state across app launches per scene  
**Use When**: Need state restoration for multi-window apps

```swift
struct DocumentView: View {
    @SceneStorage("selectedTab") private var selectedTab = 0
    @SceneStorage("scrollPosition") private var scrollPosition: Double = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Text("Tab 1").tag(0)
            Text("Tab 2").tag(1)
        }
    }
}
```

**Key Points**:
- Unique per scene (window) on iPad/Mac
- Survives app termination
- Limited to simple types
- Resets when scene is destroyed

### @FocusState

**Purpose**: Manages keyboard focus state  
**Use When**: Need to control which field has focus

```swift
struct LoginForm: View {
    @FocusState private var focusedField: Field?
    @State private var username = ""
    @State private var password = ""
    
    enum Field: Hashable {
        case username
        case password
    }
    
    var body: some View {
        VStack {
            TextField("Username", text: $username)
                .focused($focusedField, equals: .username)
                .onSubmit {
                    focusedField = .password
                }
            
            SecureField("Password", text: $password)
                .focused($focusedField, equals: .password)
                .onSubmit {
                    submitForm()
                }
        }
        .onAppear {
            focusedField = .username
        }
    }
    
    func submitForm() {
        focusedField = nil  // Dismiss keyboard
    }
}
```

**Key Points**:
- Can use Bool or Hashable enum
- Programmatically control focus
- Detect which field is focused
- Works with TextField, TextEditor, etc.

### @GestureState

**Purpose**: Tracks gesture state with automatic reset  
**Use When**: Creating custom gestures

```swift
struct DraggableView: View {
    @GestureState private var dragOffset: CGSize = .zero
    @State private var position: CGSize = .zero
    
    var body: some View {
        Circle()
            .fill(.blue)
            .frame(width: 100, height: 100)
            .offset(x: position.width + dragOffset.width,
                    y: position.height + dragOffset.height)
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation
                    }
                    .onEnded { value in
                        position.width += value.translation.width
                        position.height += value.translation.height
                    }
            )
    }
}
```

**Key Points**:
- Automatically resets to initial value when gesture ends
- Use with `.updating()` modifier
- Perfect for temporary gesture state
- Separate from persistent state

### @Namespace

**Purpose**: Creates unique namespace for matched geometry effects  
**Use When**: Creating hero animations between views

```swift
struct AnimationView: View {
    @Namespace private var animation
    @State private var isExpanded = false
    
    var body: some View {
        VStack {
            if !isExpanded {
                Circle()
                    .fill(.blue)
                    .frame(width: 50, height: 50)
                    .matchedGeometryEffect(id: "circle", in: animation)
            } else {
                Circle()
                    .fill(.blue)
                    .frame(width: 200, height: 200)
                    .matchedGeometryEffect(id: "circle", in: animation)
            }
        }
        .onTapGesture {
            withAnimation {
                isExpanded.toggle()
            }
        }
    }
}
```

**Key Points**:
- Creates identity for matched geometry effects
- Enables smooth transitions between views
- ID must match for both views
- Works across different view hierarchies

---

## Common Patterns

### State Hoisting

Moving state to a common ancestor:

```swift
struct ParentView: View {
    @State private var sharedValue = 0
    
    var body: some View {
        VStack {
            ChildA(value: $sharedValue)
            ChildB(value: $sharedValue)
        }
    }
}

struct ChildA: View {
    @Binding var value: Int
    var body: some View {
        Button("Increment") { value += 1 }
    }
}

struct ChildB: View {
    @Binding var value: Int
    var body: some View {
        Text("Value: \(value)")
    }
}
```

### Observable Object Pattern

```swift
@Observable
class AppState {
    var user: User?
    var isAuthenticated: Bool { user != nil }
    
    func login(username: String, password: String) {
        // Login logic
    }
    
    func logout() {
        user = nil
    }
}

struct RootView: View {
    @State private var appState = AppState()
    
    var body: some View {
        Group {
            if appState.isAuthenticated {
                MainView()
            } else {
                LoginView()
            }
        }
        .environment(appState)  // For @Environment access
    }
}
```

### Computed Bindings

```swift
struct FilteredListView: View {
    @State private var items = ["Apple", "Banana", "Cherry"]
    @State private var searchText = ""
    
    var filteredItemsBinding: Binding<[String]> {
        Binding(
            get: {
                searchText.isEmpty ? items : items.filter { $0.contains(searchText) }
            },
            set: { items = $0 }
        )
    }
    
    var body: some View {
        VStack {
            TextField("Search", text: $searchText)
            List(filteredItemsBinding.wrappedValue, id: \.self) { item in
                Text(item)
            }
        }
    }
}
```

---

## Quick Reference Table

| Wrapper | Purpose | Ownership | Persistence | Type |
|---------|---------|-----------|-------------|------|
| `@State` | Local view state | View owns | View lifetime | Value type |
| `@Binding` | Two-way connection | References external | N/A | Any |
| `@StateObject` | Observable object | View owns | View lifetime | ObservableObject |
| `@ObservedObject` | Observable object | External | External | ObservableObject |
| `@EnvironmentObject` | Shared observable | Injected | External | ObservableObject |
| `@Environment` | System/custom values | System/parent | External | Any |
| `@AppStorage` | UserDefaults sync | Shared | Permanent | Simple types |
| `@SceneStorage` | Scene restoration | Per scene | Per session | Simple types |
| `@FocusState` | Focus management | View owns | View lifetime | Bool/Hashable |
| `@GestureState` | Gesture tracking | View owns | Gesture lifetime | Any |
| `@Namespace` | Matched geometry | View owns | View lifetime | Namespace.ID |
| `@Observable` | Modern observation | View/external | Depends | Class |

---

## Best Practices

1. **Use @State for simple, private view state**
   - Always mark as `private`
   - Only for data the view owns

2. **Use @StateObject when creating observable objects**
   - Only at the creation point
   - Ensures object survives view updates

3. **Use @ObservedObject when receiving observable objects**
   - For objects created elsewhere
   - Don't create instances here

4. **Use @Binding for child views that need to modify parent state**
   - Enables two-way data flow
   - Keep child views reusable

5. **Use @EnvironmentObject for app-wide shared state**
   - Avoids prop drilling
   - Remember to inject with `.environmentObject()`

6. **Prefer @Observable for iOS 17+**
   - Cleaner syntax
   - Better performance
   - Automatic property tracking

7. **Use @AppStorage for user preferences**
   - Perfect for settings
   - Automatically persists

8. **Keep state as local as possible**
   - Only hoist when necessary
   - Reduces coupling between views

---

## Troubleshooting

**Issue**: View not updating when property changes  
**Solution**: Ensure property is wrapped with `@State`, `@Published`, or in `@Observable` class

**Issue**: "Missing environment object"  
**Solution**: Add `.environmentObject()` modifier to ancestor view

**Issue**: Object gets recreated unexpectedly  
**Solution**: Use `@StateObject` instead of `@ObservedObject` at creation point

**Issue**: Binding not working  
**Solution**: Use `$` prefix when passing bindings, ensure source is `@State` or `@Binding`

**Issue**: @AppStorage not syncing between views  
**Solution**: Ensure all views use same key string

---

## Additional Resources

- [SwiftUI Data Flow (WWDC)](https://developer.apple.com/videos/play/wwdc2020/10040/)
- [Observable Macro (iOS 17+)](https://developer.apple.com/documentation/observation)
- [Property Wrappers Documentation](https://docs.swift.org/swift-book/LanguageGuide/Properties.html)
