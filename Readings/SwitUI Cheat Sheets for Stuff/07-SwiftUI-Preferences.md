# SwiftUI Preferences (PreferenceKey) Cheatsheet

## Overview

PreferenceKey is SwiftUI's system for passing data UP the view hierarchy—from child views to parent views. This is the opposite of environment values (which flow down). Preferences enable children to report their state, size, or other information to ancestors.

---

## PreferenceKey Fundamentals

### What is PreferenceKey?

```swift
protocol PreferenceKey {
    associatedtype Value
    
    // Default value when no preference is set
    static var defaultValue: Value { get }
    
    // How to combine values from multiple children
    static func reduce(value: inout Value, nextValue: () -> Value)
}
```

### Basic Flow

```swift
// 1. Define preference key
struct MyPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())  // Keep maximum
    }
}

// 2. Child sets preference
struct ChildView: View {
    var body: some View {
        Text("Child")
            .preference(key: MyPreferenceKey.self, value: 100)
    }
}

// 3. Parent reads preference
struct ParentView: View {
    @State private var childValue: CGFloat = 0
    
    var body: some View {
        ChildView()
            .onPreferenceChange(MyPreferenceKey.self) { value in
                childValue = value
            }
    }
}
```

---

## Simple Examples

### 1. Reporting View Size

```swift
struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()  // Use latest value
    }
}

struct MeasurableView: View {
    var body: some View {
        GeometryReader { geometry in
            Color.clear
                .preference(key: SizePreferenceKey.self, value: geometry.size)
        }
    }
}

struct ParentView: View {
    @State private var size: CGSize = .zero
    
    var body: some View {
        VStack {
            Text("Child size: \(size.width) x \(size.height)")
            
            Rectangle()
                .fill(.blue)
                .frame(width: 200, height: 100)
                .background(MeasurableView())
        }
        .onPreferenceChange(SizePreferenceKey.self) { size in
            self.size = size
        }
    }
}
```

### 2. Reporting Max Height

```swift
struct MaxHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct EqualHeightRows: View {
    @State private var maxHeight: CGFloat = 0
    
    var body: some View {
        HStack {
            ForEach(items) { item in
                ItemView(item: item)
                    .background(GeometryReader { geo in
                        Color.clear.preference(
                            key: MaxHeightKey.self,
                            value: geo.size.height
                        )
                    })
                    .frame(height: maxHeight)  // Apply max height to all
            }
        }
        .onPreferenceChange(MaxHeightKey.self) { height in
            maxHeight = height
        }
    }
}
```

### 3. Collecting View IDs

```swift
struct ViewIDKey: PreferenceKey {
    static var defaultValue: [String] = []
    
    static func reduce(value: inout [String], nextValue: () -> [String]) {
        value.append(contentsOf: nextValue())
    }
}

struct CollectorView: View {
    @State private var viewIDs: [String] = []
    
    var body: some View {
        VStack {
            Text("View 1")
                .preference(key: ViewIDKey.self, value: ["View1"])
            
            Text("View 2")
                .preference(key: ViewIDKey.self, value: ["View2"])
            
            Text("View 3")
                .preference(key: ViewIDKey.self, value: ["View3"])
        }
        .onPreferenceChange(ViewIDKey.self) { ids in
            viewIDs = ids
            print("Views: \(ids)")  // ["View1", "View2", "View3"]
        }
    }
}
```

---

## Reduce Function Patterns

### Maximum Value

```swift
static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = max(value, nextValue())
}
```

### Minimum Value

```swift
static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = min(value, nextValue())
}
```

### Sum/Total

```swift
static func reduce(value: inout Int, nextValue: () -> Int) {
    value += nextValue()
}
```

### Array Accumulation

```swift
static func reduce(value: inout [Item], nextValue: () -> [Item]) {
    value.append(contentsOf: nextValue())
}
```

### Last Value Wins

```swift
static func reduce(value: inout String, nextValue: () -> String) {
    value = nextValue()
}
```

### Dictionary Merge

```swift
static func reduce(value: inout [String: Int], nextValue: () -> [String: Int]) {
    value.merge(nextValue(), uniquingKeysWith: { $1 })  // New value wins
}
```

### Custom Logic

```swift
struct CustomReduceKey: PreferenceKey {
    static var defaultValue: [ViewData] = []
    
    static func reduce(value: inout [ViewData], nextValue: () -> [ViewData]) {
        let new = nextValue()
        // Custom logic: only add unique items
        value.append(contentsOf: new.filter { item in
            !value.contains(where: { $0.id == item.id })
        })
    }
}
```

---

## Practical Examples

### 1. Adaptive Grid Layout

```swift
struct WidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct AdaptiveGridItem: View {
    let text: String
    
    var body: some View {
        Text(text)
            .padding()
            .background(
                GeometryReader { geo in
                    Color.clear.preference(
                        key: WidthPreferenceKey.self,
                        value: geo.size.width
                    )
                }
            )
    }
}

struct AdaptiveGrid: View {
    let items = ["Short", "Medium Text", "This is a longer text"]
    @State private var maxWidth: CGFloat = 0
    
    var body: some View {
        VStack {
            ForEach(items, id: \.self) { item in
                AdaptiveGridItem(text: item)
                    .frame(width: maxWidth)
            }
        }
        .onPreferenceChange(WidthPreferenceKey.self) { width in
            maxWidth = width
        }
    }
}
```

### 2. Anchor Preferences for Overlays

```swift
struct AnchorPreferenceKey: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] = [:]
    
    static func reduce(
        value: inout [String: Anchor<CGRect>],
        nextValue: () -> [String: Anchor<CGRect>]
    ) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

struct HighlightableView: View {
    let id: String
    let content: String
    
    var body: some View {
        Text(content)
            .padding()
            .anchorPreference(
                key: AnchorPreferenceKey.self,
                value: .bounds
            ) { anchor in
                [id: anchor]
            }
    }
}

struct OverlayContainer: View {
    @State private var highlightID: String?
    
    var body: some View {
        VStack {
            HighlightableView(id: "item1", content: "Item 1")
            HighlightableView(id: "item2", content: "Item 2")
            HighlightableView(id: "item3", content: "Item 3")
        }
        .overlayPreferenceValue(AnchorPreferenceKey.self) { anchors in
            GeometryReader { geometry in
                if let highlightID = highlightID,
                   let anchor = anchors[highlightID] {
                    let rect = geometry[anchor]
                    Rectangle()
                        .stroke(.blue, lineWidth: 3)
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)
                }
            }
        }
        .onTapGesture {
            highlightID = highlightID == nil ? "item2" : nil
        }
    }
}
```

### 3. Scroll Position Tracking

```swift
struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ScrollPositionView: View {
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(0..<50) { i in
                    Text("Item \(i)")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue.opacity(0.2))
                }
            }
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
        .onPreferenceChange(ScrollOffsetKey.self) { offset in
            scrollOffset = offset
        }
        .overlay(alignment: .top) {
            Text("Offset: \(scrollOffset, specifier: "%.0f")")
                .padding()
                .background(.ultraThinMaterial)
        }
    }
}
```

### 4. Navigation Title from Child

```swift
struct NavigationTitleKey: PreferenceKey {
    static var defaultValue: String = ""
    static func reduce(value: inout String, nextValue: () -> String) {
        let new = nextValue()
        if !new.isEmpty {
            value = new
        }
    }
}

extension View {
    func childNavigationTitle(_ title: String) -> some View {
        preference(key: NavigationTitleKey.self, value: title)
    }
}

struct ChildView: View {
    var body: some View {
        Text("Child Content")
            .childNavigationTitle("Child's Title")
    }
}

struct ParentView: View {
    @State private var title = "Default Title"
    
    var body: some View {
        NavigationView {
            ChildView()
                .navigationTitle(title)
        }
        .onPreferenceChange(NavigationTitleKey.self) { newTitle in
            title = newTitle
        }
    }
}
```

### 5. Form Validation State

```swift
struct ValidationStateKey: PreferenceKey {
    static var defaultValue: [String: Bool] = [:]
    
    static func reduce(
        value: inout [String: Bool],
        nextValue: () -> [String: Bool]
    ) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

struct ValidatedField: View {
    let id: String
    @Binding var text: String
    let validator: (String) -> Bool
    
    var isValid: Bool {
        validator(text)
    }
    
    var body: some View {
        TextField("", text: $text)
            .border(isValid ? .green : .red)
            .preference(key: ValidationStateKey.self, value: [id: isValid])
    }
}

struct FormView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isFormValid = false
    
    var body: some View {
        Form {
            ValidatedField(
                id: "email",
                text: $email,
                validator: { $0.contains("@") }
            )
            
            ValidatedField(
                id: "password",
                text: $password,
                validator: { $0.count >= 8 }
            )
            
            Button("Submit") {
                // Submit
            }
            .disabled(!isFormValid)
        }
        .onPreferenceChange(ValidationStateKey.self) { states in
            isFormValid = states.values.allSatisfy { $0 }
        }
    }
}
```

---

## Anchor Preferences

### Understanding Anchor Preferences

```swift
// Anchor represents a geometric position in a coordinate space
// Unlike regular preferences, anchors preserve coordinate information

struct AnchorExample: View {
    var body: some View {
        VStack {
            Text("Target")
                .background(.blue)
                .anchorPreference(
                    key: BoundsPreferenceKey.self,
                    value: .bounds  // Anchor<CGRect>
                ) { anchor in
                    ["target": anchor]
                }
        }
        .backgroundPreferenceValue(BoundsPreferenceKey.self) { anchors in
            GeometryReader { geometry in
                if let anchor = anchors["target"] {
                    let rect = geometry[anchor]  // Resolve anchor to CGRect
                    Circle()
                        .stroke(.red, lineWidth: 2)
                        .frame(width: rect.width + 20, height: rect.height + 20)
                        .position(x: rect.midX, y: rect.midY)
                }
            }
        }
    }
}

struct BoundsPreferenceKey: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] = [:]
    
    static func reduce(
        value: inout [String: Anchor<CGRect>],
        nextValue: () -> [String: Anchor<CGRect>]
    ) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}
```

### Tooltip Example with Anchors

```swift
struct TooltipKey: PreferenceKey {
    struct Item {
        let anchor: Anchor<CGRect>
        let text: String
    }
    
    static var defaultValue: [String: Item] = [:]
    
    static func reduce(
        value: inout [String: Item],
        nextValue: () -> [String: Item]
    ) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

extension View {
    func tooltip(_ text: String, id: String) -> some View {
        anchorPreference(key: TooltipKey.self, value: .bounds) { anchor in
            [id: TooltipKey.Item(anchor: anchor, text: text)]
        }
    }
}

struct TooltipContainer: View {
    @State private var activeTooltip: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Button("Button 1") { }
                .tooltip("This is button 1", id: "btn1")
                .onTapGesture { activeTooltip = "btn1" }
            
            Button("Button 2") { }
                .tooltip("This is button 2", id: "btn2")
                .onTapGesture { activeTooltip = "btn2" }
        }
        .overlayPreferenceValue(TooltipKey.self) { tooltips in
            GeometryReader { geometry in
                if let activeTooltip = activeTooltip,
                   let item = tooltips[activeTooltip] {
                    let rect = geometry[item.anchor]
                    
                    Text(item.text)
                        .padding(8)
                        .background(.black.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(6)
                        .position(x: rect.midX, y: rect.minY - 30)
                }
            }
        }
    }
}
```

---

## Multiple Preferences

### Combining Multiple PreferenceKeys

```swift
struct MultiPreferenceView: View {
    @State private var size: CGSize = .zero
    @State private var position: CGPoint = .zero
    
    var body: some View {
        Rectangle()
            .fill(.blue)
            .frame(width: 100, height: 100)
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: SizeKey.self, value: geometry.size)
                        .preference(key: PositionKey.self, value: CGPoint(
                            x: geometry.frame(in: .global).midX,
                            y: geometry.frame(in: .global).midY
                        ))
                }
            )
            .onPreferenceChange(SizeKey.self) { size in
                self.size = size
            }
            .onPreferenceChange(PositionKey.self) { position in
                self.position = position
            }
    }
}

struct SizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

struct PositionKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
        value = nextValue()
    }
}
```

---

## Advanced Patterns

### 1. Hierarchical Data Collection

```swift
struct ViewHierarchyKey: PreferenceKey {
    struct ViewInfo {
        let id: String
        let level: Int
    }
    
    static var defaultValue: [ViewInfo] = []
    
    static func reduce(value: inout [ViewInfo], nextValue: () -> [ViewInfo]) {
        value.append(contentsOf: nextValue())
    }
}

struct HierarchicalView: View {
    let id: String
    let level: Int
    let children: [HierarchicalView]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(String(repeating: "  ", count: level))\(id)")
                .preference(
                    key: ViewHierarchyKey.self,
                    value: [ViewHierarchyKey.ViewInfo(id: id, level: level)]
                )
            
            ForEach(children.indices, id: \.self) { index in
                children[index]
            }
        }
    }
}
```

### 2. Dynamic Layout Adjustment

```swift
struct DynamicLayoutKey: PreferenceKey {
    static var defaultValue: [CGFloat] = []
    
    static func reduce(value: inout [CGFloat], nextValue: () -> [CGFloat]) {
        value.append(contentsOf: nextValue())
    }
}

struct DynamicLayoutView: View {
    @State private var columnWidths: [CGFloat] = []
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { index in
                Text(items[index])
                    .frame(width: columnWidths.isEmpty ? nil : columnWidths[index])
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(
                                key: DynamicLayoutKey.self,
                                value: [geo.size.width]
                            )
                        }
                    )
            }
        }
        .onPreferenceChange(DynamicLayoutKey.self) { widths in
            // Use max width for all columns
            let maxWidth = widths.max() ?? 0
            columnWidths = Array(repeating: maxWidth, count: items.count)
        }
    }
}
```

### 3. Conditional Overlay

```swift
struct ConditionalOverlayKey: PreferenceKey {
    struct Overlay {
        let id: String
        let anchor: Anchor<CGRect>
        let shouldShow: Bool
    }
    
    static var defaultValue: [Overlay] = []
    
    static func reduce(value: inout [Overlay], nextValue: () -> [Overlay]) {
        value.append(contentsOf: nextValue())
    }
}

struct ConditionalOverlayView: View {
    @State private var showOverlays = false
    
    var body: some View {
        VStack {
            Toggle("Show Overlays", isOn: $showOverlays)
            
            ForEach(0..<5) { i in
                Text("Item \(i)")
                    .padding()
                    .anchorPreference(
                        key: ConditionalOverlayKey.self,
                        value: .bounds
                    ) { anchor in
                        [ConditionalOverlayKey.Overlay(
                            id: "item\(i)",
                            anchor: anchor,
                            shouldShow: showOverlays
                        )]
                    }
            }
        }
        .overlayPreferenceValue(ConditionalOverlayKey.self) { overlays in
            GeometryReader { geometry in
                ForEach(overlays.filter(\.shouldShow), id: \.id) { overlay in
                    let rect = geometry[overlay.anchor]
                    Rectangle()
                        .stroke(.red, lineWidth: 2)
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)
                }
            }
        }
    }
}
```

---

## Performance Considerations

### 1. Minimize Preference Updates

```swift
// Bad: Updates on every frame
.preference(key: MyKey.self, value: Date())  // Changes constantly!

// Good: Only update when value changes
.preference(key: MyKey.self, value: meaningfulValue)
```

### 2. Use Equatable Values

```swift
struct OptimizedKey: PreferenceKey {
    struct Value: Equatable {  // Equatable prevents unnecessary updates
        let size: CGSize
        let id: String
    }
    
    static var defaultValue = Value(size: .zero, id: "")
    
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = nextValue()
    }
}
```

### 3. Batch Preference Updates

```swift
// Bad: Multiple preference keys for related data
.preference(key: WidthKey.self, value: width)
.preference(key: HeightKey.self, value: height)
.preference(key: PositionKey.self, value: position)

// Good: Single preference with combined data
struct LayoutInfoKey: PreferenceKey {
    struct Info {
        let width: CGFloat
        let height: CGFloat
        let position: CGPoint
    }
    
    static var defaultValue = Info(width: 0, height: 0, position: .zero)
    static func reduce(value: inout Info, nextValue: () -> Info) {
        value = nextValue()
    }
}

.preference(key: LayoutInfoKey.self, value: info)
```

---

## Common Patterns Reference

### Size Reporting

```swift
.background(GeometryReader { geo in
    Color.clear.preference(key: SizeKey.self, value: geo.size)
})
```

### Position Tracking

```swift
.background(GeometryReader { geo in
    Color.clear.preference(
        key: PositionKey.self,
        value: geo.frame(in: .global).origin
    )
})
```

### Anchor Preference

```swift
.anchorPreference(key: AnchorKey.self, value: .bounds) { anchor in
    ["id": anchor]
}
```

### Reading Preference

```swift
.onPreferenceChange(MyKey.self) { value in
    // Handle value
}
```

### Overlay with Preference

```swift
.overlayPreferenceValue(AnchorKey.self) { anchors in
    GeometryReader { geometry in
        // Use geometry[anchor] to get CGRect
    }
}
```

### Background with Preference

```swift
.backgroundPreferenceValue(MyKey.self) { value in
    // Create background based on value
}
```

---

## Best Practices

1. **Use descriptive names** - `MaxHeightKey` not `Key1`
2. **Document reduce logic** - Explain how values combine
3. **Make values Equatable** - Prevents unnecessary updates
4. **Keep preferences focused** - One responsibility per key
5. **Use anchors for geometry** - More reliable than coordinates
6. **Test edge cases** - Empty collections, nil values
7. **Minimize preference updates** - Only when values change
8. **Consider performance** - Preferences trigger view updates

---

## Debugging Preferences

### Print Preference Changes

```swift
.onPreferenceChange(MyKey.self) { value in
    print("Preference changed: \(value)")
    self.value = value
}
```

### Visualize Anchors

```swift
.overlayPreferenceValue(AnchorKey.self) { anchors in
    GeometryReader { geometry in
        ForEach(anchors.keys.sorted(), id: \.self) { key in
            if let anchor = anchors[key] {
                let rect = geometry[anchor]
                Rectangle()
                    .stroke(.red, lineWidth: 2)
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
                    .overlay(
                        Text(key)
                            .font(.caption)
                            .background(.white)
                            .position(x: rect.midX, y: rect.minY - 10)
                    )
            }
        }
    }
}
```

---

## Additional Resources

- [PreferenceKey Documentation](https://developer.apple.com/documentation/swiftui/preferencekey)
- [Anchors and Preferences](https://www.fivestars.blog/articles/swiftui-anchor-preferences/)
- [Building Custom Views (WWDC)](https://developer.apple.com/videos/play/wwdc2019/237/)
