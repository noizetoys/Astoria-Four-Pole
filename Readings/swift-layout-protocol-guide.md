# Complete Guide to Swift's Layout Protocol

## Table of Contents
1. [Introduction](#introduction)
2. [Understanding the Layout Protocol](#understanding-the-layout-protocol)
3. [Core Protocol Requirements](#core-protocol-requirements)
4. [Building Your First Custom Layout](#building-your-first-custom-layout)
5. [Advanced Layout Techniques](#advanced-layout-techniques)
6. [Layout Caching and Performance](#layout-caching-and-performance)
7. [Real-World Examples](#real-world-examples)
8. [Best Practices](#best-practices)

---

## Introduction

The `Layout` protocol, introduced in iOS 16, is SwiftUI's powerful mechanism for creating custom layout containers. It gives you precise control over how views are positioned and sized, going beyond what's possible with HStack, VStack, and ZStack.

### Why Use the Layout Protocol?

- **Custom Positioning**: Create layouts that aren't possible with standard containers
- **Performance**: Efficient layout calculations with built-in caching
- **Flexibility**: Full control over spacing, alignment, and sizing
- **Composability**: Custom layouts work seamlessly with SwiftUI's view system

---

## Understanding the Layout Protocol

The Layout protocol is a type that can arrange a collection of views. Here's the basic structure:

```swift
public protocol Layout: Animatable {
    /// Required: Calculate and return the size of the composite view
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGSize
    
    /// Required: Position each subview
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    )
    
    /// Optional: Create a cache for layout calculations
    associatedtype Cache = Void
    func makeCache(subviews: Subviews) -> Cache
    func updateCache(_ cache: inout Cache, subviews: Subviews)
    
    /// Optional: Provide spacing preferences
    func spacing(subviews: Subviews, cache: inout Cache) -> ViewSpacing
    
    /// Optional: Provide explicit alignment guides
    func explicitAlignment(
        of guide: HorizontalAlignment,
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGFloat?
    
    func explicitAlignment(
        of guide: VerticalAlignment,
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGFloat?
}
```

### Key Concepts

**ProposedViewSize**: The size the parent is suggesting for your layout
- Can be `.infinity` in one or both dimensions
- Can be `.zero` for "ideal size"
- Can be a specific size

**Subviews**: A proxy collection representing the child views
- Access view properties without rendering
- Query size requirements
- Position views

**Cache**: Optional storage for expensive calculations
- Computed once, reused across layout passes
- Invalidated when subviews change

---

## Core Protocol Requirements

### 1. sizeThatFits(proposal:subviews:cache:)

This method calculates the total size your layout needs. It's called before `placeSubviews`.

```swift
func sizeThatFits(
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout Cache
) -> CGSize {
    // Return the size your layout needs
    // Consider the proposal and subview requirements
}
```

**Key Points:**
- Called multiple times during layout
- Should respect the proposal when reasonable
- Don't actually position views here (that's for placeSubviews)

### 2. placeSubviews(in:proposal:subviews:cache:)

This method positions each subview within the provided bounds.

```swift
func placeSubviews(
    in bounds: CGRect,
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout Cache
) {
    // Position each subview using subview.place(at:anchor:proposal:)
}
```

**Key Points:**
- Called after sizeThatFits
- Use `subview.place(at:anchor:proposal:)` to position each view
- The `anchor` parameter determines the reference point (default: .topLeading)

---

## Building Your First Custom Layout

Let's create a simple horizontal flow layout that wraps views to multiple lines.

### Example 1: Basic Flow Layout

```swift
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        
        for (index, subview) in subviews.enumerated() {
            let position = result.positions[index]
            subview.place(
                at: CGPoint(
                    x: bounds.minX + position.x,
                    y: bounds.minY + position.y
                ),
                anchor: .topLeading,
                proposal: ProposedViewSize(result.sizes[index])
            )
        }
    }
    
    // Helper structure to calculate layout
    struct FlowResult {
        var positions: [CGPoint] = []
        var sizes: [CGSize] = []
        var size: CGSize = .zero
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                // Check if we need to wrap to next line
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: currentX, y: currentY))
                sizes.append(size)
                
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
                
                // Update total size
                self.size.width = max(self.size.width, currentX - spacing)
                self.size.height = currentY + lineHeight
            }
        }
    }
}

// Usage
struct FlowLayoutExample: View {
    let items = ["Swift", "SwiftUI", "Layout", "Protocol", "Custom", "Views", "iOS", "macOS"]
    
    var body: some View {
        FlowLayout(spacing: 12) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(20)
            }
        }
        .padding()
    }
}
```

### Example 2: Radial Layout

A layout that arranges views in a circle.

```swift
struct RadialLayout: Layout {
    var radius: CGFloat = 100
    
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGSize {
        // Need space for the circle plus subview sizes
        let maxSubviewSize = subviews.map { 
            $0.sizeThatFits(.unspecified) 
        }.reduce(CGSize.zero) { current, size in
            CGSize(
                width: max(current.width, size.width),
                height: max(current.height, size.height)
            )
        }
        
        let diameter = radius * 2 + max(maxSubviewSize.width, maxSubviewSize.height)
        return CGSize(width: diameter, height: diameter)
    }
    
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let angleStep = (2 * .pi) / Double(subviews.count)
        
        for (index, subview) in subviews.enumerated() {
            let angle = angleStep * Double(index) - .pi / 2 // Start at top
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
struct RadialLayoutExample: View {
    var body: some View {
        RadialLayout(radius: 120) {
            ForEach(1...8, id: \.self) { number in
                Circle()
                    .fill(Color.blue)
                    .frame(width: 50, height: 50)
                    .overlay(Text("\(number)").foregroundColor(.white))
            }
        }
        .frame(width: 400, height: 400)
        .background(Color.gray.opacity(0.1))
    }
}
```

---

## Advanced Layout Techniques

### Working with Layout Values

You can attach custom data to views that your layout can read using layout values.

```swift
// Define a custom layout value key
private struct PriorityKey: LayoutValueKey {
    static let defaultValue: Double = 0
}

extension View {
    func layoutPriority(_ value: Double) -> some View {
        layoutValue(key: PriorityKey.self, value: value)
    }
}

// Use in a custom layout
struct PriorityLayout: Layout {
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGSize {
        let priorities = subviews.map { $0[PriorityKey.self] }
        // Use priorities to influence sizing...
        
        return proposal.replacingUnspecifiedDimensions()
    }
    
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) {
        let priorities = subviews.map { $0[PriorityKey.self] }
        var x: CGFloat = bounds.minX
        
        // Sort by priority for placement
        let sortedIndices = subviews.indices.sorted { 
            priorities[$0] > priorities[$1] 
        }
        
        for index in sortedIndices {
            let subview = subviews[index]
            let size = subview.sizeThatFits(.unspecified)
            
            subview.place(
                at: CGPoint(x: x, y: bounds.midY),
                anchor: .leading,
                proposal: ProposedViewSize(size)
            )
            
            x += size.width + 10
        }
    }
}

// Usage
PriorityLayout {
    Text("High").layoutPriority(3)
    Text("Low").layoutPriority(1)
    Text("Medium").layoutPriority(2)
}
```

### Flexible Spacing

Implement the `spacing` method to provide custom spacing between views.

```swift
struct CustomSpacingLayout: Layout {
    func spacing(subviews: Subviews, cache: inout Cache) -> ViewSpacing {
        // Provide custom spacing for each edge
        ViewSpacing(
            leading: 10,
            trailing: 10,
            top: 5,
            bottom: 5
        )
    }
    
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGSize {
        // Calculate size considering custom spacing
        var width: CGFloat = 0
        var height: CGFloat = 0
        
        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            width += size.width
            height = max(height, size.height)
            
            if index < subviews.count - 1 {
                width += subview.spacing.distance(
                    to: subviews[index + 1].spacing,
                    along: .horizontal
                )
            }
        }
        
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) {
        var x = bounds.minX
        
        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            
            subview.place(
                at: CGPoint(x: x, y: bounds.midY),
                anchor: .leading,
                proposal: ProposedViewSize(size)
            )
            
            x += size.width
            
            if index < subviews.count - 1 {
                x += subview.spacing.distance(
                    to: subviews[index + 1].spacing,
                    along: .horizontal
                )
            }
        }
    }
}
```

---

## Layout Caching and Performance

For complex layouts with expensive calculations, implement caching.

```swift
struct EfficientGridLayout: Layout {
    let columns: Int
    let spacing: CGFloat
    
    struct CacheData {
        var columnWidths: [CGFloat] = []
        var rowHeights: [CGFloat] = []
        var positions: [CGPoint] = []
    }
    
    func makeCache(subviews: Subviews) -> CacheData {
        return CacheData()
    }
    
    func updateCache(_ cache: inout CacheData, subviews: Subviews) {
        // Calculate expensive layout data once
        let rows = (subviews.count + columns - 1) / columns
        
        cache.columnWidths = Array(repeating: 0, count: columns)
        cache.rowHeights = Array(repeating: 0, count: rows)
        cache.positions = []
        
        // Calculate maximum width for each column
        for (index, subview) in subviews.enumerated() {
            let column = index % columns
            let size = subview.sizeThatFits(.unspecified)
            cache.columnWidths[column] = max(cache.columnWidths[column], size.width)
        }
        
        // Calculate maximum height for each row
        for (index, subview) in subviews.enumerated() {
            let row = index / columns
            let size = subview.sizeThatFits(.unspecified)
            cache.rowHeights[row] = max(cache.rowHeights[row], size.height)
        }
        
        // Calculate positions
        var y: CGFloat = 0
        for row in 0..<rows {
            var x: CGFloat = 0
            for column in 0..<columns {
                let index = row * columns + column
                if index < subviews.count {
                    cache.positions.append(CGPoint(x: x, y: y))
                }
                x += cache.columnWidths[column] + spacing
            }
            y += cache.rowHeights[row] + spacing
        }
    }
    
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout CacheData
    ) -> CGSize {
        let width = cache.columnWidths.reduce(0, +) + spacing * CGFloat(columns - 1)
        let height = cache.rowHeights.reduce(0, +) + spacing * CGFloat(cache.rowHeights.count - 1)
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout CacheData
    ) {
        for (index, subview) in subviews.enumerated() {
            let position = cache.positions[index]
            let row = index / columns
            let column = index % columns
            
            subview.place(
                at: CGPoint(
                    x: bounds.minX + position.x,
                    y: bounds.minY + position.y
                ),
                anchor: .topLeading,
                proposal: ProposedViewSize(
                    width: cache.columnWidths[column],
                    height: cache.rowHeights[row]
                )
            )
        }
    }
}

// Usage
struct GridExample: View {
    var body: some View {
        EfficientGridLayout(columns: 3, spacing: 12) {
            ForEach(1...12, id: \.self) { number in
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue)
                    .overlay(Text("\(number)").foregroundColor(.white))
                    .frame(width: 80, height: 80)
            }
        }
        .padding()
    }
}
```

---

## Real-World Examples

### Example 1: Masonry Layout

A Pinterest-style masonry layout with variable height items.

```swift
struct MasonryLayout: Layout {
    var columns: Int = 2
    var spacing: CGFloat = 8
    
    struct CacheData {
        var columnHeights: [CGFloat]
        var itemFrames: [CGRect]
        
        init(columns: Int) {
            self.columnHeights = Array(repeating: 0, count: columns)
            self.itemFrames = []
        }
    }
    
    func makeCache(subviews: Subviews) -> CacheData {
        return CacheData(columns: columns)
    }
    
    func updateCache(_ cache: inout CacheData, subviews: Subviews) {
        cache.columnHeights = Array(repeating: 0, count: columns)
        cache.itemFrames = []
        
        guard !subviews.isEmpty else { return }
        
        // Get max available width from first layout pass
        let totalSpacing = spacing * CGFloat(columns - 1)
        let columnWidth: CGFloat = 100 // Default, will be recalculated in sizeThatFits
        
        for subview in subviews {
            // Find shortest column
            let shortestColumnIndex = cache.columnHeights.indices.min(by: { 
                cache.columnHeights[$0] < cache.columnHeights[$1] 
            }) ?? 0
            
            let size = subview.sizeThatFits(
                ProposedViewSize(width: columnWidth, height: nil)
            )
            
            let x = CGFloat(shortestColumnIndex) * (columnWidth + spacing)
            let y = cache.columnHeights[shortestColumnIndex]
            
            cache.itemFrames.append(CGRect(
                x: x,
                y: y,
                width: columnWidth,
                height: size.height
            ))
            
            cache.columnHeights[shortestColumnIndex] += size.height + spacing
        }
    }
    
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout CacheData
    ) -> CGSize {
        let width = proposal.replacingUnspecifiedDimensions().width
        let totalSpacing = spacing * CGFloat(columns - 1)
        let columnWidth = (width - totalSpacing) / CGFloat(columns)
        
        // Recalculate with actual column width
        cache.columnHeights = Array(repeating: 0, count: columns)
        cache.itemFrames = []
        
        for subview in subviews {
            let shortestColumnIndex = cache.columnHeights.indices.min(by: { 
                cache.columnHeights[$0] < cache.columnHeights[$1] 
            }) ?? 0
            
            let size = subview.sizeThatFits(
                ProposedViewSize(width: columnWidth, height: nil)
            )
            
            let x = CGFloat(shortestColumnIndex) * (columnWidth + spacing)
            let y = cache.columnHeights[shortestColumnIndex]
            
            cache.itemFrames.append(CGRect(
                x: x,
                y: y,
                width: columnWidth,
                height: size.height
            ))
            
            cache.columnHeights[shortestColumnIndex] += size.height + spacing
        }
        
        let maxHeight = cache.columnHeights.max() ?? 0
        return CGSize(width: width, height: maxHeight)
    }
    
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout CacheData
    ) {
        for (index, subview) in subviews.enumerated() {
            let frame = cache.itemFrames[index]
            subview.place(
                at: CGPoint(
                    x: bounds.minX + frame.minX,
                    y: bounds.minY + frame.minY
                ),
                anchor: .topLeading,
                proposal: ProposedViewSize(frame.size)
            )
        }
    }
}

// Usage
struct MasonryExample: View {
    let colors: [Color] = [.red, .blue, .green, .orange, .purple, .pink]
    let heights: [CGFloat] = [100, 150, 120, 180, 90, 200, 110, 160]
    
    var body: some View {
        ScrollView {
            MasonryLayout(columns: 2, spacing: 12) {
                ForEach(0..<heights.count, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colors[index % colors.count])
                        .frame(height: heights[index])
                        .overlay(
                            Text("Item \(index + 1)")
                                .foregroundColor(.white)
                                .font(.headline)
                        )
                }
            }
            .padding()
        }
    }
}
```

### Example 2: Animated Layout Switching

Layouts can be animated when switched between different types.

```swift
struct SwitchableLayout: View {
    @State private var useGrid = false
    
    var body: some View {
        VStack {
            Button("Toggle Layout") {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    useGrid.toggle()
                }
            }
            .padding()
            
            // Using AnyLayout for dynamic layout switching
            let layout = useGrid ? 
                AnyLayout(EfficientGridLayout(columns: 3, spacing: 12)) : 
                AnyLayout(FlowLayout(spacing: 12))
            
            layout {
                ForEach(1...12, id: \.self) { number in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue)
                        .frame(width: 80, height: 80)
                        .overlay(Text("\(number)").foregroundColor(.white))
                }
            }
            .padding()
        }
    }
}
```

### Example 3: Responsive Layout

A layout that adapts based on available space.

```swift
struct ResponsiveLayout: Layout {
    var minItemWidth: CGFloat = 100
    var spacing: CGFloat = 10
    
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGSize {
        let width = proposal.replacingUnspecifiedDimensions().width
        let columns = max(1, Int(width / (minItemWidth + spacing)))
        let columnWidth = (width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
        
        var height: CGFloat = 0
        var currentRowHeight: CGFloat = 0
        var itemsInCurrentRow = 0
        
        for subview in subviews {
            if itemsInCurrentRow >= columns {
                height += currentRowHeight + spacing
                currentRowHeight = 0
                itemsInCurrentRow = 0
            }
            
            let size = subview.sizeThatFits(
                ProposedViewSize(width: columnWidth, height: nil)
            )
            currentRowHeight = max(currentRowHeight, size.height)
            itemsInCurrentRow += 1
        }
        
        height += currentRowHeight
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) {
        let columns = max(1, Int(bounds.width / (minItemWidth + spacing)))
        let columnWidth = (bounds.width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
        
        var x = bounds.minX
        var y = bounds.minY
        var currentRowHeight: CGFloat = 0
        
        for (index, subview) in subviews.enumerated() {
            if index > 0 && index % columns == 0 {
                x = bounds.minX
                y += currentRowHeight + spacing
                currentRowHeight = 0
            }
            
            let size = subview.sizeThatFits(
                ProposedViewSize(width: columnWidth, height: nil)
            )
            
            subview.place(
                at: CGPoint(x: x, y: y),
                anchor: .topLeading,
                proposal: ProposedViewSize(width: columnWidth, height: size.height)
            )
            
            currentRowHeight = max(currentRowHeight, size.height)
            x += columnWidth + spacing
        }
    }
}
```

---

## Best Practices

### 1. Performance Optimization

```swift
// ✅ Good: Use caching for expensive calculations
struct OptimizedLayout: Layout {
    struct CacheData {
        var calculatedSizes: [CGSize] = []
    }
    
    func updateCache(_ cache: inout CacheData, subviews: Subviews) {
        cache.calculatedSizes = subviews.map { $0.sizeThatFits(.unspecified) }
    }
    
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout CacheData
    ) -> CGSize {
        // Use cached sizes instead of recalculating
        let totalWidth = cache.calculatedSizes.reduce(0) { $0 + $1.width }
        // ...
        return CGSize(width: totalWidth, height: 100)
    }
}

// ❌ Bad: Recalculate sizes multiple times
struct UnoptimizedLayout: Layout {
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGSize {
        // This recalculates every time!
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        // ...
        return CGSize(width: 0, height: 0)
    }
    
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) {
        // Recalculating again!
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        // ...
    }
}
```

### 2. Handle Edge Cases

```swift
func sizeThatFits(
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout Cache
) -> CGSize {
    // ✅ Good: Handle empty subviews
    guard !subviews.isEmpty else {
        return .zero
    }
    
    // ✅ Good: Handle infinite proposals
    let width = proposal.width ?? 300 // Provide reasonable default
    let height = proposal.height ?? 300
    
    // ✅ Good: Handle zero proposals
    if proposal == .zero {
        // Return ideal size
        return calculateIdealSize(subviews: subviews)
    }
    
    // Calculate actual size...
    return CGSize(width: width, height: height)
}
```

### 3. Use Semantic Anchors

```swift
// ✅ Good: Use semantic anchor points
func placeSubviews(
    in bounds: CGRect,
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout Cache
) {
    for subview in subviews {
        // Center alignment makes sense for this layout
        subview.place(
            at: CGPoint(x: bounds.midX, y: bounds.midY),
            anchor: .center,
            proposal: .unspecified
        )
    }
}

// Consider these anchor options based on your layout:
// - .topLeading: For left-to-right, top-to-bottom layouts
// - .center: For centered or radial layouts
// - .bottom: For layouts that grow upward
```

### 4. Respect Proposal Sizes

```swift
// ✅ Good: Respect parent's size proposal
func sizeThatFits(
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout Cache
) -> CGSize {
    let maxWidth = proposal.width ?? .infinity
    
    // Ensure we don't exceed the proposed width
    let calculatedWidth = calculateIdealWidth(subviews: subviews)
    let finalWidth = min(calculatedWidth, maxWidth)
    
    return CGSize(width: finalWidth, height: 100)
}
```

### 5. Make Layouts Configurable

```swift
// ✅ Good: Parameterize layout behavior
struct FlexibleLayout: Layout {
    var spacing: CGFloat = 8
    var alignment: Alignment = .center
    var distribution: Distribution = .equalSpacing
    
    enum Distribution {
        case equalSpacing
        case equalSize
        case natural
    }
    
    // Implementation uses these parameters...
}

// Usage is clear and flexible
FlexibleLayout(spacing: 12, alignment: .leading, distribution: .equalSize) {
    // Content
}
```

### 6. Test with Various Content

```swift
// Test your layouts with:
// - Empty content
// - Single item
// - Many items
// - Items of varying sizes
// - Very large items
// - Very small items
struct LayoutTester: View {
    var body: some View {
        VStack {
            // Empty
            CustomLayout { }
            
            // Single item
            CustomLayout {
                Text("One")
            }
            
            // Many items
            CustomLayout {
                ForEach(1...20, id: \.self) { i in
                    Text("Item \(i)")
                }
            }
            
            // Varying sizes
            CustomLayout {
                Text("Short")
                Text("Much longer text here")
                Text("Medium")
            }
        }
    }
}
```

---

## Common Patterns and Recipes

### Pattern 1: Two-Pass Layout

Many layouts need two passes: one to gather information, one to position.

```swift
struct TwoPassLayout: Layout {
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGSize {
        // First pass: gather all sizes
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        
        // Second pass: calculate layout based on gathered info
        // ...
        
        return CGSize(width: 100, height: 100)
    }
}
```

### Pattern 2: Proportional Distribution

Distribute space proportionally based on view preferences.

```swift
private struct ProportionKey: LayoutValueKey {
    static let defaultValue: Double = 1.0
}

extension View {
    func proportion(_ value: Double) -> some View {
        layoutValue(key: ProportionKey.self, value: value)
    }
}

struct ProportionalLayout: Layout {
    var axis: Axis = .horizontal
    
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) {
        let proportions = subviews.map { $0[ProportionKey.self] }
        let totalProportion = proportions.reduce(0, +)
        
        let availableSpace = axis == .horizontal ? bounds.width : bounds.height
        var offset: CGFloat = 0
        
        for (index, subview) in subviews.enumerated() {
            let proportion = proportions[index]
            let size = availableSpace * (proportion / totalProportion)
            
            if axis == .horizontal {
                subview.place(
                    at: CGPoint(x: bounds.minX + offset, y: bounds.minY),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(width: size, height: bounds.height)
                )
                offset += size
            } else {
                subview.place(
                    at: CGPoint(x: bounds.minX, y: bounds.minY + offset),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(width: bounds.width, height: size)
                )
                offset += size
            }
        }
    }
    
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGSize {
        return proposal.replacingUnspecifiedDimensions()
    }
}

// Usage
ProportionalLayout(axis: .horizontal) {
    Color.red.proportion(1)
    Color.blue.proportion(2)
    Color.green.proportion(1)
}
```

---

## Debugging Tips

### 1. Visualize Layout Calculations

```swift
struct DebugLayout: Layout {
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) {
        print("📐 Layout bounds: \(bounds)")
        print("📏 Proposal: \(proposal)")
        print("👶 Subview count: \(subviews.count)")
        
        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            print("  View \(index): wants \(size)")
            
            // Position subview...
        }
    }
}
```

### 2. Add Visual Debugging

```swift
struct DebugLayoutView: View {
    @State private var showDebugInfo = false
    
    var body: some View {
        ZStack {
            CustomLayout {
                // Your content
            }
            
            if showDebugInfo {
                // Overlay with debug info
                Rectangle()
                    .stroke(Color.red, lineWidth: 2)
                    .overlay(
                        Text("Layout bounds")
                            .background(Color.white)
                    )
            }
        }
        .onTapGesture {
            showDebugInfo.toggle()
        }
    }
}
```

---

## Conclusion

The Layout protocol is a powerful tool for creating custom layouts in SwiftUI. Key takeaways:

1. **Implement both required methods**: `sizeThatFits` and `placeSubviews`
2. **Use caching** for expensive calculations
3. **Handle edge cases**: empty content, infinite proposals, zero proposals
4. **Test thoroughly** with various content sizes and quantities
5. **Make layouts flexible** with parameters
6. **Respect proposals** from parent views
7. **Use semantic anchors** for positioning

With these principles and examples, you can create sophisticated, performant custom layouts that integrate seamlessly with SwiftUI's layout system.

---

## Additional Resources

- Apple's Layout Protocol Documentation
- WWDC 2022: "Compose custom layouts with SwiftUI"
- SwiftUI Layout System Deep Dive
- Custom Layout Examples on GitHub

Happy layouting! 🎨
