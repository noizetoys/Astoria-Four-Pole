# SwiftUI Custom Content Wrappers Cheatsheet

## Overview

Content wrappers are SwiftUI views that accept and transform child content using `@ViewBuilder`. They enable creation of reusable container views with custom behavior, styling, and layout patterns.

---

## Basic Content Wrapper Pattern

### Simple Wrapper

```swift
struct Card<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(.white)
            .cornerRadius(12)
            .shadow(radius: 3)
    }
}

// Usage
Card {
    Text("Hello")
    Text("World")
}
```

### Understanding @ViewBuilder

```swift
// @ViewBuilder enables multiple views without explicit containers
@ViewBuilder
func makeContent() -> some View {
    Text("Line 1")
    Text("Line 2")
    Text("Line 3")
    // Implicitly creates TupleView
}

// Without @ViewBuilder, you'd need:
func makeContent() -> some View {
    VStack {  // Explicit container required
        Text("Line 1")
        Text("Line 2")
        Text("Line 3")
    }
}
```

---

## Common Wrapper Patterns

### 1. Conditional Wrapper

```swift
struct ConditionalCard<Content: View>: View {
    let isElevated: Bool
    let content: Content
    
    init(
        isElevated: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.isElevated = isElevated
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(.white)
            .cornerRadius(isElevated ? 16 : 8)
            .shadow(radius: isElevated ? 8 : 2)
    }
}

// Usage
ConditionalCard(isElevated: true) {
    Text("Elevated content")
}
```

### 2. Styled Container

```swift
struct Section<Content: View>: View {
    let title: String
    let content: Content
    
    init(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            
            content
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(10)
        }
    }
}

// Usage
Section("Settings") {
    Toggle("Dark Mode", isOn: $isDarkMode)
    Toggle("Notifications", isOn: $notificationsEnabled)
}
```

### 3. Header-Content-Footer Pattern

```swift
struct Frame<Header: View, Content: View, Footer: View>: View {
    let header: Header
    let content: Content
    let footer: Footer
    
    init(
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.header = header()
        self.content = content()
        self.footer = footer()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            header
                .frame(maxWidth: .infinity)
                .background(.blue)
                .foregroundColor(.white)
            
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            footer
                .frame(maxWidth: .infinity)
                .background(.gray.opacity(0.2))
        }
    }
}

// Usage
Frame {
    Text("Header")
        .font(.headline)
        .padding()
} content: {
    ScrollView {
        Text("Main content")
    }
} footer: {
    HStack {
        Button("Cancel") { }
        Button("OK") { }
    }
    .padding()
}
```

---

## Optional Content Wrappers

### Using Optional Views

```swift
struct OptionalHeader<Header: View, Content: View>: View {
    let header: Header?
    let content: Content
    
    init(
        @ViewBuilder header: () -> Header?,
        @ViewBuilder content: () -> Content
    ) {
        self.header = header()
        self.content = content()
    }
    
    var body: some View {
        VStack {
            if let header = header {
                header
                    .font(.headline)
                Divider()
            }
            
            content
        }
    }
}

// Usage with optional header
OptionalHeader {
    if showHeader {
        Text("Optional Header")
    }
} content: {
    Text("Content always shows")
}
```

### Default Values Pattern

```swift
struct DefaultableWrapper<Content: View>: View {
    let content: Content
    let title: String
    
    init(
        title: String = "Untitled",
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
            content
        }
        .padding()
    }
}

// Usage
DefaultableWrapper {
    Text("Content")
}

DefaultableWrapper(title: "Custom Title") {
    Text("Content")
}
```

---

## Multiple Content Regions

### Dual Content Wrapper

```swift
struct SplitView<Leading: View, Trailing: View>: View {
    let leading: Leading
    let trailing: Trailing
    let spacing: CGFloat
    
    init(
        spacing: CGFloat = 16,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.spacing = spacing
        self.leading = leading()
        self.trailing = trailing()
    }
    
    var body: some View {
        HStack(spacing: spacing) {
            leading
                .frame(maxWidth: .infinity)
            
            Divider()
            
            trailing
                .frame(maxWidth: .infinity)
        }
    }
}

// Usage
SplitView {
    Text("Left side")
} trailing: {
    Text("Right side")
}
```

### Flexible Multi-Region

```swift
struct Dashboard<
    TopBar: View,
    Sidebar: View,
    MainContent: View,
    DetailPanel: View
>: View {
    let topBar: TopBar
    let sidebar: Sidebar
    let mainContent: MainContent
    let detailPanel: DetailPanel
    
    init(
        @ViewBuilder topBar: () -> TopBar,
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder mainContent: () -> MainContent,
        @ViewBuilder detailPanel: () -> DetailPanel
    ) {
        self.topBar = topBar()
        self.sidebar = sidebar()
        self.mainContent = mainContent()
        self.detailPanel = detailPanel()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            topBar
                .frame(height: 60)
            
            HStack(spacing: 0) {
                sidebar
                    .frame(width: 200)
                
                mainContent
                    .frame(maxWidth: .infinity)
                
                detailPanel
                    .frame(width: 300)
            }
        }
    }
}
```

---

## Environment-Aware Wrappers

### Passing Environment Down

```swift
struct ThemedContainer<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(backgroundColor)
            .cornerRadius(12)
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? .black : .white
    }
}

// Usage - content automatically adapts
ThemedContainer {
    Text("Themed content")
}
```

### Custom Environment Injection

```swift
struct CustomEnvironment<Content: View>: View {
    let customValue: String
    let content: Content
    
    init(
        customValue: String,
        @ViewBuilder content: () -> Content
    ) {
        self.customValue = customValue
        self.content = content()
    }
    
    var body: some View {
        content
            .environment(\.customKey, customValue)
    }
}

// Define custom environment key
private struct CustomKey: EnvironmentKey {
    static let defaultValue = ""
}

extension EnvironmentValues {
    var customKey: String {
        get { self[CustomKey.self] }
        set { self[CustomKey.self] = newValue }
    }
}

// Usage
CustomEnvironment(customValue: "Hello") {
    ChildView()  // Can access customKey
}
```

---

## Generic Content Wrappers

### Type-Erased Wrapper

```swift
struct AnyViewWrapper<Content: View>: View {
    let content: AnyView
    
    init<V: View>(@ViewBuilder content: () -> V) {
        self.content = AnyView(content())
    }
    
    var body: some View {
        content
            .padding()
    }
}

// Usage with different view types
AnyViewWrapper {
    if condition {
        Text("Text view")
    } else {
        Image(systemName: "star")
    }
}
```

### Protocol-Based Wrapper

```swift
protocol WrapperConfiguration {
    var backgroundColor: Color { get }
    var cornerRadius: CGFloat { get }
}

struct ConfiguredWrapper<
    Config: WrapperConfiguration,
    Content: View
>: View {
    let config: Config
    let content: Content
    
    init(
        config: Config,
        @ViewBuilder content: () -> Content
    ) {
        self.config = config
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(config.backgroundColor)
            .cornerRadius(config.cornerRadius)
    }
}

// Define configuration
struct CardConfig: WrapperConfiguration {
    var backgroundColor: Color = .white
    var cornerRadius: CGFloat = 12
}

// Usage
ConfiguredWrapper(config: CardConfig()) {
    Text("Configured content")
}
```

---

## Practical Examples

### 1. Loading Wrapper

```swift
struct LoadingWrapper<Content: View>: View {
    let isLoading: Bool
    let content: Content
    
    init(
        isLoading: Bool,
        @ViewBuilder content: () -> Content
    ) {
        self.isLoading = isLoading
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            content
                .disabled(isLoading)
                .blur(radius: isLoading ? 3 : 0)
            
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            }
        }
    }
}

// Usage
LoadingWrapper(isLoading: viewModel.isLoading) {
    List(items) { item in
        ItemRow(item: item)
    }
}
```

### 2. Error Boundary

```swift
struct ErrorBoundary<Content: View>: View {
    let error: Error?
    let retry: () -> Void
    let content: Content
    
    init(
        error: Error?,
        retry: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.error = error
        self.retry = retry
        self.content = content()
    }
    
    var body: some View {
        Group {
            if let error = error {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    
                    Text(error.localizedDescription)
                        .multilineTextAlignment(.center)
                    
                    Button("Retry", action: retry)
                        .buttonStyle(.bordered)
                }
                .padding()
            } else {
                content
            }
        }
    }
}

// Usage
ErrorBoundary(error: viewModel.error, retry: viewModel.reload) {
    ContentView(data: viewModel.data)
}
```

### 3. Permission Wrapper

```swift
struct PermissionGate<Content: View>: View {
    let hasPermission: Bool
    let requestPermission: () -> Void
    let content: Content
    
    init(
        hasPermission: Bool,
        requestPermission: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.hasPermission = hasPermission
        self.requestPermission = requestPermission
        self.content = content()
    }
    
    var body: some View {
        Group {
            if hasPermission {
                content
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("Permission Required")
                        .font(.headline)
                    
                    Text("This feature requires special permissions")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Grant Permission", action: requestPermission)
                        .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
    }
}

// Usage
PermissionGate(
    hasPermission: cameraManager.hasPermission,
    requestPermission: cameraManager.requestPermission
) {
    CameraView()
}
```

### 4. Tooltip Wrapper

```swift
struct Tooltip<Content: View>: View {
    let message: String
    let content: Content
    @State private var showTooltip = false
    
    init(
        _ message: String,
        @ViewBuilder content: () -> Content
    ) {
        self.message = message
        self.content = content()
    }
    
    var body: some View {
        content
            .onHover { hovering in
                showTooltip = hovering
            }
            .overlay(alignment: .top) {
                if showTooltip {
                    Text(message)
                        .font(.caption)
                        .padding(8)
                        .background(.black.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(6)
                        .offset(y: -40)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: showTooltip)
    }
}

// Usage
Tooltip("Click to save") {
    Button("Save") { }
}
```

### 5. Badge Wrapper

```swift
struct BadgeWrapper<Content: View>: View {
    let count: Int
    let content: Content
    
    init(
        count: Int,
        @ViewBuilder content: () -> Content
    ) {
        self.count = count
        self.content = content()
    }
    
    var body: some View {
        content
            .overlay(alignment: .topTrailing) {
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(4)
                        .background(.red)
                        .clipShape(Circle())
                        .offset(x: 10, y: -10)
                }
            }
    }
}

// Usage
BadgeWrapper(count: unreadMessages) {
    Image(systemName: "envelope")
        .font(.title)
}
```

---

## Advanced Patterns

### 1. Preference Key Integration

```swift
struct MeasuringWrapper<Content: View>: View {
    @Binding var size: CGSize
    let content: Content
    
    init(
        size: Binding<CGSize>,
        @ViewBuilder content: () -> Content
    ) {
        self._size = size
        self.content = content()
    }
    
    var body: some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: SizePreferenceKey.self,
                        value: geometry.size
                    )
                }
            )
            .onPreferenceChange(SizePreferenceKey.self) { newSize in
                size = newSize
            }
    }
}

struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

// Usage
@State private var contentSize: CGSize = .zero

MeasuringWrapper(size: $contentSize) {
    Text("Measured content")
}
.onChange(of: contentSize) { size in
    print("Content size: \(size)")
}
```

### 2. Animated Wrapper

```swift
struct AnimatedPresence<Content: View>: View {
    let isPresent: Bool
    let content: Content
    
    init(
        isPresent: Bool,
        @ViewBuilder content: () -> Content
    ) {
        self.isPresent = isPresent
        self.content = content()
    }
    
    var body: some View {
        Group {
            if isPresent {
                content
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
            }
        }
        .animation(.spring(), value: isPresent)
    }
}

// Usage
AnimatedPresence(isPresent: showDetails) {
    DetailView()
}
```

### 3. Context Menu Wrapper

```swift
struct ContextualWrapper<Content: View, Menu: View>: View {
    let content: Content
    let menu: Menu
    
    init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder menu: () -> Menu
    ) {
        self.content = content()
        self.menu = menu()
    }
    
    var body: some View {
        content
            .contextMenu {
                menu
            }
    }
}

// Usage
ContextualWrapper {
    Text("Right-click me")
} menu: {
    Button("Copy") { }
    Button("Paste") { }
    Divider()
    Button("Delete", role: .destructive) { }
}
```

### 4. Scroll Wrapper with Tracking

```swift
struct TrackedScrollView<Content: View>: View {
    @Binding var scrollOffset: CGFloat
    let content: Content
    
    init(
        scrollOffset: Binding<CGFloat>,
        @ViewBuilder content: () -> Content
    ) {
        self._scrollOffset = scrollOffset
        self.content = content()
    }
    
    var body: some View {
        ScrollView {
            content
                .background(
                    GeometryReader { geometry in
                        Color.clear.preference(
                            key: ScrollOffsetKey.self,
                            value: geometry.frame(in: .named("scroll")).minY
                        )
                    }
                )
        }
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(ScrollOffsetKey.self) { value in
            scrollOffset = value
        }
    }
}

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// Usage
@State private var scrollOffset: CGFloat = 0

TrackedScrollView(scrollOffset: $scrollOffset) {
    VStack {
        ForEach(items) { item in
            ItemView(item: item)
        }
    }
}
```

---

## Wrapper Composition

### Combining Wrappers

```swift
// Stack wrappers
Card {
    LoadingWrapper(isLoading: isLoading) {
        ErrorBoundary(error: error, retry: retry) {
            ContentView()
        }
    }
}

// Create composite wrapper
struct SmartWrapper<Content: View>: View {
    let isLoading: Bool
    let error: Error?
    let retry: () -> Void
    let content: Content
    
    init(
        isLoading: Bool,
        error: Error?,
        retry: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.isLoading = isLoading
        self.error = error
        self.retry = retry
        self.content = content()
    }
    
    var body: some View {
        Card {
            LoadingWrapper(isLoading: isLoading) {
                ErrorBoundary(error: error, retry: retry) {
                    content
                }
            }
        }
    }
}

// Usage
SmartWrapper(
    isLoading: viewModel.isLoading,
    error: viewModel.error,
    retry: viewModel.reload
) {
    ContentView(data: viewModel.data)
}
```

---

## Best Practices

### 1. Naming Conventions

```swift
// Clear, descriptive names
struct Card<Content: View>              // Good
struct Wrapper<Content: View>           // Too generic

// Indicate purpose
struct LoadingWrapper                   // Good
struct LW                              // Too cryptic
```

### 2. Parameter Order

```swift
// Put @ViewBuilder last
init(
    title: String,
    isExpanded: Bool,
    @ViewBuilder content: () -> Content  // Last
)

// Group related parameters
init(
    // Configuration
    style: Style,
    theme: Theme,
    // Content
    @ViewBuilder content: () -> Content
)
```

### 3. Default Values

```swift
init(
    spacing: CGFloat = 16,           // Sensible defaults
    backgroundColor: Color = .white,
    @ViewBuilder content: () -> Content
)
```

### 4. Type Constraints

```swift
// Be specific when needed
struct ImageCard<Content: View>: View where Content: View {
    // Content must be a View
}

// Use protocols for flexibility
struct ConfigurableWrapper<
    Config: WrapperConfiguration,
    Content: View
>: View {
    // Config can be any type conforming to WrapperConfiguration
}
```

### 5. Performance

```swift
// Avoid expensive operations in init
init(@ViewBuilder content: () -> Content) {
    self.content = content()  // Simple assignment
    // Not: self.processedContent = processExpensively(content())
}

// Use lazy evaluation
var body: some View {
    expensiveComputation  // Computed property
}

private var expensiveComputation: some View {
    // Computed only when needed
}
```

---

## Common Pitfalls

### 1. Storing Content Incorrectly

```swift
// Wrong: Storing generic Content type in @State
struct BadWrapper<Content: View>: View {
    @State private var storedContent: Content  // Error!
    
    init(@ViewBuilder content: () -> Content) {
        _storedContent = State(initialValue: content())  // Error!
    }
}

// Correct: Just store the content directly
struct GoodWrapper<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
}
```

### 2. Type Erasure Misuse

```swift
// Avoid unnecessary type erasure
struct BadWrapper: View {
    let content: AnyView  // Loses type information
}

// Prefer generics
struct GoodWrapper<Content: View>: View {
    let content: Content  // Preserves type information
}
```

### 3. Missing @ViewBuilder

```swift
// Wrong: No @ViewBuilder
init(content: () -> Content) {
    self.content = content()
}

// Can't use multiple views:
// Wrapper {
//     Text("Line 1")  // Error!
//     Text("Line 2")
// }

// Correct: With @ViewBuilder
init(@ViewBuilder content: () -> Content) {
    self.content = content()
}
```

---

## Testing Wrappers

```swift
// Create test wrapper
struct TestWrapper: View {
    var body: some View {
        Card {
            Text("Test content")
            Image(systemName: "star")
        }
    }
}

// Preview
struct TestWrapper_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TestWrapper()
            
            TestWrapper()
                .preferredColorScheme(.dark)
            
            TestWrapper()
                .previewLayout(.sizeThatFits)
        }
    }
}
```

---

## Additional Resources

- [ViewBuilder Documentation](https://developer.apple.com/documentation/swiftui/viewbuilder)
- [Building Custom Views (WWDC)](https://developer.apple.com/videos/play/wwdc2019/237/)
- [Swift Generics](https://docs.swift.org/swift-book/LanguageGuide/Generics.html)
