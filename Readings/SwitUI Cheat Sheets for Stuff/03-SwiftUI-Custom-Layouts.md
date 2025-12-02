# SwiftUI Custom Layouts Cheatsheet

## Overview

The Layout protocol (iOS 16+) enables creation of custom container views with complete control over child view positioning and sizing. This replaces the old GeometryReader-based approaches with a more efficient, declarative system.

---

## Layout Protocol Basics

### Anatomy of a Layout

```swift
struct BasicLayout: Layout {
    // 1. REQUIRED: Calculate and cache layout properties
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        // Return the size this layout needs
    }
    
    // 2. REQUIRED: Position each subview
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        // Place each subview at calculated positions
    }
    
    // 3. OPTIONAL: Create cache for expensive calculations
    func makeCache(subviews: Subviews) -> CacheData {
        // Calculate and return cached data
    }
    
    // 4. OPTIONAL: Invalidate cache when needed
    func updateCache(_ cache: inout CacheData, subviews: Subviews) {
        // Update cache if subviews change
    }
}
```

### Using a Custom Layout

```swift
// Use like any stack
BasicLayout {
    Text("Child 1")
    Text("Child 2")
    Text("Child 3")
}

// With alignment
BasicLayout(alignment: .center) {
    // children
}

// With spacing
BasicLayout(spacing: 10) {
    // children
}
```

---

## Understanding ProposedViewSize

### What is ProposedViewSize?

```swift
struct ProposedViewSize {
    var width: CGFloat?   // nil means "ideal width"
    var height: CGFloat?  // nil means "ideal height"
}

// Special cases
.unspecified  // Both nil - "what's your ideal size?"
.infinity     // Both .infinity - "take all available space"
.zero         // Both 0 - "minimum size needed"
```

### Handling Proposals

```swift
func sizeThatFits(
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout ()
) -> CGSize {
    // Handle different proposal types
    let width = proposal.width ?? 100  // Default if nil
    let height = proposal.height ?? 50
    
    // Or replace nil with ideal size
    let width = proposal.replacingUnspecifiedDimensions().width
    
    return CGSize(width: width, height: height)
}
```

---

## Understanding Subviews

### The Subviews Collection

```swift
func placeSubviews(
    in bounds: CGRect,
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout ()
) {
    // Iterate over subviews
    for subview in subviews {
        // Get subview's size
        let size = subview.sizeThatFits(.unspecified)
        
        // Place subview
        subview.place(
            at: CGPoint(x: 0, y: 0),
            proposal: ProposedViewSize(size)
        )
    }
}
```

### Subview Methods

```swift
// Get dimensions
let size = subview.sizeThatFits(proposal)
let spacing = subview.spacing  // ViewSpacing for this subview

// Get priority
let priority = subview.priority  // Layout priority (Double)

// Access layout values
let customValue = subview[CustomLayoutValue.self]

// Place subview
subview.place(
    at: position,
    anchor: .center,  // Anchor point (default: .topLeading)
    proposal: proposal
)
```

---

## Simple Custom Layout Examples

### 1. Basic Flow Layout

```swift
struct FlowLayout: Layout {
    var spacing: CGFloat = 10
    
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGSize {
        let result = cache.calculate(
            for: subviews,
            in: proposal.replacingUnspecifiedDimensions().width
        )
        return result.size
    }
    
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) {
        let result = cache.calculate(
            for: subviews,
            in: bounds.width
        )
        
        for (index, subview) in subviews.enumerated() {
            subview.place(
                at: CGPoint(
                    x: bounds.minX + result.positions[index].x,
                    y: bounds.minY + result.positions[index].y
                ),
                proposal: .unspecified
            )
        }
    }
    
    struct Cache {
        var results: [CGFloat: CalculationResult] = [:]
        
        mutating func calculate(
            for subviews: Subviews,
            in width: CGFloat
        ) -> CalculationResult {
            if let cached = results[width] {
                return cached
            }
            
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            var positions: [CGPoint] = []
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > width && x > 0 {
                    // Move to next line
                    x = 0
                    y += lineHeight + 10  // spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + 10  // spacing
            }
            
            let result = CalculationResult(
                size: CGSize(width: width, height: y + lineHeight),
                positions: positions
            )
            
            results[width] = result
            return result
        }
    }
    
    struct CalculationResult {
        let size: CGSize
        let positions: [CGPoint]
    }
    
    func makeCache(subviews: Subviews) -> Cache {
        Cache()
    }
    
    func updateCache(_ cache: inout Cache, subviews: Subviews) {
        cache.results.removeAll()
    }
}

// Usage
FlowLayout {
    ForEach(tags, id: \.self) { tag in
        Text(tag)
            .padding(8)
            .background(.blue)
            .cornerRadius(8)
    }
}
```

### 2. Equal Width Layout

```swift
struct EqualWidthLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        guard !subviews.isEmpty else { return .zero }
        
        let totalSpacing = spacing * CGFloat(subviews.count - 1)
        let width = proposal.replacingUnspecifiedDimensions().width
        let childWidth = (width - totalSpacing) / CGFloat(subviews.count)
        
        let maxHeight = subviews.map { subview in
            subview.sizeThatFits(
                ProposedViewSize(width: childWidth, height: nil)
            ).height
        }.max() ?? 0
        
        return CGSize(width: width, height: maxHeight)
    }
    
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        guard !subviews.isEmpty else { return }
        
        let totalSpacing = spacing * CGFloat(subviews.count - 1)
        let childWidth = (bounds.width - totalSpacing) / CGFloat(subviews.count)
        
        var x = bounds.minX
        
        for subview in subviews {
            subview.place(
                at: CGPoint(x: x, y: bounds.minY),
                proposal: ProposedViewSize(
                    width: childWidth,
                    height: bounds.height
                )
            )
            x += childWidth + spacing
        }
    }
}

// Usage
EqualWidthLayout {
    Button("Cancel") { }
    Button("Save") { }
    Button("Delete") { }
}
```

### 3. Radial Layout

```swift
struct RadialLayout: Layout {
    var radius: CGFloat = 100
    
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let diameter = radius * 2
        return CGSize(width: diameter, height: diameter)
    }
    
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let angleStep = (2 * .pi) / Double(subviews.count)
        
        for (index, subview) in subviews.enumerated() {
            let angle = angleStep * Double(index) - .pi / 2
            
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            
            subview.place(
                at: CGPoint(x: x, y: y),
                anchor: .center,
                proposal: .unspecified
            )
        }
    }
}

// Usage
RadialLayout(radius: 120) {
    ForEach(0..<8) { i in
        Circle()
            .fill(.blue)
            .frame(width: 30, height: 30)
    }
}
```

---

## Advanced Cache Usage

### Why Use Cache?

```swift
// WITHOUT cache: Calculations done twice (sizeThatFits + placeSubviews)
// WITH cache: Calculations done once, reused

struct OptimizedLayout: Layout {
    struct Cache {
        var sizes: [CGSize] = []
        var positions: [CGPoint] = []
        var totalSize: CGSize = .zero
    }
    
    func makeCache(subviews: Subviews) -> Cache {
        Cache()
    }
    
    func updateCache(_ cache: inout Cache, subviews: Subviews) {
        // Recalculate when subviews change
        cache.sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        
        // Calculate positions based on sizes
        var y: CGFloat = 0
        cache.positions = cache.sizes.map { size in
            let position = CGPoint(x: 0, y: y)
            y += size.height + 10
            return position
        }
        
        cache.totalSize = CGSize(
            width: cache.sizes.map(\.width).max() ?? 0,
            height: y - 10
        )
    }
    
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGSize {
        cache.totalSize  // Just return cached value!
    }
    
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) {
        for (index, subview) in subviews.enumerated() {
            subview.place(
                at: CGPoint(
                    x: bounds.minX + cache.positions[index].x,
                    y: bounds.minY + cache.positions[index].y
                ),
                proposal: ProposedViewSize(cache.sizes[index])
            )
        }
    }
}
```

---

## Layout Values & Custom Data

### Defining Custom Layout Values

```swift
struct CustomPriorityKey: LayoutValueKey {
    static let defaultValue: Double = 0
}

extension View {
    func customPriority(_ value: Double) -> some View {
        layoutValue(key: CustomPriorityKey.self, value: value)
    }
}
```

### Reading Layout Values

```swift
struct PriorityLayout: Layout {
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        // Sort subviews by custom priority
        let sorted = subviews.sorted { 
            $0[CustomPriorityKey.self] > $1[CustomPriorityKey.self]
        }
        
        // Place highest priority views first
        for subview in sorted {
            let priority = subview[CustomPriorityKey.self]
            // ... placement logic
        }
    }
}

// Usage
PriorityLayout {
    Text("Low").customPriority(1)
    Text("High").customPriority(10)
    Text("Medium").customPriority(5)
}
```

---

## Complex Layout Examples

### 1. Masonry/Pinterest Layout

```swift
struct MasonryLayout: Layout {
    var columns: Int = 2
    var spacing: CGFloat = 8
    
    struct Cache {
        var columnHeights: [CGFloat] = []
        var frames: [CGRect] = []
    }
    
    func makeCache(subviews: Subviews) -> Cache {
        Cache(columnHeights: Array(repeating: 0, count: columns))
    }
    
    func updateCache(_ cache: inout Cache, subviews: Subviews) {
        cache.columnHeights = Array(repeating: 0, count: columns)
        cache.frames = []
    }
    
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGSize {
        let width = proposal.replacingUnspecifiedDimensions().width
        calculateFrames(in: width, subviews: subviews, cache: &cache)
        
        let maxHeight = cache.columnHeights.max() ?? 0
        return CGSize(width: width, height: maxHeight)
    }
    
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) {
        for (index, subview) in subviews.enumerated() {
            let frame = cache.frames[index]
            subview.place(
                at: CGPoint(
                    x: bounds.minX + frame.minX,
                    y: bounds.minY + frame.minY
                ),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }
    
    private func calculateFrames(
        in width: CGFloat,
        subviews: Subviews,
        cache: inout Cache
    ) {
        guard cache.frames.isEmpty else { return }
        
        let totalSpacing = spacing * CGFloat(columns - 1)
        let columnWidth = (width - totalSpacing) / CGFloat(columns)
        
        cache.columnHeights = Array(repeating: 0, count: columns)
        cache.frames = []
        
        for subview in subviews {
            // Find shortest column
            let shortestColumn = cache.columnHeights
                .enumerated()
                .min(by: { $0.element < $1.element })?
                .offset ?? 0
            
            let size = subview.sizeThatFits(
                ProposedViewSize(width: columnWidth, height: nil)
            )
            
            let x = CGFloat(shortestColumn) * (columnWidth + spacing)
            let y = cache.columnHeights[shortestColumn]
            
            cache.frames.append(CGRect(
                x: x,
                y: y,
                width: columnWidth,
                height: size.height
            ))
            
            cache.columnHeights[shortestColumn] += size.height + spacing
        }
    }
}

// Usage
ScrollView {
    MasonryLayout(columns: 3) {
        ForEach(items) { item in
            ItemCard(item: item)
        }
    }
    .padding()
}
```

### 2. Custom Grid with Dynamic Columns

```swift
struct AdaptiveGrid: Layout {
    var minItemWidth: CGFloat = 100
    var spacing: CGFloat = 8
    
    struct Cache {
        var columns: Int = 0
        var itemWidth: CGFloat = 0
    }
    
    func makeCache(subviews: Subviews) -> Cache {
        Cache()
    }
    
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGSize {
        let width = proposal.replacingUnspecifiedDimensions().width
        
        // Calculate columns
        cache.columns = max(1, Int((width + spacing) / (minItemWidth + spacing)))
        let totalSpacing = spacing * CGFloat(cache.columns - 1)
        cache.itemWidth = (width - totalSpacing) / CGFloat(cache.columns)
        
        // Calculate rows needed
        let rows = Int(ceil(Double(subviews.count) / Double(cache.columns)))
        
        // Get max height per row
        var maxHeights: [CGFloat] = []
        for row in 0..<rows {
            var maxHeight: CGFloat = 0
            for col in 0..<cache.columns {
                let index = row * cache.columns + col
                guard index < subviews.count else { break }
                
                let size = subviews[index].sizeThatFits(
                    ProposedViewSize(width: cache.itemWidth, height: nil)
                )
                maxHeight = max(maxHeight, size.height)
            }
            maxHeights.append(maxHeight)
        }
        
        let totalHeight = maxHeights.reduce(0, +) + spacing * CGFloat(rows - 1)
        return CGSize(width: width, height: totalHeight)
    }
    
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) {
        let rows = Int(ceil(Double(subviews.count) / Double(cache.columns)))
        var y = bounds.minY
        
        for row in 0..<rows {
            var maxHeight: CGFloat = 0
            
            // First pass: determine row height
            for col in 0..<cache.columns {
                let index = row * cache.columns + col
                guard index < subviews.count else { break }
                
                let size = subviews[index].sizeThatFits(
                    ProposedViewSize(width: cache.itemWidth, height: nil)
                )
                maxHeight = max(maxHeight, size.height)
            }
            
            // Second pass: place views
            for col in 0..<cache.columns {
                let index = row * cache.columns + col
                guard index < subviews.count else { break }
                
                let x = bounds.minX + CGFloat(col) * (cache.itemWidth + spacing)
                
                subviews[index].place(
                    at: CGPoint(x: x, y: y),
                    proposal: ProposedViewSize(
                        width: cache.itemWidth,
                        height: maxHeight
                    )
                )
            }
            
            y += maxHeight + spacing
        }
    }
}

// Usage
AdaptiveGrid(minItemWidth: 150, spacing: 12) {
    ForEach(photos) { photo in
        PhotoView(photo: photo)
    }
}
```

### 3. Staggered Layout

```swift
struct StaggeredLayout: Layout {
    var spacing: CGFloat = 8
    var staggerOffset: CGFloat = 20
    
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        guard !subviews.isEmpty else { return .zero }
        
        var width: CGFloat = 0
        var height: CGFloat = 0
        
        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            let offset = CGFloat(index) * staggerOffset
            
            width = max(width, size.width + offset)
            height = max(height, size.height + offset)
        }
        
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        for (index, subview) in subviews.enumerated() {
            let offset = CGFloat(index) * staggerOffset
            
            subview.place(
                at: CGPoint(
                    x: bounds.minX + offset,
                    y: bounds.minY + offset
                ),
                proposal: .unspecified
            )
        }
    }
}

// Usage - creates card stack effect
StaggeredLayout(staggerOffset: 30) {
    ForEach(cards) { card in
        CardView(card: card)
    }
}
```

---

## Layout Composition

### Combining Layouts

```swift
struct CompoundLayout: Layout {
    var useRadial: Bool
    
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        if useRadial {
            return RadialLayout().sizeThatFits(
                proposal: proposal,
                subviews: subviews,
                cache: &cache
            )
        } else {
            return FlowLayout().sizeThatFits(
                proposal: proposal,
                subviews: subviews,
                cache: &cache
            )
        }
    }
    
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        if useRadial {
            RadialLayout().placeSubviews(
                in: bounds,
                proposal: proposal,
                subviews: subviews,
                cache: &cache
            )
        } else {
            FlowLayout().placeSubviews(
                in: bounds,
                proposal: proposal,
                subviews: subviews,
                cache: &cache
            )
        }
    }
}
```

### AnyLayout (iOS 16+)

```swift
struct LayoutSwitcher: View {
    @State private var useRadial = false
    
    var body: some View {
        let layout = useRadial ? AnyLayout(RadialLayout()) : AnyLayout(FlowLayout())
        
        layout {
            ForEach(items) { item in
                ItemView(item: item)
            }
        }
        .animation(.default, value: useRadial)
    }
}
```

---

## ViewSpacing

### Understanding ViewSpacing

```swift
struct ViewSpacing {
    // Distance from view edge to content
    var top: CGFloat
    var bottom: CGFloat
    var leading: CGFloat
    var trailing: CGFloat
}

// Access in layout
func placeSubviews(...) {
    for subview in subviews {
        let spacing = subview.spacing
        // Use spacing.leading, spacing.trailing, etc.
    }
}
```

### Custom Spacing

```swift
extension View {
    func customSpacing(_ edges: Edge.Set, _ value: CGFloat) -> some View {
        self.modifier(CustomSpacingModifier(edges: edges, value: value))
    }
}

private struct CustomSpacingModifier: ViewModifier {
    let edges: Edge.Set
    let value: CGFloat
    
    func body(content: Content) -> some View {
        content
            .padding(edges, value)
    }
}
```

---

## Alignment in Custom Layouts

### Using Alignment Guides

```swift
struct AlignedLayout: Layout {
    var alignment: HorizontalAlignment = .center
    
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var y = bounds.minY
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            let x: CGFloat
            switch alignment {
            case .leading:
                x = bounds.minX
            case .trailing:
                x = bounds.maxX - size.width
            default:  // center
                x = bounds.midX - size.width / 2
            }
            
            subview.place(
                at: CGPoint(x: x, y: y),
                proposal: .unspecified
            )
            
            y += size.height + 10
        }
    }
    
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        
        return CGSize(
            width: sizes.map(\.width).max() ?? 0,
            height: sizes.map(\.height).reduce(0, +) + 
                    CGFloat(sizes.count - 1) * 10
        )
    }
}
```

---

## Performance Optimization

### 1. Efficient Caching

```swift
struct OptimizedCache {
    // Cache calculations by proposal width
    private var cache: [Int: LayoutData] = [:]
    
    mutating func get(
        for width: CGFloat,
        calculate: () -> LayoutData
    ) -> LayoutData {
        let key = Int(width)
        if let cached = cache[key] {
            return cached
        }
        let data = calculate()
        cache[key] = data
        return data
    }
    
    mutating func invalidate() {
        cache.removeAll()
    }
}
```

### 2. Avoid Redundant Calculations

```swift
// Bad: Recalculates every time
func placeSubviews(...) {
    for subview in subviews {
        let size = subview.sizeThatFits(.unspecified)  // Expensive!
        // ...
    }
}

// Good: Calculate once in updateCache
struct Cache {
    var sizes: [CGSize] = []
}

func updateCache(_ cache: inout Cache, subviews: Subviews) {
    cache.sizes = subviews.map { $0.sizeThatFits(.unspecified) }
}

func placeSubviews(..., cache: inout Cache) {
    for (index, subview) in subviews.enumerated() {
        let size = cache.sizes[index]  // Fast lookup!
        // ...
    }
}
```

### 3. Lazy Calculation

```swift
struct LazyCache {
    private var sizes: [Int: CGSize] = [:]
    
    mutating func size(
        for index: Int,
        subview: LayoutSubview
    ) -> CGSize {
        if let cached = sizes[index] {
            return cached
        }
        let size = subview.sizeThatFits(.unspecified)
        sizes[index] = size
        return size
    }
}
```

---

## Debugging Custom Layouts

### Visualization Helper

```swift
struct LayoutDebugger: Layout {
    var baseLayout: any Layout
    var showBounds: Bool = true
    
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        baseLayout.sizeThatFits(
            proposal: proposal,
            subviews: subviews,
            cache: &cache
        )
    }
    
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        baseLayout.placeSubviews(
            in: bounds,
            proposal: proposal,
            subviews: subviews,
            cache: &cache
        )
        
        if showBounds {
            print("Layout bounds: \(bounds)")
            for (index, subview) in subviews.enumerated() {
                let size = subview.sizeThatFits(.unspecified)
                print("  Subview \(index): \(size)")
            }
        }
    }
}
```

### Print Diagnostics

```swift
func sizeThatFits(...) -> CGSize {
    let result = calculateSize(...)
    print("sizeThatFits: proposal=\(proposal), result=\(result)")
    return result
}

func placeSubviews(...) {
    print("placeSubviews: bounds=\(bounds)")
    // ...
}
```

---

## Common Patterns

### 1. Responsive Layout

```swift
struct ResponsiveLayout: Layout {
    func placeSubviews(...) {
        let width = bounds.width
        
        if width < 600 {
            // Mobile layout
            placeVertically(...)
        } else {
            // Desktop layout
            placeHorizontally(...)
        }
    }
}
```

### 2. Animated Transitions

```swift
struct AnimatedLayout: View {
    @State private var isExpanded = false
    
    var body: some View {
        let layout = isExpanded ? 
            AnyLayout(ExpandedLayout()) : 
            AnyLayout(CompactLayout())
        
        layout {
            ForEach(items) { item in
                ItemView(item: item)
            }
        }
        .animation(.spring(), value: isExpanded)
    }
}
```

### 3. Priority-Based Layout

```swift
struct PriorityBasedLayout: Layout {
    func placeSubviews(...) {
        let sorted = subviews.sorted { 
            $0.priority > $1.priority 
        }
        
        var availableSpace = bounds.width
        
        for subview in sorted {
            let ideal = subview.sizeThatFits(.unspecified)
            let allocated = min(ideal.width, availableSpace)
            
            subview.place(
                at: position,
                proposal: ProposedViewSize(
                    width: allocated,
                    height: bounds.height
                )
            )
            
            availableSpace -= allocated
        }
    }
}
```

---

## Best Practices

1. **Always implement both required methods**
   - `sizeThatFits` and `placeSubviews`

2. **Use cache for expensive calculations**
   - Measure subview sizes once
   - Cache layout calculations

3. **Handle edge cases**
   - Empty subviews
   - Nil proposals
   - Zero-sized containers

4. **Respect proposals**
   - Don't ignore parent's size constraints
   - Use `replacingUnspecifiedDimensions()` carefully

5. **Test with different content**
   - Various numbers of children
   - Different child sizes
   - Dynamic content changes

6. **Consider accessibility**
   - Support dynamic type
   - Respect layout direction (RTL)

7. **Profile performance**
   - Use Instruments to measure
   - Optimize hot paths

---

## Migration from GeometryReader

```swift
// Old approach
var body: some View {
    GeometryReader { geometry in
        // Manual layout calculations
        ForEach(items.indices, id: \.self) { index in
            items[index]
                .position(x: calculateX(index, geometry.size.width),
                         y: calculateY(index, geometry.size.width))
        }
    }
}

// New approach with Layout protocol
var body: some View {
    CustomLayout {
        ForEach(items) { item in
            ItemView(item: item)
        }
    }
}
```

**Benefits**:
- More declarative
- Better performance
- Automatic caching
- Type-safe
- Composable

---

## Additional Resources

- [WWDC22: Compose custom layouts](https://developer.apple.com/videos/play/wwdc2022/10056/)
- [Layout Protocol Documentation](https://developer.apple.com/documentation/swiftui/layout)
- [Advanced Layout Guide](https://www.objc.io/blog/2022/08/09/grid-layout/)
