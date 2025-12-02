# SwiftUI View Modifiers Cheatsheet

## Overview

View modifiers are methods that transform views, returning modified versions. They're the primary way to configure appearance, behavior, and layout in SwiftUI. Modifiers can be chained, and order often matters.

---

## Core Concepts

### How Modifiers Work

```swift
// Each modifier returns a new view
Text("Hello")
    .font(.title)           // Returns ModifiedContent<Text, _FontModifier>
    .foregroundColor(.blue) // Returns ModifiedContent<ModifiedContent<...>, _ColorModifier>
    .padding()              // And so on...
```

**Key Principles**:
- Modifiers return a new view, not modify in place
- Order matters - applied sequentially
- Each modifier wraps the previous view
- Modifiers apply to the view and its children (unless overridden)

### Modifier Order Example

```swift
// Background after padding
Text("Hello")
    .padding()           // Add space around text
    .background(.blue)   // Blue background includes padding

// Background before padding  
Text("Hello")
    .background(.blue)   // Blue background only behind text
    .padding()           // Padding is outside blue background
```

---

## Layout Modifiers

### Frame & Size

```swift
// Fixed size
Text("Fixed")
    .frame(width: 200, height: 100)

// Flexible size with constraints
Rectangle()
    .frame(minWidth: 100, maxWidth: 300, minHeight: 50, maxHeight: 200)

// Alignment within frame
Text("Top Leading")
    .frame(width: 200, height: 100, alignment: .topLeading)

// Ideal size (no constraints)
Text("Ideal")
    .frame(idealWidth: 200, idealHeight: 100)

// Fixed size (prevent compression)
Text("This text will not wrap")
    .fixedSize()

// Fixed in one dimension only
Text("This text will wrap but won't compress height")
    .fixedSize(horizontal: false, vertical: true)
```

### Padding

```swift
// Uniform padding
Text("Padded").padding()               // Default (16pt)
Text("Custom").padding(20)             // All sides

// Specific edges
Text("Top").padding(.top, 20)
Text("Horizontal").padding(.horizontal, 30)
Text("Leading & Bottom").padding([.leading, .bottom], 15)

// Edge insets
Text("Custom Insets")
    .padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
```

### Offset

```swift
// Offset position (doesn't affect layout)
Circle()
    .offset(x: 20, y: 30)

// Offset with CGSize
Circle()
    .offset(CGSize(width: 20, height: 30))

// Animated offset
@State private var offset: CGFloat = 0

Circle()
    .offset(x: offset)
    .onAppear {
        withAnimation {
            offset = 100
        }
    }
```

### Position

```swift
// Absolute positioning
Circle()
    .position(x: 100, y: 100)

// Position with CGPoint
Circle()
    .position(CGPoint(x: 100, y: 100))
```

### Alignment & Spacing

```swift
// Container alignment
VStack(alignment: .leading, spacing: 20) {
    Text("Line 1")
    Text("Line 2")
}

// Alignment guide
Text("Custom Alignment")
    .alignmentGuide(.leading) { d in d[.leading] + 20 }

// Spacing
Text("Above")
    .padding(.bottom, 20)  // Space after
Text("Below")
    .padding(.top, 10)     // Space before
```

### Layout Priority

```swift
HStack {
    Text("High priority expands")
        .layoutPriority(1)
    
    Text("Low priority compresses")
        .layoutPriority(0)
}
```

---

## Appearance Modifiers

### Colors & Backgrounds

```swift
// Foreground color
Text("Red").foregroundColor(.red)
Text("Custom").foregroundColor(Color(hex: "#FF5733"))

// Foreground style (iOS 15+)
Text("Gradient")
    .foregroundStyle(.linearGradient(
        colors: [.red, .blue],
        startPoint: .leading,
        endPoint: .trailing
    ))

// Background
Text("Blue Background")
    .background(.blue)

// Complex background
Text("Gradient Background")
    .background(
        LinearGradient(
            colors: [.red, .blue],
            startPoint: .top,
            endPoint: .bottom
        )
    )

// Background with alignment
Text("Top-aligned background")
    .background(alignment: .top) {
        Circle().fill(.blue)
    }

// Tint color (affects interactive elements)
Button("Tinted") { }
    .tint(.purple)
```

### Borders & Strokes

```swift
// Border
Rectangle()
    .border(.blue, width: 2)

// Stroke
Circle()
    .stroke(.red, lineWidth: 3)

// Stroke with style
Circle()
    .stroke(.blue, style: StrokeStyle(
        lineWidth: 4,
        lineCap: .round,
        lineJoin: .miter,
        dash: [10, 5]
    ))

// Overlay with stroke
Rectangle()
    .fill(.white)
    .overlay(
        RoundedRectangle(cornerRadius: 10)
            .stroke(.blue, lineWidth: 2)
    )
```

### Overlays & Backgrounds

```swift
// Simple overlay
Circle()
    .fill(.blue)
    .overlay(Text("Hello"))

// Overlay with alignment
Rectangle()
    .overlay(alignment: .topLeading) {
        Image(systemName: "star.fill")
            .foregroundColor(.yellow)
    }

// Multiple overlays stack
Circle()
    .overlay { Text("1") }
    .overlay { Text("2").offset(y: 20) }

// Background layers
Text("Layered")
    .background { Color.blue }
    .background { Color.red.padding(5) }
```

### Shadows & Blur

```swift
// Drop shadow
Text("Shadow")
    .shadow(color: .black.opacity(0.3), radius: 5, x: 2, y: 2)

// Multiple shadows
Rectangle()
    .shadow(radius: 5)
    .shadow(color: .blue, radius: 10, x: 5, y: 5)

// Blur
Image("photo")
    .blur(radius: 5)

// Conditional blur
Image("sensitive")
    .blur(radius: isBlurred ? 10 : 0)
```

### Opacity

```swift
// Fixed opacity
Text("Semi-transparent")
    .opacity(0.5)

// Animated opacity
@State private var isVisible = false

Text("Fade In")
    .opacity(isVisible ? 1 : 0)
    .animation(.easeIn, value: isVisible)
```

### Clipping & Masking

```swift
// Clip to shape
Image("photo")
    .clipShape(Circle())

// Clip with specific shape
Text("Rounded")
    .padding()
    .background(.blue)
    .clipShape(RoundedRectangle(cornerRadius: 10))

// Mask with view
Rectangle()
    .fill(.blue)
    .mask {
        Text("MASKED")
            .font(.system(size: 80, weight: .bold))
    }

// Corner radius (convenience)
Rectangle()
    .fill(.blue)
    .cornerRadius(10)
```

### Rotation, Scale, and 3D

```swift
// Rotation
Text("Rotated")
    .rotationEffect(.degrees(45))

// Rotation with anchor
Rectangle()
    .rotationEffect(.degrees(45), anchor: .topLeading)

// 3D rotation
Text("3D")
    .rotation3DEffect(.degrees(45), axis: (x: 1, y: 0, z: 0))

// Scale
Circle()
    .scaleEffect(1.5)

// Scale with anchor
Rectangle()
    .scaleEffect(2.0, anchor: .topLeading)

// Non-uniform scale
Rectangle()
    .scaleEffect(x: 2, y: 0.5)
```

---

## Typography Modifiers

### Font

```swift
// System fonts
Text("Title").font(.title)
Text("Large Title").font(.largeTitle)
Text("Headline").font(.headline)
Text("Body").font(.body)
Text("Caption").font(.caption)
Text("Footnote").font(.footnote)

// Custom size
Text("Custom").font(.system(size: 24))

// With weight
Text("Bold").font(.system(size: 20, weight: .bold))

// With design
Text("Monospaced").font(.system(size: 16, design: .monospaced))
Text("Rounded").font(.system(size: 16, design: .rounded))
Text("Serif").font(.system(size: 16, design: .serif))

// Custom font
Text("Custom Font").font(.custom("Helvetica", size: 18))

// Dynamic type
Text("Scalable").font(.system(.body, design: .rounded))
```

### Text Modifiers

```swift
// Weight
Text("Bold").bold()
Text("Semibold").fontWeight(.semibold)

// Italic
Text("Italic").italic()

// Underline
Text("Underline").underline()
Text("Custom underline").underline(color: .red)

// Strikethrough
Text("Crossed").strikethrough()
Text("Custom strike").strikethrough(color: .blue)

// Kerning (letter spacing)
Text("Spaced").kerning(2)

// Tracking
Text("Tracked").tracking(5)

// Baseline offset
Text("Super").baselineOffset(10) + Text("script")

// Multi-line text alignment
Text("Multiple\nLines\nAligned")
    .multilineTextAlignment(.center)

// Line limit
Text("Long text that might wrap")
    .lineLimit(2)

// Line spacing
Text("Line 1\nLine 2\nLine 3")
    .lineSpacing(10)

// Minimum scale factor
Text("This will scale down if needed")
    .minimumScaleFactor(0.5)

// Allows tightening
Text("Tight text")
    .allowsTightening(true)

// Truncation mode
Text("This is a very long text")
    .lineLimit(1)
    .truncationMode(.middle)
```

---

## Interaction Modifiers

### Gestures

```swift
// Tap gesture
Text("Tap me")
    .onTapGesture {
        print("Tapped")
    }

// Long press
Text("Long press")
    .onLongPressGesture {
        print("Long pressed")
    }

// Long press with minimum duration
Text("Custom duration")
    .onLongPressGesture(minimumDuration: 2.0) {
        print("Pressed for 2 seconds")
    }

// Gesture modifier
Circle()
    .gesture(
        DragGesture()
            .onChanged { value in
                print("Dragging: \(value.translation)")
            }
            .onEnded { value in
                print("Drag ended")
            }
    )

// High priority gesture
Text("High priority tap")
    .highPriorityGesture(TapGesture())

// Simultaneous gesture
Circle()
    .simultaneousGesture(TapGesture())
```

### Buttons & Forms

```swift
// Button style
Button("Styled") { }
    .buttonStyle(.bordered)
    .buttonStyle(.borderedProminent)
    .buttonStyle(.borderless)

// Control size
Button("Large") { }
    .controlSize(.large)

// Disabled state
Button("Submit") { }
    .disabled(isFormInvalid)

// Keyboard shortcuts
Button("Save") { }
    .keyboardShortcut("s", modifiers: .command)
```

### Focus & Navigation

```swift
// Focused
TextField("Name", text: $name)
    .focused($focusedField, equals: .name)

// Default focus
TextField("Search", text: $search)
    .defaultFocus($focusedField, .search)

// Submit label
TextField("Email", text: $email)
    .submitLabel(.done)

// On submit
TextField("Username", text: $username)
    .onSubmit {
        submitForm()
    }

// Autocorrection
TextField("Text", text: $text)
    .autocorrectionDisabled()

// Text input autocapitalization
TextField("City", text: $city)
    .textInputAutocapitalization(.words)
```

### Scrolling

```swift
// Scroll disabled
ScrollView {
    content
}
.scrollDisabled(true)

// Scroll indicators
ScrollView {
    content
}
.scrollIndicators(.hidden)

// Scroll position (iOS 17+)
ScrollView {
    content
}
.scrollPosition(id: $scrollPosition)

// Scroll target behavior (iOS 17+)
ScrollView {
    content
}
.scrollTargetBehavior(.paging)
```

---

## Animation Modifiers

### Basic Animation

```swift
// Implicit animation
Text("Animated")
    .animation(.default, value: someValue)

// Explicit animation (in action)
Button("Animate") {
    withAnimation {
        someValue.toggle()
    }
}

// Animation curves
.animation(.linear, value: value)
.animation(.easeIn, value: value)
.animation(.easeOut, value: value)
.animation(.easeInOut, value: value)

// Spring animation
.animation(.spring(response: 0.5, dampingFraction: 0.7), value: value)

// Custom timing
.animation(.easeIn(duration: 2.0), value: value)

// Animation with delay
.animation(.default.delay(0.5), value: value)

// Repeated animation
.animation(.default.repeatCount(3), value: value)
.animation(.default.repeatForever(), value: value)
```

### Transition Modifiers

```swift
// Transition
if showView {
    Text("Hello")
        .transition(.scale)
}

// Combined transitions
.transition(.scale.combined(with: .opacity))

// Asymmetric transitions
.transition(.asymmetric(
    insertion: .move(edge: .leading),
    removal: .move(edge: .trailing)
))

// Custom transition
.transition(.modifier(
    active: ScaleModifier(scale: 0),
    identity: ScaleModifier(scale: 1)
))

// Match geometry effect
Circle()
    .matchedGeometryEffect(id: "circle", in: namespace)
```

---

## Environment Modifiers

### Environment Values

```swift
// Color scheme
.environment(\.colorScheme, .dark)

// Size category
.environment(\.sizeCategory, .large)

// Locale
.environment(\.locale, Locale(identifier: "es"))

// Time zone
.environment(\.timeZone, TimeZone(identifier: "UTC")!)

// Layout direction
.environment(\.layoutDirection, .rightToLeft)

// Custom environment value
.environment(\.customKey, customValue)
```

### Preferred Modifiers

```swift
// Preferred color scheme
.preferredColorScheme(.dark)

// Preferred display mode
NavigationView {
    content
}
.navigationViewStyle(.stack)  // iPad: force stack instead of split
```

---

## Accessibility Modifiers

### Accessibility Labels

```swift
// Accessibility label
Image(systemName: "star")
    .accessibilityLabel("Favorite")

// Accessibility value
Slider(value: $volume)
    .accessibilityValue("\(Int(volume))%")

// Accessibility hint
Button("Submit") { }
    .accessibilityHint("Submits the form")

// Accessibility input labels
TextField("", text: $name)
    .accessibilityLabel("Full name")
```

### Accessibility Actions

```swift
// Custom actions
Text("Message")
    .accessibilityAction(named: "Reply") {
        reply()
    }
    .accessibilityAction(named: "Delete") {
        delete()
    }

// Accessibility element
HStack {
    Image(systemName: "star")
    Text("Favorite")
}
.accessibilityElement(children: .combine)

// Hidden from accessibility
Divider()
    .accessibilityHidden(true)
```

### Traits & Sorting

```swift
// Accessibility traits
Button("Play") { }
    .accessibilityAddTraits(.isButton)

Text("Error message")
    .accessibilityAddTraits(.isStaticText)

// Remove traits
Text("Not a header")
    .accessibilityRemoveTraits(.isHeader)

// Sort priority
VStack {
    Text("Read this second")
        .accessibilitySortPriority(1)
    Text("Read this first")
        .accessibilitySortPriority(2)
}
```

---

## Custom View Modifiers

### Creating Custom Modifiers

```swift
struct PrimaryButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(.blue)
            .cornerRadius(10)
    }
}

// Extension for convenience
extension View {
    func primaryButtonStyle() -> some View {
        modifier(PrimaryButtonStyle())
    }
}

// Usage
Text("Button")
    .primaryButtonStyle()
```

### Parameterized Modifiers

```swift
struct RoundedBorder: ViewModifier {
    let color: Color
    let width: CGFloat
    let radius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(color, lineWidth: width)
            )
    }
}

extension View {
    func roundedBorder(
        color: Color = .blue,
        width: CGFloat = 2,
        radius: CGFloat = 10
    ) -> some View {
        modifier(RoundedBorder(color: color, width: width, radius: radius))
    }
}

// Usage
Text("Bordered")
    .padding()
    .roundedBorder(color: .red, radius: 20)
```

### Conditional Modifiers

```swift
extension View {
    @ViewBuilder
    func `if`<Transform: View>(
        _ condition: Bool,
        transform: (Self) -> Transform
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// Usage
Text("Conditional")
    .if(isHighlighted) { view in
        view
            .foregroundColor(.red)
            .bold()
    }
```

### Environment-Aware Modifiers

```swift
struct AdaptivePadding: ViewModifier {
    @Environment(\.horizontalSizeClass) var sizeClass
    
    func body(content: Content) -> some View {
        content
            .padding(sizeClass == .compact ? 8 : 16)
    }
}

extension View {
    func adaptivePadding() -> some View {
        modifier(AdaptivePadding())
    }
}
```

---

## Composition Patterns

### Modifier Chains

```swift
// Building complex views
Text("Styled")
    .font(.title)
    .foregroundColor(.white)
    .padding()
    .background(.blue)
    .cornerRadius(10)
    .shadow(radius: 5)
```

### Extracted Modifiers

```swift
// Extract common styling
struct ContentView: View {
    var body: some View {
        VStack {
            card(content: "Card 1")
            card(content: "Card 2")
            card(content: "Card 3")
        }
    }
    
    func card(content: String) -> some View {
        Text(content)
            .cardStyle()
    }
}

extension View {
    func cardStyle() -> some View {
        self
            .padding()
            .background(.white)
            .cornerRadius(12)
            .shadow(radius: 3)
    }
}
```

### Modifier Groups

```swift
// Group related modifiers
extension View {
    func standardTextField() -> some View {
        self
            .textFieldStyle(.roundedBorder)
            .autocapitalization(.none)
            .autocorrectionDisabled()
            .submitLabel(.done)
    }
}

// Usage
TextField("Email", text: $email)
    .standardTextField()
```

---

## Performance Considerations

### Avoid Expensive Modifiers in Loops

```swift
// Bad: Creates many modified views
ForEach(items) { item in
    Text(item.name)
        .modifier(ExpensiveModifier())  // Applied to each
}

// Good: Apply once to container
VStack {
    ForEach(items) { item in
        Text(item.name)
    }
}
.modifier(ExpensiveModifier())  // Applied to VStack
```

### Preference Key Modifiers

```swift
// Send data up the view hierarchy
struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// Set preference
Text("Content")
    .background(GeometryReader { geometry in
        Color.clear.preference(
            key: HeightPreferenceKey.self,
            value: geometry.size.height
        )
    })

// Read preference
.onPreferenceChange(HeightPreferenceKey.self) { height in
    self.contentHeight = height
}
```

---

## Common Patterns & Best Practices

### 1. Order Matters

```swift
// Different results
Text("A")
    .padding()      // Padding then background
    .background(.blue)

Text("B")
    .background(.blue)  // Background then padding
    .padding()
```

### 2. Reusable Modifiers

```swift
// Create reusable styles
extension View {
    func errorStyle() -> some View {
        self
            .foregroundColor(.red)
            .font(.caption)
            .padding(4)
    }
}
```

### 3. Environment Propagation

```swift
// Modifiers flow down to children
VStack {
    Text("Inherits")
    Text("Blue color")
}
.foregroundColor(.blue)  // Both texts are blue
```

### 4. Conditional Application

```swift
@ViewBuilder
func conditionalModifier<Content: View>(
    _ condition: Bool,
    @ViewBuilder content: () -> Content
) -> some View {
    if condition {
        content().bold()
    } else {
        content()
    }
}
```

---

## Quick Reference

### Most Common Modifiers
- `.frame()` - Size and alignment
- `.padding()` - Spacing
- `.background()` - Background color/view
- `.foregroundColor()` / `.foregroundStyle()` - Text/icon color
- `.font()` - Typography
- `.bold()`, `.italic()` - Text styling
- `.cornerRadius()` - Rounded corners
- `.shadow()` - Drop shadow
- `.opacity()` - Transparency
- `.offset()` - Position adjustment
- `.overlay()` - Layer on top
- `.clipShape()` - Clip to shape
- `.onTapGesture()` - Tap handling
- `.disabled()` - Disable interaction
- `.animation()` - Animate changes

### Performance Tips
- Apply modifiers to containers when possible
- Extract repeated modifier chains
- Use `@ViewBuilder` for conditional modifiers
- Profile with Instruments for expensive modifiers

---

## Additional Resources

- [SwiftUI View Modifiers](https://developer.apple.com/documentation/swiftui/view-modifiers)
- [Custom View Modifiers](https://www.hackingwithswift.com/books/ios-swiftui/custom-modifiers)
- [Thinking in SwiftUI](https://www.objc.io/books/thinking-in-swiftui/)
