# SwiftUI Environment Objects & Properties Cheatsheet

## Overview

The SwiftUI environment system provides a way to pass data through the view hierarchy without explicit parameters. This includes both system-provided environment values and custom environment objects/values.

---

## Environment Objects (@EnvironmentObject)

### Basic Environment Object

```swift
// 1. Define observable object
@Observable
class UserSettings {
    var username = ""
    var isDarkMode = false
    var fontSize: Double = 16
}

// 2. Inject at root
struct MyApp: App {
    @State private var settings = UserSettings()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(settings)  // For @Observable
        }
    }
}

// 3. Access in any descendant
struct ContentView: View {
    @Environment(UserSettings.self) var settings
    
    var body: some View {
        Text("Hello, \(settings.username)")
        DetailView()
    }
}

struct DetailView: View {
    @Environment(UserSettings.self) var settings
    
    var body: some View {
        Toggle("Dark Mode", isOn: $settings.isDarkMode)
    }
}
```

### Legacy ObservableObject Pattern (iOS 13+)

```swift
// Using ObservableObject (older pattern)
class AppSettings: ObservableObject {
    @Published var username = ""
    @Published var isDarkMode = false
}

struct RootView: View {
    @StateObject private var settings = AppSettings()
    
    var body: some View {
        ContentView()
            .environmentObject(settings)
    }
}

struct ContentView: View {
    @EnvironmentObject var settings: AppSettings
    
    var body: some View {
        Text(settings.username)
    }
}
```

### Multiple Environment Objects

```swift
@Observable
class UserData {
    var user: User?
}

@Observable
class AppState {
    var isLoading = false
}

struct RootView: View {
    @State private var userData = UserData()
    @State private var appState = AppState()
    
    var body: some View {
        ContentView()
            .environment(userData)
            .environment(appState)
    }
}

struct ContentView: View {
    @Environment(UserData.self) var userData
    @Environment(AppState.self) var appState
    
    var body: some View {
        if let user = userData.user {
            Text("Hello, \(user.name)")
        }
    }
}
```

---

## System Environment Values

### Color Scheme

```swift
struct ColorSchemeExample: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Text("Mode: \(colorScheme == .dark ? "Dark" : "Light")")
            .foregroundColor(colorScheme == .dark ? .white : .black)
    }
}

// Force specific color scheme
struct ForcedColorScheme: View {
    var body: some View {
        ContentView()
            .preferredColorScheme(.dark)
    }
}

// Override locally
struct LocalOverride: View {
    var body: some View {
        VStack {
            Text("Default")
            Text("Always dark")
                .environment(\.colorScheme, .dark)
        }
    }
}
```

### Dynamic Type Size

```swift
struct DynamicTypeExample: View {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    var body: some View {
        VStack {
            Text("Current size: \(String(describing: dynamicTypeSize))")
            
            if dynamicTypeSize >= .accessibility1 {
                Text("Large accessibility text")
            } else {
                Text("Regular text")
            }
        }
    }
}

// Limit dynamic type range
struct LimitedDynamicType: View {
    var body: some View {
        Text("Limited range")
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}
```

### Layout Direction

```swift
struct LayoutDirectionExample: View {
    @Environment(\.layoutDirection) var layoutDirection
    
    var body: some View {
        HStack {
            if layoutDirection == .rightToLeft {
                Text("RTL Layout")
            } else {
                Text("LTR Layout")
            }
        }
    }
}

// Force RTL (for testing)
struct ForcedRTL: View {
    var body: some View {
        ContentView()
            .environment(\.layoutDirection, .rightToLeft)
    }
}
```

### Size Category

```swift
struct SizeCategoryExample: View {
    @Environment(\.sizeCategory) var sizeCategory
    
    var body: some View {
        Text("Font size adapts")
            .font(sizeCategory.isAccessibilityCategory ? .title : .body)
    }
}

extension ContentSizeCategory {
    var isAccessibilityCategory: Bool {
        switch self {
        case .accessibilityMedium,
             .accessibilityLarge,
             .accessibilityExtraLarge,
             .accessibilityExtraExtraLarge,
             .accessibilityExtraExtraExtraLarge:
            return true
        default:
            return false
        }
    }
}
```

### Dismiss Action

```swift
struct DismissExample: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            Text("Modal View")
            
            Button("Close") {
                dismiss()  // Dismisses sheet/fullScreenCover/modal
            }
        }
    }
}

// Usage
struct ParentView: View {
    @State private var showModal = false
    
    var body: some View {
        Button("Show Modal") {
            showModal = true
        }
        .sheet(isPresented: $showModal) {
            DismissExample()
        }
    }
}
```

### Open URL

```swift
struct OpenURLExample: View {
    @Environment(\.openURL) var openURL
    
    var body: some View {
        Button("Open Website") {
            if let url = URL(string: "https://www.apple.com") {
                openURL(url)
            }
        }
    }
}

// With completion handler
struct OpenURLWithCompletion: View {
    @Environment(\.openURL) var openURL
    
    var body: some View {
        Button("Open with Callback") {
            openURL(URL(string: "https://www.apple.com")!) { accepted in
                print("URL opened: \(accepted)")
            }
        }
    }
}
```

### Refresh Action

```swift
struct RefreshableList: View {
    @State private var items: [String] = []
    
    var body: some View {
        List(items, id: \.self) { item in
            Text(item)
        }
        .refreshable {
            await loadData()
        }
    }
    
    func loadData() async {
        // Simulate network call
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        items = ["New Item 1", "New Item 2"]
    }
}

// Manual access
struct ManualRefresh: View {
    @Environment(\.refresh) var refresh
    
    var body: some View {
        Button("Refresh") {
            Task {
                await refresh?()
            }
        }
    }
}
```

### Is Enabled

```swift
struct EnabledExample: View {
    @Environment(\.isEnabled) var isEnabled
    
    var body: some View {
        Text("Enabled: \(isEnabled ? "Yes" : "No")")
            .foregroundColor(isEnabled ? .primary : .secondary)
    }
}

// Disabling propagates
struct DisabledParent: View {
    var body: some View {
        VStack {
            EnabledExample()  // isEnabled = true
        }
        .disabled(true)  // Now isEnabled = false for all children
    }
}
```

### Redaction Reasons

```swift
struct RedactionExample: View {
    @Environment(\.redactionReasons) var redactionReasons
    
    var body: some View {
        VStack {
            if redactionReasons.contains(.placeholder) {
                Text("Loading...")
            } else {
                Text("Actual content")
            }
        }
    }
}

// Apply redaction
struct RedactedView: View {
    var body: some View {
        ContentView()
            .redacted(reason: .placeholder)
    }
}
```

### Scene Phase

```swift
struct ScenePhaseExample: View {
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        Text("Scene phase")
            .onChange(of: scenePhase) { oldPhase, newPhase in
                switch newPhase {
                case .active:
                    print("App became active")
                case .inactive:
                    print("App became inactive")
                case .background:
                    print("App went to background")
                @unknown default:
                    break
                }
            }
    }
}
```

---

## Custom Environment Values

### Defining Custom Environment Values

```swift
// 1. Define the key
private struct CustomThemeKey: EnvironmentKey {
    static let defaultValue: String = "Default Theme"
}

// 2. Extend EnvironmentValues
extension EnvironmentValues {
    var customTheme: String {
        get { self[CustomThemeKey.self] }
        set { self[CustomThemeKey.self] = newValue }
    }
}

// 3. Optional: Create view extension for convenience
extension View {
    func customTheme(_ theme: String) -> some View {
        environment(\.customTheme, theme)
    }
}

// Usage
struct ParentView: View {
    var body: some View {
        ContentView()
            .customTheme("Dark Theme")
    }
}

struct ContentView: View {
    @Environment(\.customTheme) var theme
    
    var body: some View {
        Text("Current theme: \(theme)")
    }
}
```

### Complex Custom Environment Value

```swift
// Define complex type
struct AppTheme {
    var primaryColor: Color
    var secondaryColor: Color
    var fontSize: CGFloat
    
    static let light = AppTheme(
        primaryColor: .blue,
        secondaryColor: .gray,
        fontSize: 16
    )
    
    static let dark = AppTheme(
        primaryColor: .purple,
        secondaryColor: .white,
        fontSize: 18
    )
}

// Environment key
private struct ThemeKey: EnvironmentKey {
    static let defaultValue = AppTheme.light
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// Usage
struct ThemedView: View {
    @Environment(\.appTheme) var theme
    
    var body: some View {
        Text("Themed Text")
            .foregroundColor(theme.primaryColor)
            .font(.system(size: theme.fontSize))
    }
}

struct RootView: View {
    @State private var useDarkTheme = false
    
    var body: some View {
        ThemedView()
            .environment(\.appTheme, useDarkTheme ? .dark : .light)
    }
}
```

### Optional Environment Value

```swift
private struct OptionalValueKey: EnvironmentKey {
    static let defaultValue: String? = nil
}

extension EnvironmentValues {
    var optionalValue: String? {
        get { self[OptionalValueKey.self] }
        set { self[OptionalValueKey.self] = newValue }
    }
}

struct OptionalExample: View {
    @Environment(\.optionalValue) var value
    
    var body: some View {
        if let value = value {
            Text("Value: \(value)")
        } else {
            Text("No value set")
        }
    }
}
```

---

## Common System Environment Values

### Complete Reference

```swift
struct EnvironmentValuesShowcase: View {
    // Appearance
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.colorSchemeContrast) var colorSchemeContrast
    
    // Typography
    @Environment(\.font) var font
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @Environment(\.sizeCategory) var sizeCategory
    @Environment(\.legibilityWeight) var legibilityWeight
    
    // Layout
    @Environment(\.layoutDirection) var layoutDirection
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    // Actions
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    @Environment(\.refresh) var refresh
    
    // State
    @Environment(\.isEnabled) var isEnabled
    @Environment(\.isFocused) var isFocused
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.redactionReasons) var redactionReasons
    
    // Localization
    @Environment(\.locale) var locale
    @Environment(\.timeZone) var timeZone
    @Environment(\.calendar) var calendar
    
    // Accessibility
    @Environment(\.accessibilityEnabled) var accessibilityEnabled
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    @Environment(\.accessibilityDifferentiateWithoutColor) var differentiateWithoutColor
    @Environment(\.accessibilityInvertColors) var invertColors
    
    var body: some View {
        Text("Environment values available")
    }
}
```

### Accessibility Environment Values

```swift
struct AccessibilityAdaptive: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    @Environment(\.accessibilityDifferentiateWithoutColor) var differentiateWithoutColor
    
    var body: some View {
        VStack {
            if reduceMotion {
                // No animations
                Text("Static content")
            } else {
                // With animations
                Text("Animated content")
                    .animation(.default, value: UUID())
            }
            
            Rectangle()
                .fill(differentiateWithoutColor ? .blue : .clear)
                .overlay(
                    Text("Important")
                        .foregroundColor(differentiateWithoutColor ? .white : .blue)
                )
        }
        .background(reduceTransparency ? .white : .ultraThinMaterial)
    }
}
```

### Display Scale

```swift
struct DisplayScaleExample: View {
    @Environment(\.displayScale) var displayScale
    
    var body: some View {
        Text("Display scale: \(displayScale)x")
        // Use for pixel-perfect layouts
    }
}
```

### Presentation Mode (Legacy)

```swift
// Note: Use @Environment(\.dismiss) on iOS 15+
struct LegacyDismiss: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        Button("Close") {
            presentationMode.wrappedValue.dismiss()
        }
    }
}
```

---

## Practical Patterns

### 1. App-Wide Theme System

```swift
@Observable
class ThemeManager {
    var currentTheme: Theme = .system
    
    enum Theme {
        case light, dark, system
    }
    
    var colorScheme: ColorScheme? {
        switch currentTheme {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

struct ThemeManagerKey: EnvironmentKey {
    static let defaultValue = ThemeManager()
}

extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeManagerKey.self] }
        set { self[ThemeManagerKey.self] = newValue }
    }
}

struct RootView: View {
    @State private var themeManager = ThemeManager()
    
    var body: some View {
        ContentView()
            .environment(themeManager)
            .preferredColorScheme(themeManager.colorScheme)
    }
}

struct SettingsView: View {
    @Environment(ThemeManager.self) var themeManager
    
    var body: some View {
        Picker("Theme", selection: $themeManager.currentTheme) {
            Text("Light").tag(ThemeManager.Theme.light)
            Text("Dark").tag(ThemeManager.Theme.dark)
            Text("System").tag(ThemeManager.Theme.system)
        }
    }
}
```

### 2. Feature Flags

```swift
struct FeatureFlags {
    var showBetaFeatures = false
    var enableExperimentalUI = false
}

private struct FeatureFlagsKey: EnvironmentKey {
    static let defaultValue = FeatureFlags()
}

extension EnvironmentValues {
    var featureFlags: FeatureFlags {
        get { self[FeatureFlagsKey.self] }
        set { self[FeatureFlagsKey.self] = newValue }
    }
}

struct FeatureGatedView: View {
    @Environment(\.featureFlags) var flags
    
    var body: some View {
        VStack {
            Text("Standard features")
            
            if flags.showBetaFeatures {
                Text("Beta feature")
                    .foregroundColor(.orange)
            }
        }
    }
}
```

### 3. Dependency Injection

```swift
protocol APIClient {
    func fetchData() async throws -> [String]
}

class ProductionAPIClient: APIClient {
    func fetchData() async throws -> [String] {
        // Real API call
        return ["Data from API"]
    }
}

class MockAPIClient: APIClient {
    func fetchData() async throws -> [String] {
        return ["Mock data"]
    }
}

private struct APIClientKey: EnvironmentKey {
    static let defaultValue: APIClient = ProductionAPIClient()
}

extension EnvironmentValues {
    var apiClient: APIClient {
        get { self[APIClientKey.self] }
        set { self[APIClientKey.self] = newValue }
    }
}

struct DataView: View {
    @Environment(\.apiClient) var apiClient
    @State private var data: [String] = []
    
    var body: some View {
        List(data, id: \.self) { item in
            Text(item)
        }
        .task {
            data = (try? await apiClient.fetchData()) ?? []
        }
    }
}

// For previews/testing
struct DataView_Previews: PreviewProvider {
    static var previews: some View {
        DataView()
            .environment(\.apiClient, MockAPIClient())
    }
}
```

### 4. User Preferences

```swift
@Observable
class UserPreferences {
    @AppStorage("showTutorial") var showTutorial = true
    @AppStorage("animationsEnabled") var animationsEnabled = true
    @AppStorage("notificationsEnabled") var notificationsEnabled = true
}

struct RootView: View {
    @State private var preferences = UserPreferences()
    
    var body: some View {
        ContentView()
            .environment(preferences)
    }
}

struct FeatureView: View {
    @Environment(UserPreferences.self) var preferences
    
    var body: some View {
        if preferences.showTutorial {
            TutorialView()
        } else {
            MainView()
        }
    }
}
```

---

## Environment Value Propagation

### Scoped Override

```swift
struct ScopedOverride: View {
    var body: some View {
        VStack {
            Text("Uses default font")
            
            VStack {
                Text("Uses large title")
                Text("Also large title")
            }
            .environment(\.font, .largeTitle)
            
            Text("Back to default")
        }
    }
}
```

### Layered Environments

```swift
struct LayeredEnvironments: View {
    var body: some View {
        VStack {
            Text("Level 1")
        }
        .environment(\.customValue, "Layer 1")
        .padding()
        .background(Color.blue.opacity(0.2))
        .environment(\.customValue, "Layer 2")  // Overrides
        .padding()
        .background(Color.green.opacity(0.2))
    }
}
```

---

## Best Practices

### 1. Use Environment for Cross-Cutting Concerns

```swift
// Good: Theme, user session, feature flags
.environment(\.appTheme, theme)
.environment(userData)

// Bad: Passing specific view data
// Use explicit parameters or bindings instead
```

### 2. Provide Sensible Defaults

```swift
private struct MyValueKey: EnvironmentKey {
    static let defaultValue = "Sensible default"  // Good
    // Not: static let defaultValue = ""  // Bad: unclear
}
```

### 3. Document Custom Environment Values

```swift
extension EnvironmentValues {
    /// Controls the app-wide animation speed multiplier.
    /// Default value is 1.0 (normal speed).
    /// - Values > 1.0 speed up animations
    /// - Values < 1.0 slow down animations
    var animationSpeed: Double {
        get { self[AnimationSpeedKey.self] }
        set { self[AnimationSpeedKey.self] = newValue }
    }
}
```

### 4. Avoid Environment for Frequent Updates

```swift
// Bad: Rapidly changing values
@Environment(\.mousePosition) var mousePosition  // Updates too often!

// Good: Use @State or @Binding for local, fast-changing state
@State private var mousePosition: CGPoint = .zero
```

### 5. Prefer @Observable for iOS 17+

```swift
// Modern approach (iOS 17+)
@Observable
class AppState {
    var user: User?
    var isAuthenticated: Bool { user != nil }
}

struct RootView: View {
    @State private var appState = AppState()
    
    var body: some View {
        ContentView()
            .environment(appState)
    }
}

struct ContentView: View {
    @Environment(AppState.self) var appState
    
    var body: some View {
        if appState.isAuthenticated {
            MainView()
        } else {
            LoginView()
        }
    }
}
```

---

## Testing with Environment

### Inject Test Data

```swift
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Default environment
            ContentView()
            
            // Dark mode
            ContentView()
                .preferredColorScheme(.dark)
            
            // Custom environment
            ContentView()
                .environment(\.customTheme, "Test Theme")
            
            // Large text
            ContentView()
                .environment(\.sizeCategory, .accessibilityLarge)
        }
    }
}
```

### Mock Environment Objects

```swift
class MockUserData: ObservableObject {
    @Published var user = User(name: "Test User")
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(MockUserData())
    }
}
```

---

## Migration from @EnvironmentObject to @Observable

```swift
// Old pattern (iOS 13-16)
class OldViewModel: ObservableObject {
    @Published var count = 0
}

struct OldView: View {
    @EnvironmentObject var viewModel: OldViewModel
    
    var body: some View {
        Text("\(viewModel.count)")
    }
}

// New pattern (iOS 17+)
@Observable
class NewViewModel {
    var count = 0
}

struct NewView: View {
    @Environment(NewViewModel.self) var viewModel
    
    var body: some View {
        Text("\(viewModel.count)")
    }
}

// Injection also changes
// Old: .environmentObject(viewModel)
// New: .environment(viewModel)
```

---

## Common System Environment Values Quick Reference

| Environment Value | Type | Purpose |
|------------------|------|---------|
| `\.colorScheme` | ColorScheme | Light/dark mode |
| `\.dynamicTypeSize` | DynamicTypeSize | User's text size |
| `\.sizeCategory` | ContentSizeCategory | Accessibility text size |
| `\.layoutDirection` | LayoutDirection | LTR/RTL layout |
| `\.horizontalSizeClass` | UserInterfaceSizeClass? | Compact/regular |
| `\.verticalSizeClass` | UserInterfaceSizeClass? | Compact/regular |
| `\.dismiss` | DismissAction | Dismiss view |
| `\.openURL` | OpenURLAction | Open URLs |
| `\.refresh` | RefreshAction? | Pull to refresh |
| `\.isEnabled` | Bool | Disabled state |
| `\.scenePhase` | ScenePhase | Active/inactive/background |
| `\.locale` | Locale | User's locale |
| `\.timeZone` | TimeZone | User's time zone |
| `\.calendar` | Calendar | User's calendar |
| `\.displayScale` | CGFloat | Screen pixel density |

---

## Additional Resources

- [EnvironmentValues Documentation](https://developer.apple.com/documentation/swiftui/environmentvalues)
- [Data Essentials in SwiftUI (WWDC)](https://developer.apple.com/videos/play/wwdc2020/10040/)
- [Observation Framework](https://developer.apple.com/documentation/observation)
