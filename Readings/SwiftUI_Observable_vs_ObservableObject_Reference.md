# SwiftUI Observable Systems: Complete Reference Guide

## Table of Contents
1. [Overview](#overview)
2. [ObservableObject - The Legacy System](#observableobject-the-legacy-system)
3. [Observable - The Modern System](#observable-the-modern-system)
4. [Direct Comparison](#direct-comparison)
5. [Migration Guide](#migration-guide)
6. [Advanced Topics](#advanced-topics)
7. [Common Pitfalls](#common-pitfalls)
8. [Performance Considerations](#performance-considerations)
9. [Best Practices](#best-practices)

---

## Overview

SwiftUI provides two distinct systems for making objects observable:

- **`ObservableObject`** (iOS 13+): The original protocol-based system using Combine
- **`@Observable`** (iOS 17+): The modern macro-based system using Swift's observation framework

### Quick Decision Guide

```swift
// Use @Observable (iOS 17+) for new projects
@Observable
class ModernViewModel {
    var title = "Hello"
}

// Use ObservableObject (iOS 13+) for:
// - Supporting older iOS versions
// - Existing codebases
// - Combine integration requirements
class LegacyViewModel: ObservableObject {
    @Published var title = "Hello"
}
```

---

## ObservableObject - The Legacy System

### Basic Implementation

```swift
import Combine

class UserProfileViewModel: ObservableObject {
    // Automatically publishes changes
    @Published var username: String = ""
    @Published var email: String = ""
    @Published var age: Int = 0
    
    // Manual publishing for computed properties
    var isValid: Bool {
        !username.isEmpty && !email.isEmpty
    }
    
    // Private properties don't trigger updates
    private var internalCache: [String: Any] = [:]
    
    // Manual notification
    func updateCache() {
        internalCache["key"] = "value"
        objectWillChange.send() // Manually notify observers
    }
}
```

### View Integration

```swift
struct ProfileView: View {
    // Three different property wrappers for three scenarios:
    
    // 1. @StateObject - View owns and creates the object
    @StateObject private var viewModel = UserProfileViewModel()
    
    // 2. @ObservedObject - Object passed from parent
    // @ObservedObject var viewModel: UserProfileViewModel
    
    // 3. @EnvironmentObject - Object injected via environment
    // @EnvironmentObject var viewModel: UserProfileViewModel
    
    var body: some View {
        Form {
            TextField("Username", text: $viewModel.username)
            TextField("Email", text: $viewModel.email)
            Stepper("Age: \(viewModel.age)", value: $viewModel.age)
            
            if viewModel.isValid {
                Text("Profile is valid")
            }
        }
    }
}

// Parent view setup
struct ParentView: View {
    @StateObject private var profile = UserProfileViewModel()
    
    var body: some View {
        NavigationStack {
            // Approach 1: Pass directly
            ProfileView(viewModel: profile)
            
            // Approach 2: Environment injection
            // ProfileView()
            //     .environmentObject(profile)
        }
    }
}
```

### Advanced ObservableObject Features

#### Custom Publishers

```swift
class AdvancedViewModel: ObservableObject {
    @Published var items: [String] = []
    
    // Custom publisher for debounced updates
    var debouncedItems: AnyPublisher<[String], Never> {
        $items
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    // Combine multiple publishers
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    
    var fullName: AnyPublisher<String, Never> {
        Publishers.CombineLatest($firstName, $lastName)
            .map { "\($0) \($1)" }
            .eraseToAnyPublisher()
    }
}

// Using custom publishers in a view
struct AdvancedView: View {
    @StateObject private var viewModel = AdvancedViewModel()
    @State private var debouncedValue: [String] = []
    
    var body: some View {
        VStack {
            TextField("Add item", text: .constant(""))
            Text("Items: \(debouncedValue.count)")
        }
        .onReceive(viewModel.debouncedItems) { items in
            debouncedValue = items
        }
    }
}
```

#### Manual Control Over Publishing

```swift
class ManualControlViewModel: ObservableObject {
    // Using custom objectWillChange publisher
    let objectWillChange = PassthroughSubject<Void, Never>()
    
    var data: [String] = [] {
        didSet {
            // Only publish on significant changes
            if data.count % 10 == 0 {
                objectWillChange.send()
            }
        }
    }
    
    // Batch updates without triggering multiple redraws
    func batchUpdate(_ newItems: [String]) {
        // Suspend automatic updates
        let willChange = objectWillChange
        
        data.append(contentsOf: newItems)
        
        // Single notification after all changes
        willChange.send()
    }
}
```

### ObservableObject Pros

✅ **Broad Compatibility**: Works on iOS 13+ (critical for apps supporting older devices)  
✅ **Combine Integration**: Deep integration with Combine framework for reactive programming  
✅ **Explicit Control**: `@Published` makes observable properties obvious  
✅ **Custom Publishers**: Can create sophisticated publisher chains  
✅ **Selective Publishing**: Choose exactly which properties publish changes  
✅ **Manual Notifications**: Call `objectWillChange.send()` for fine-grained control  
✅ **Well-Documented**: Years of Stack Overflow answers and tutorials  

### ObservableObject Cons

❌ **Verbose**: Requires `@Published` on every observable property  
❌ **Over-Invalidation**: Changes to ANY `@Published` property invalidate ALL observing views  
❌ **Memory Overhead**: Combine publishers for each `@Published` property  
❌ **Property Wrapper Confusion**: `@StateObject` vs `@ObservedObject` vs `@EnvironmentObject`  
❌ **No Computed Property Support**: Computed properties require manual `objectWillChange.send()`  
❌ **Binding Complexity**: Creating bindings to non-`@Published` properties is awkward  
❌ **willSet Timing**: Publishes *before* the change, not after  

### Common ObservableObject Use Cases

```swift
// 1. Network request coordinator
class NetworkCoordinator: ObservableObject {
    @Published var isLoading = false
    @Published var error: Error?
    @Published var data: Data?
    
    func fetchData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            data = try await URLSession.shared.data(from: URL(string: "...")!).0
        } catch {
            self.error = error
        }
    }
}

// 2. Form validation
class FormValidator: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    
    var isValid: Bool {
        email.contains("@") && 
        password.count >= 8 && 
        password == confirmPassword
    }
}

// 3. Settings/Preferences manager
class AppSettings: ObservableObject {
    @Published var isDarkMode = false
    @Published var fontSize: CGFloat = 14
    @Published var notificationsEnabled = true
    
    func save() {
        UserDefaults.standard.set(isDarkMode, forKey: "darkMode")
        UserDefaults.standard.set(fontSize, forKey: "fontSize")
        UserDefaults.standard.set(notificationsEnabled, forKey: "notifications")
    }
}
```

### Edge Cases and Gotchas

#### Problem: View Doesn't Update for Computed Properties

```swift
class BrokenViewModel: ObservableObject {
    @Published var firstName = ""
    @Published var lastName = ""
    
    // ❌ This won't trigger view updates!
    var fullName: String {
        "\(firstName) \(lastName)"
    }
}

// Solution 1: Make it @Published (but requires storage)
class FixedViewModel1: ObservableObject {
    @Published var firstName = "" {
        didSet { updateFullName() }
    }
    @Published var lastName = "" {
        didSet { updateFullName() }
    }
    @Published var fullName = ""
    
    private func updateFullName() {
        fullName = "\(firstName) \(lastName)"
    }
}

// Solution 2: Inline in the view
struct FixedView: View {
    @StateObject var viewModel = BrokenViewModel()
    
    var body: some View {
        // Computed inline, so it updates when firstName/lastName change
        Text("\(viewModel.firstName) \(viewModel.lastName)")
    }
}
```

#### Problem: @ObservedObject Doesn't Persist Across View Updates

```swift
struct ParentView: View {
    @State private var showChild = false
    
    var body: some View {
        VStack {
            Button("Toggle") { showChild.toggle() }
            
            if showChild {
                // ❌ Creates new instance every time!
                ChildView(viewModel: MyViewModel())
            }
        }
    }
}

struct ChildView: View {
    @ObservedObject var viewModel: MyViewModel // Loses state on recreation
    
    var body: some View {
        TextField("Input", text: $viewModel.text)
    }
}

// ✅ Solution: Use @StateObject in parent or child
struct FixedParentView: View {
    @StateObject private var viewModel = MyViewModel()
    @State private var showChild = false
    
    var body: some View {
        VStack {
            Button("Toggle") { showChild.toggle() }
            if showChild {
                ChildView(viewModel: viewModel) // Persists!
            }
        }
    }
}
```

#### Problem: Nested ObservableObjects

```swift
class OuterViewModel: ObservableObject {
    @Published var title = "Outer"
    let inner = InnerViewModel() // ❌ Changes to inner don't propagate!
}

class InnerViewModel: ObservableObject {
    @Published var subtitle = "Inner"
}

struct BrokenNestedView: View {
    @StateObject var outer = OuterViewModel()
    
    var body: some View {
        VStack {
            Text(outer.title) // Updates ✅
            Text(outer.inner.subtitle) // Doesn't update! ❌
        }
    }
}

// Solution: Manual forwarding
class FixedOuterViewModel: ObservableObject {
    @Published var title = "Outer"
    @Published var inner = InnerViewModel()
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Forward inner changes to outer
        inner.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}
```

---

## Observable - The Modern System

### Basic Implementation

```swift
import Observation

@Observable
class ModernUserProfile {
    // All stored properties are automatically observable!
    var username: String = ""
    var email: String = ""
    var age: Int = 0
    
    // Computed properties automatically track dependencies
    var isValid: Bool {
        !username.isEmpty && !email.isEmpty
    }
    
    // Exclude properties from observation
    @ObservationIgnored var internalCache: [String: Any] = [:]
    
    // Methods work normally
    func reset() {
        username = ""
        email = ""
        age = 0
    }
}
```

### View Integration

```swift
struct ModernProfileView: View {
    // Simple: just use plain properties or @State
    
    // Option 1: Plain property (passed from parent)
    let profile: ModernUserProfile
    
    // Option 2: @State (view owns it)
    // @State private var profile = ModernUserProfile()
    
    // Option 3: @Environment (injected)
    // @Environment(ModernUserProfile.self) var profile
    
    var body: some View {
        Form {
            // Bindings work automatically
            TextField("Username", text: $profile.username)
            TextField("Email", text: $profile.email)
            Stepper("Age: \(profile.age)", value: $profile.age)
            
            // Computed properties just work
            if profile.isValid {
                Text("Profile is valid")
            }
        }
    }
}

// Parent view setup
struct ModernParentView: View {
    @State private var profile = ModernUserProfile()
    
    var body: some View {
        NavigationStack {
            // Approach 1: Pass directly
            ModernProfileView(profile: profile)
            
            // Approach 2: Environment injection
            // ModernProfileView()
            //     .environment(profile)
        }
    }
}
```

### Advanced Observable Features

#### Granular Observation

```swift
@Observable
class GranularViewModel {
    var title: String = ""
    var count: Int = 0
    var items: [String] = []
}

struct GranularView: View {
    let viewModel: GranularViewModel
    
    var body: some View {
        VStack {
            // This view only observes 'title'
            TitleView(viewModel: viewModel)
            
            // This view only observes 'count'
            CountView(viewModel: viewModel)
        }
    }
}

struct TitleView: View {
    let viewModel: GranularViewModel
    
    var body: some View {
        // Only updates when 'title' changes!
        // Changes to 'count' or 'items' won't redraw this view
        Text(viewModel.title)
    }
}

struct CountView: View {
    let viewModel: GranularViewModel
    
    var body: some View {
        // Only updates when 'count' changes!
        Text("Count: \(viewModel.count)")
    }
}
```

#### Observation Isolation

```swift
@Observable
class IsolatedViewModel {
    var publicData: String = ""
    
    @ObservationIgnored 
    private var cache: [String: String] = [:]
    
    @ObservationIgnored
    private let queue = DispatchQueue(label: "background")
    
    // Heavy computation that shouldn't trigger observations
    @ObservationIgnored
    var expensiveResult: String = "" {
        didSet {
            // Even though this changes, views won't update
            print("Expensive computation complete")
        }
    }
    
    func performBackgroundWork() {
        queue.async {
            // Safe: cache isn't observed
            self.cache["key"] = "value"
            
            // This change IS observed and will update views
            self.publicData = "Updated"
        }
    }
}
```

#### Transient State

```swift
@Observable
class TransientStateViewModel {
    var data: [String] = []
    
    // Not persisted, not observed - perfect for UI state
    @ObservationIgnored var isLoading = false
    @ObservationIgnored var error: Error?
    
    func loadData() async {
        isLoading = true // Won't trigger view update
        defer { isLoading = false }
        
        // Simulate network call
        try? await Task.sleep(for: .seconds(1))
        
        // This WILL trigger view update
        data = ["Item 1", "Item 2", "Item 3"]
    }
}

// Companion view that observes loading state
struct TransientStateView: View {
    let viewModel: TransientStateViewModel
    @State private var isLoading = false
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
            }
            
            List(viewModel.data, id: \.self) { item in
                Text(item)
            }
        }
        .task {
            isLoading = true
            await viewModel.loadData()
            isLoading = false
        }
    }
}
```

#### Nested Observable Objects

```swift
@Observable
class Parent {
    var name: String = "Parent"
    var child: Child = Child() // Nested observable works automatically!
}

@Observable
class Child {
    var name: String = "Child"
}

struct NestedView: View {
    let parent: Parent
    
    var body: some View {
        VStack {
            Text(parent.name) // Updates when parent.name changes
            Text(parent.child.name) // Updates when parent.child.name changes!
        }
    }
}
```

### Observable Pros

✅ **Automatic Observation**: All properties are observable by default  
✅ **Granular Updates**: Views only update for properties they actually read  
✅ **Computed Property Support**: Computed properties automatically track dependencies  
✅ **Simple Syntax**: No property wrappers needed in most cases  
✅ **Better Performance**: Fine-grained observation reduces unnecessary redraws  
✅ **Nested Objects Work**: Nested `@Observable` objects propagate changes automatically  
✅ **Cleaner Code**: Less boilerplate, more readable  
✅ **Type Safety**: Compiler-enforced observation tracking  

### Observable Cons

❌ **iOS 17+ Only**: Cannot use in apps supporting iOS 16 or earlier  
❌ **Less Control**: Can't easily create custom publishers or reactive chains  
❌ **No Combine Integration**: Doesn't work with Combine publishers  
❌ **Newer System**: Fewer resources, tutorials, and Stack Overflow answers  
❌ **Migration Cost**: Existing codebases require refactoring  
❌ **Macro Complexity**: Understanding the generated code requires advanced knowledge  
❌ **Limited Customization**: Can't customize observation behavior like with Combine  

### Common Observable Use Cases

```swift
// 1. MVVM pattern
@Observable
class ArticleViewModel {
    var article: Article?
    var isLoading = false
    var errorMessage: String?
    
    func loadArticle(id: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            article = try await ArticleService.fetch(id: id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// 2. Shared app state
@Observable
class AppState {
    var currentUser: User?
    var isAuthenticated: Bool { currentUser != nil }
    var theme: Theme = .light
    var navigationPath: [Route] = []
    
    func login(user: User) {
        currentUser = user
    }
    
    func logout() {
        currentUser = nil
        navigationPath = []
    }
}

// 3. Real-time data model
@Observable
class ChatRoom {
    var messages: [Message] = []
    var participants: [User] = []
    var typingUsers: Set<String> = []
    
    var unreadCount: Int {
        messages.filter { !$0.isRead }.count
    }
    
    func addMessage(_ message: Message) {
        messages.append(message)
    }
}

// 4. Form state management
@Observable
class RegistrationForm {
    var email = ""
    var password = ""
    var confirmPassword = ""
    var agreedToTerms = false
    
    var isEmailValid: Bool {
        email.contains("@") && email.contains(".")
    }
    
    var passwordsMatch: Bool {
        !password.isEmpty && password == confirmPassword
    }
    
    var canSubmit: Bool {
        isEmailValid && passwordsMatch && agreedToTerms
    }
}
```

### Edge Cases and Advanced Patterns

#### Observation with SwiftData

```swift
import SwiftData
import Observation

@Observable
class DataController {
    let modelContainer: ModelContainer
    let modelContext: ModelContext
    
    var items: [Item] = []
    
    init() {
        let schema = Schema([Item.self])
        modelContainer = try! ModelContainer(for: schema)
        modelContext = ModelContext(modelContainer)
        loadItems()
    }
    
    func loadItems() {
        let descriptor = FetchDescriptor<Item>()
        items = (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func addItem(_ item: Item) {
        modelContext.insert(item)
        try? modelContext.save()
        loadItems()
    }
}
```

#### Observation with Actors

```swift
@Observable
class ActorBackedViewModel {
    private let dataActor: DataActor
    var data: [String] = []
    
    init() {
        dataActor = DataActor()
    }
    
    func loadData() async {
        data = await dataActor.fetchData()
    }
}

actor DataActor {
    private var cache: [String] = []
    
    func fetchData() async -> [String] {
        // Thread-safe operations
        if cache.isEmpty {
            cache = ["Item 1", "Item 2", "Item 3"]
        }
        return cache
    }
}
```

#### Conditional Observation

```swift
@Observable
class ConditionalViewModel {
    var isEnabled: Bool = true
    var value: String = ""
    
    // This computed property only triggers updates when isEnabled is true
    var displayValue: String {
        isEnabled ? value : "Disabled"
    }
}

struct ConditionalView: View {
    let viewModel: ConditionalViewModel
    
    var body: some View {
        VStack {
            Toggle("Enable", isOn: $viewModel.isEnabled)
            
            // Only observes the properties accessed based on isEnabled state
            Text(viewModel.displayValue)
        }
    }
}
```

---

## Direct Comparison

### Feature Matrix

| Feature | ObservableObject | @Observable |
|---------|-----------------|-------------|
| **iOS Version** | 13+ | 17+ |
| **Boilerplate** | High (`@Published` required) | Low (automatic) |
| **Observation Granularity** | Coarse (entire object) | Fine (per property) |
| **Computed Properties** | Manual | Automatic |
| **Nested Objects** | Manual forwarding | Automatic |
| **Combine Integration** | Native | None |
| **Property Wrappers in Views** | `@StateObject`, `@ObservedObject`, `@EnvironmentObject` | Plain properties, `@State`, `@Environment` |
| **Performance** | Good | Better (granular updates) |
| **Learning Curve** | Moderate | Easier |
| **Customization** | High (Combine publishers) | Limited |

### Side-by-Side Examples

#### Basic Counter

```swift
// ObservableObject approach
class CounterViewModel: ObservableObject {
    @Published var count: Int = 0
    @Published var lastUpdated: Date = Date()
    
    func increment() {
        count += 1
        lastUpdated = Date()
    }
}

struct CounterView: View {
    @StateObject private var viewModel = CounterViewModel()
    
    var body: some View {
        VStack {
            Text("Count: \(viewModel.count)")
            Text("Updated: \(viewModel.lastUpdated.formatted())")
            Button("Increment") {
                viewModel.increment()
            }
        }
    }
}

// @Observable approach
@Observable
class ModernCounterViewModel {
    var count: Int = 0
    var lastUpdated: Date = Date()
    
    func increment() {
        count += 1
        lastUpdated = Date()
    }
}

struct ModernCounterView: View {
    @State private var viewModel = ModernCounterViewModel()
    
    var body: some View {
        VStack {
            Text("Count: \(viewModel.count)")
            Text("Updated: \(viewModel.lastUpdated.formatted())")
            Button("Increment") {
                viewModel.increment()
            }
        }
    }
}
```

#### Shopping Cart

```swift
// ObservableObject approach
class ShoppingCart: ObservableObject {
    @Published var items: [Item] = []
    @Published var discount: Double = 0.0
    
    var total: Double {
        items.reduce(0) { $0 + $1.price } * (1 - discount)
    }
    
    func addItem(_ item: Item) {
        items.append(item)
        objectWillChange.send() // Needed to update 'total' computed property
    }
}

struct CartView: View {
    @StateObject private var cart = ShoppingCart()
    
    var body: some View {
        VStack {
            List(cart.items) { item in
                Text("\(item.name): $\(item.price)")
            }
            Text("Total: $\(cart.total)") // May not update without manual send()
        }
    }
}

// @Observable approach
@Observable
class ModernShoppingCart {
    var items: [Item] = []
    var discount: Double = 0.0
    
    var total: Double {
        items.reduce(0) { $0 + $1.price } * (1 - discount)
    }
    
    func addItem(_ item: Item) {
        items.append(item)
        // 'total' automatically updates in views!
    }
}

struct ModernCartView: View {
    @State private var cart = ModernShoppingCart()
    
    var body: some View {
        VStack {
            List(cart.items) { item in
                Text("\(item.name): $\(item.price)")
            }
            Text("Total: $\(cart.total)") // Automatically updates!
        }
    }
}
```

---

## Migration Guide

### Converting ObservableObject to @Observable

```swift
// BEFORE: ObservableObject
class UserSettings: ObservableObject {
    @Published var username: String = ""
    @Published var notificationsEnabled: Bool = true
    @Published var theme: Theme = .light
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Combine setup
        $username
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] newValue in
                self?.saveUsername(newValue)
            }
            .store(in: &cancellables)
    }
    
    private func saveUsername(_ username: String) {
        UserDefaults.standard.set(username, forKey: "username")
    }
}

// AFTER: @Observable
@Observable
class UserSettings {
    var username: String = "" {
        didSet {
            // Simple debouncing requires Task
            Task {
                try? await Task.sleep(for: .milliseconds(500))
                saveUsername(username)
            }
        }
    }
    var notificationsEnabled: Bool = true
    var theme: Theme = .light
    
    private func saveUsername(_ username: String) {
        UserDefaults.standard.set(username, forKey: "username")
    }
}

// Alternative: Keep Combine for complex reactive logic
@Observable
class UserSettingsHybrid {
    var username: String = ""
    var notificationsEnabled: Bool = true
    var theme: Theme = .light
    
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Use KVO or custom subject for observation
        // This is more complex but allows Combine integration
    }
}
```

### View Migration

```swift
// BEFORE: ObservableObject pattern
struct OldProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    // or @ObservedObject var viewModel: ProfileViewModel
    // or @EnvironmentObject var viewModel: ProfileViewModel
    
    var body: some View {
        TextField("Name", text: $viewModel.name)
    }
}

// AFTER: @Observable pattern
struct NewProfileView: View {
    @State private var viewModel = ProfileViewModel()
    // or let viewModel: ProfileViewModel
    // or @Environment(ProfileViewModel.self) var viewModel
    
    var body: some View {
        TextField("Name", text: $viewModel.name)
    }
}
```

### Migration Checklist

1. ✅ Update iOS deployment target to 17.0+
2. ✅ Replace `class MyClass: ObservableObject` with `@Observable class MyClass`
3. ✅ Remove `@Published` from all properties
4. ✅ Add `@ObservationIgnored` to properties that shouldn't trigger updates
5. ✅ Replace `@StateObject` with `@State` in views
6. ✅ Replace `@ObservedObject` with plain properties
7. ✅ Replace `.environmentObject()` with `.environment()`
8. ✅ Replace `@EnvironmentObject` with `@Environment`
9. ✅ Remove `objectWillChange.send()` calls (usually unnecessary)
10. ✅ Test computed properties (they should just work now)
11. ✅ Remove Combine subscriptions if they're only for property observation
12. ✅ Test nested observable objects (should work automatically)

---

## Advanced Topics

### When to Mix Both Systems

Sometimes you need both in the same app:

```swift
// Legacy module using ObservableObject
class LegacyAuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var user: User?
}

// Modern module using @Observable
@Observable
class ModernAppState {
    // Bridge: hold reference to legacy object
    @ObservationIgnored var legacyAuth: LegacyAuthManager
    
    // Mirror the state you need
    var isAuthenticated: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init(legacyAuth: LegacyAuthManager) {
        self.legacyAuth = legacyAuth
        
        // Forward changes from legacy to modern
        legacyAuth.$isAuthenticated
            .assign(to: \.isAuthenticated, on: self)
            .store(in: &cancellables)
    }
}

// View can use modern system
struct ModernView: View {
    @State private var appState: ModernAppState
    
    var body: some View {
        if appState.isAuthenticated {
            Text("Logged in")
        }
    }
}
```

### Custom Observable Tracking

```swift
@Observable
class CustomTrackingViewModel {
    var value: String = "" {
        willSet {
            print("About to change from \(value) to \(newValue)")
        }
        didSet {
            print("Changed from \(oldValue) to \(value)")
            
            // Custom side effects
            if value.count > 100 {
                value = String(value.prefix(100))
            }
        }
    }
}
```

### Observable with Property Wrappers

```swift
@Observable
class UserDefaultsBacked {
    @ObservationIgnored
    @UserDefaultsBacked(key: "username", defaultValue: "")
    var username: String
    
    // This property WILL trigger observations
    var displayName: String {
        username.isEmpty ? "Guest" : username
    }
}

@propertyWrapper
struct UserDefaultsBacked<T> {
    let key: String
    let defaultValue: T
    
    var wrappedValue: T {
        get {
            UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}
```

### Thread Safety

```swift
// ObservableObject approach
class ThreadSafeViewModel: ObservableObject {
    @Published var data: [String] = []
    private let queue = DispatchQueue(label: "thread-safe")
    
    func updateData(_ newData: [String]) {
        queue.async {
            DispatchQueue.main.async {
                self.data = newData // Must update on main thread
            }
        }
    }
}

// @Observable approach with MainActor
@Observable @MainActor
class MainActorViewModel {
    var data: [String] = []
    
    // Automatically on main thread
    func updateData(_ newData: [String]) {
        data = newData
    }
    
    // Background work still possible
    nonisolated func performHeavyComputation() -> [String] {
        // This runs on background thread
        return ["computed", "data"]
    }
}
```

---

## Common Pitfalls

### Pitfall 1: Using @State with ObservableObject

```swift
// ❌ WRONG
struct BadView: View {
    @State var viewModel = MyObservableObject() // Creates new instance on every render!
    
    var body: some View {
        Text(viewModel.title)
    }
}

// ✅ CORRECT
struct GoodView: View {
    @StateObject var viewModel = MyObservableObject() // Persists across renders
    
    var body: some View {
        Text(viewModel.title)
    }
}
```

### Pitfall 2: Using @State with @Observable reference types

```swift
@Observable
class MyModel {
    var title: String = ""
}

// ❌ WRONG - breaks observation
struct BadView: View {
    @State var model: MyModel
    
    var body: some View {
        Text(model.title) // Won't update!
    }
}

// ✅ CORRECT - for view-owned models
struct GoodView: View {
    @State var model = MyModel() // Works if view creates it
    
    var body: some View {
        Text(model.title) // Updates correctly
    }
}

// ✅ CORRECT - for passed models
struct GoodView2: View {
    let model: MyModel // Plain property works fine
    
    var body: some View {
        Text(model.title) // Updates correctly
    }
}
```

### Pitfall 3: Forgetting @MainActor

```swift
@Observable
class NetworkViewModel {
    var data: [String] = []
    
    func fetchData() async {
        let result = await performNetworkCall()
        
        // ❌ Might update on background thread!
        data = result
    }
}

// ✅ CORRECT
@Observable @MainActor
class SafeNetworkViewModel {
    var data: [String] = []
    
    func fetchData() async {
        let result = await performNetworkCall()
        data = result // Guaranteed on main thread
    }
}
```

### Pitfall 4: Over-observing in ObservableObject

```swift
class OverObservingViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var results: [String] = []
    @Published var isLoading: Bool = false
    @Published var sortOrder: SortOrder = .ascending
    
    // Every property change redraws ALL views observing this object!
}

// Better: Split into focused models
class SearchViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var results: [String] = []
}

class UIStateViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var sortOrder: SortOrder = .ascending
}
```

### Pitfall 5: Binding to computed properties

```swift
@Observable
class BindingViewModel {
    var celsius: Double = 0
    
    // ❌ Can't create binding to computed property!
    var fahrenheit: Double {
        celsius * 9/5 + 32
    }
}

struct BindingView: View {
    let viewModel: BindingViewModel
    
    var body: some View {
        // ❌ Error: Cannot create binding
        TextField("Fahrenheit", value: $viewModel.fahrenheit, format: .number)
    }
}

// ✅ Solution: Use stored property or custom binding
@Observable
class FixedBindingViewModel {
    var celsius: Double = 0
    
    var fahrenheit: Double {
        get { celsius * 9/5 + 32 }
        set { celsius = (newValue - 32) * 5/9 }
    }
}

// Or create custom binding in view:
struct FixedBindingView: View {
    let viewModel: BindingViewModel
    
    var body: some View {
        TextField("Fahrenheit", value: Binding(
            get: { viewModel.celsius * 9/5 + 32 },
            set: { viewModel.celsius = ($0 - 32) * 5/9 }
        ), format: .number)
    }
}
```

---

## Performance Considerations

### Observation Overhead

```swift
// ObservableObject: Entire view redraws on ANY change
class HeavyViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var largeDataset: [DataPoint] = []
    @Published var timestamp: Date = Date()
}

struct HeavyView: View {
    @StateObject var viewModel = HeavyViewModel()
    
    var body: some View {
        VStack {
            Text(viewModel.title) // Redraws even if only timestamp changed!
            ExpensiveChart(data: viewModel.largeDataset) // Redraws on ANY change!
        }
    }
}

// @Observable: Only affected views redraw
@Observable
class EfficientViewModel {
    var title: String = ""
    var largeDataset: [DataPoint] = []
    var timestamp: Date = Date()
}

struct EfficientView: View {
    let viewModel: EfficientViewModel
    
    var body: some View {
        VStack {
            Text(viewModel.title) // Only redraws when title changes
            ExpensiveChart(data: viewModel.largeDataset) // Only redraws when dataset changes
        }
    }
}
```

### Memory Impact

```swift
// ObservableObject: Each @Published creates a Combine publisher
class MemoryHeavy: ObservableObject {
    @Published var prop1: String = "" // 1 publisher
    @Published var prop2: String = "" // 1 publisher
    @Published var prop3: String = "" // 1 publisher
    // ... 50 more properties = 53 publishers + objectWillChange
}

// @Observable: Minimal overhead
@Observable
class MemoryLight {
    var prop1: String = "" // No publisher overhead
    var prop2: String = "" // No publisher overhead
    var prop3: String = "" // No publisher overhead
    // ... 50 more properties = minimal tracking overhead
}
```

### Best Practices for Performance

1. **Use `@Observable` for new code** - Better performance by default
2. **Split large models** - Avoid one massive observable object
3. **Use `@ObservationIgnored` for frequently changing, non-UI-relevant properties**
4. **Avoid observing in loops** - Extract observable reads outside of loops where possible
5. **Profile before optimizing** - Use Instruments to identify real bottlenecks

```swift
// Example: Optimized list rendering
@Observable
class ListViewModel {
    var items: [Item] = []
    
    @ObservationIgnored var isProcessing: Bool = false
    
    func processItems() {
        isProcessing = true // Doesn't trigger UI updates
        // Heavy processing...
        items = processedResults // Single update at end
    }
}

struct OptimizedListView: View {
    let viewModel: ListViewModel
    
    var body: some View {
        List(viewModel.items) { item in
            // Each row only observes the specific item
            ItemRow(item: item)
        }
    }
}

struct ItemRow: View {
    let item: Item // Not observable - no tracking overhead
    
    var body: some View {
        Text(item.name)
    }
}
```

---

## Best Practices

### When to Use ObservableObject

✅ Use ObservableObject when:
- Supporting iOS 16 or earlier
- Heavily invested in Combine reactive programming
- Need custom publishers and complex reactive chains
- Working with existing ObservableObject codebase
- Need fine control over when/how properties publish

### When to Use @Observable

✅ Use @Observable when:
- Building new apps for iOS 17+
- Want simpler, cleaner code
- Need better performance (granular observation)
- Working with computed properties
- Have nested observable objects
- Want automatic observation without boilerplate

### Hybrid Approach

For large codebases migrating to iOS 17+:

```swift
// Keep critical legacy code as ObservableObject
class LegacyNetworkManager: ObservableObject {
    @Published var isConnected: Bool = false
    // Complex Combine logic...
}

// Write new features with @Observable
@Observable
class NewFeatureViewModel {
    @ObservationIgnored var networkManager: LegacyNetworkManager
    var displayState: DisplayState = .loading
    
    init(networkManager: LegacyNetworkManager) {
        self.networkManager = networkManager
        // Bridge as needed
    }
}
```

### General Principles

1. **Prefer @Observable for new code** (if iOS 17+ is viable)
2. **Keep models focused** - Single responsibility principle
3. **Avoid massive view models** - Split into logical components
4. **Use computed properties** - They're efficient with @Observable
5. **Test observation** - Ensure views update correctly
6. **Profile performance** - Don't assume, measure
7. **Document decisions** - Note why you chose a particular approach

---

## Quick Reference

### Property Wrappers Cheat Sheet

| Wrapper | Used With | Purpose | Lifecycle |
|---------|-----------|---------|-----------|
| `@Published` | ObservableObject | Mark property as observable | N/A |
| `@StateObject` | ObservableObject | View owns and creates object | Survives view updates |
| `@ObservedObject` | ObservableObject | View receives object from parent | Doesn't own, can be recreated |
| `@EnvironmentObject` | ObservableObject | Access from environment | Injected by ancestor |
| `@State` | @Observable | View owns and creates object | Survives view updates |
| Plain property | @Observable | View receives object from parent | Not owned by view |
| `@Environment` | @Observable | Access from environment | Injected by ancestor |
| `@ObservationIgnored` | @Observable | Exclude from observation | N/A |

### Common Patterns

```swift
// Pattern 1: View owns model (ObservableObject)
struct ViewA: View {
    @StateObject private var model = MyModel()
    var body: some View { /*...*/ }
}

// Pattern 1: View owns model (@Observable)
struct ViewA: View {
    @State private var model = MyModel()
    var body: some View { /*...*/ }
}

// Pattern 2: Parent passes to child (ObservableObject)
struct Parent: View {
    @StateObject private var model = MyModel()
    var body: some View {
        Child(model: model)
    }
}
struct Child: View {
    @ObservedObject var model: MyModel
    var body: some View { /*...*/ }
}

// Pattern 2: Parent passes to child (@Observable)
struct Parent: View {
    @State private var model = MyModel()
    var body: some View {
        Child(model: model)
    }
}
struct Child: View {
    let model: MyModel
    var body: some View { /*...*/ }
}

// Pattern 3: Environment injection (ObservableObject)
struct Root: View {
    @StateObject private var model = MyModel()
    var body: some View {
        ContentView()
            .environmentObject(model)
    }
}
struct ContentView: View {
    @EnvironmentObject var model: MyModel
    var body: some View { /*...*/ }
}

// Pattern 3: Environment injection (@Observable)
struct Root: View {
    @State private var model = MyModel()
    var body: some View {
        ContentView()
            .environment(model)
    }
}
struct ContentView: View {
    @Environment(MyModel.self) var model
    var body: some View { /*...*/ }
}
```

---

## Conclusion

**For new projects targeting iOS 17+**: Use `@Observable`. It's simpler, more performant, and the future of SwiftUI state management.

**For existing projects or iOS 16 support**: Continue with `ObservableObject`, but plan migration when iOS 17 becomes your minimum target.

**For complex reactive logic**: Consider keeping `ObservableObject` with Combine, or use hybrid approaches.

The SwiftUI observation story has evolved significantly. Understanding both systems helps you make informed decisions and write better, more maintainable code.

---

## Additional Resources

### Apple Documentation
- [Observation Framework](https://developer.apple.com/documentation/observation)
- [Observable Macro](https://developer.apple.com/documentation/observation/observable())
- [ObservableObject Protocol](https://developer.apple.com/documentation/combine/observableobject)

### WWDC Sessions
- WWDC 2023: "Discover Observation in SwiftUI"
- WWDC 2019: "Data Flow Through SwiftUI"
- WWDC 2020: "Data Essentials in SwiftUI"

### Community Resources
- Swift Evolution: SE-0395 (Observation)
- SwiftUI Lab: Observation deep dives
- Hacking with Swift: ObservableObject and Observable guides

---

*Document Version: 1.0*  
*Last Updated: November 2025*  
*Minimum Deployment: iOS 13 (ObservableObject), iOS 17 (@Observable)*
