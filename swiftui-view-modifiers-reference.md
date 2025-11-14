# SwiftUI View Modifiers - Complete Reference

A comprehensive guide to all SwiftUI view modifiers, organized by functionality.

---

## Layout & Positioning

### `frame(width:height:alignment:)`
Positions the view within a specified frame size.

**Use:** Set explicit dimensions for a view.

**Pros:** Precise control over view sizing.

**Cons:** Can break dynamic layouts; overuse leads to rigid UIs.

**Alternatives:** Use `.fixedSize()` or container views like `HStack`/`VStack`.

**Issues:** Apply before padding/background for expected behavior. Order matters.

```swift
Text("Hello")
    .frame(width: 200, height: 100)
    .background(Color.blue) // Background respects frame
```

### `frame(minWidth:idealWidth:maxWidth:minHeight:idealHeight:maxHeight:alignment:)`
Sets flexible frame constraints.

**Use:** Create responsive layouts with size boundaries.

**Pros:** Adapts to content while respecting constraints.

**Cons:** Complex to understand all parameter interactions.

**Issues:** Use `maxWidth: .infinity` carefully as it expands to fill available space.

```swift
Text("Flexible")
    .frame(minWidth: 100, maxWidth: .infinity, minHeight: 50)
```

### `position(x:y:)`
Places the view at absolute coordinates in the parent.

**Use:** Precise positioning for custom layouts.

**Cons:** Breaks adaptive layouts; avoid for production UIs.

**Alternatives:** Use alignment guides or geometry readers.

**Issues:** Coordinates are from center of view, not top-left.

```swift
Text("Fixed")
    .position(x: 100, y: 100)
```

### `offset(x:y:)`
Moves the view by specified distances without affecting layout.

**Use:** Shift views for animations or fine positioning.

**Pros:** Doesn't impact other views' positions.

**Issues:** Apply after frame modifiers for predictable results.

```swift
Text("Shifted")
    .offset(x: 10, y: -5)
```

### `offset(_:)` (CGSize)
Moves view by a CGSize offset.

**Use:** Useful with calculated offsets or drag gestures.

```swift
Text("Draggable")
    .offset(dragOffset)
```

### `padding(_:)`
Adds spacing around the view.

**Use:** Essential for visual breathing room.

**Pros:** Most common spacing solution.

**Issues:** Apply before background to pad inside, after to pad outside.

```swift
Text("Padded")
    .padding()
    .background(Color.blue) // Padding inside background

Text("Padded")
    .background(Color.blue)
    .padding() // Padding outside background
```

### `padding(_:_:)` (edges, length)
Adds padding to specific edges.

**Use:** Asymmetric spacing control.

```swift
Text("Custom")
    .padding(.horizontal, 20)
    .padding(.top, 10)
```

### `padding(_:)` (EdgeInsets)
Adds padding using EdgeInsets.

```swift
Text("Insets")
    .padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
```

### `edgesIgnoringSafeArea(_:)`
Extends view into safe area.

**Use:** Full-bleed backgrounds or images.

**Cons:** Deprecated in iOS 14+.

**Alternatives:** Use `.ignoresSafeArea()`.

### `ignoresSafeArea(_:edges:)`
Extends view into safe area (modern API).

**Use:** Backgrounds, full-screen content.

**Issues:** Content may be obscured by notches/home indicators.

```swift
Color.blue
    .ignoresSafeArea()
```

### `safeAreaInset(edge:alignment:spacing:content:)`
Adds custom content in safe area.

**Use:** Floating buttons, toolbars that respect safe area.

**Pros:** Automatically adjusts layout for safe area.

```swift
ScrollView {
    // Content
}
.safeAreaInset(edge: .bottom) {
    Button("Action") { }
        .padding()
}
```

### `layoutPriority(_:)`
Sets priority for view in layout negotiation.

**Use:** Control which views get space first.

**Pros:** Prevents text truncation in competing layouts.

```swift
HStack {
    Text("Important")
        .layoutPriority(1)
    Text("Less important")
}
```

### `fixedSize(horizontal:vertical:)`
Prevents compression in specified axes.

**Use:** Maintain ideal size regardless of available space.

**Cons:** Can cause overflow or clipping.

```swift
Text("Long text that won't wrap")
    .fixedSize()
```

### `aspectRatio(_:contentMode:)`
Maintains aspect ratio with scaling mode.

**Use:** Images, videos maintaining proportions.

```swift
Image("photo")
    .resizable()
    .aspectRatio(16/9, contentMode: .fit)
```

### `aspectRatio(contentMode:)`
Maintains intrinsic aspect ratio.

```swift
Image("photo")
    .resizable()
    .aspectRatio(contentMode: .fill)
```

### `scaledToFit()`
Scales to fit within frame maintaining aspect ratio.

```swift
Image("photo")
    .resizable()
    .scaledToFit()
```

### `scaledToFill()`
Scales to fill frame maintaining aspect ratio.

```swift
Image("photo")
    .resizable()
    .scaledToFill()
    .frame(width: 200, height: 200)
    .clipped()
```

### `scaleEffect(_:anchor:)`
Scales the view uniformly.

**Use:** Animations, zoom effects.

**Issues:** Doesn't affect layout; view occupies original space.

```swift
Text("Big")
    .scaleEffect(2.0)
```

### `scaleEffect(x:y:anchor:)`
Scales independently on axes.

```swift
Rectangle()
    .scaleEffect(x: 2, y: 0.5)
```

### `scaleEffect(_:anchor:)` (CGSize)
Scales using CGSize.

```swift
Image(systemName: "heart")
    .scaleEffect(scaleValue)
```

---

## Alignment & Distribution

### `alignmentGuide(_:computeValue:)`
Customizes alignment for this view.

**Use:** Advanced custom layouts.

**Cons:** Complex; requires understanding alignment coordinates.

```swift
Text("Aligned")
    .alignmentGuide(.leading) { d in d[.leading] - 10 }
```

### `multilineTextAlignment(_:)`
Sets text alignment for multi-line text.

**Use:** Center, leading, or trailing text alignment.

**Issues:** Only affects Text views with multiple lines.

```swift
Text("Multiple\nLines")
    .multilineTextAlignment(.center)
```

### `flipsForRightToLeftLayoutDirection(_:)`
Mirrors view for RTL languages.

**Use:** Custom views that should flip for Arabic, Hebrew, etc.

```swift
Image(systemName: "arrow.right")
    .flipsForRightToLeftLayoutDirection(true)
```

### `coordinateSpace(name:)`
Names a coordinate space for geometry conversions.

**Use:** Advanced layout calculations with GeometryReader.

```swift
VStack {
    // content
}
.coordinateSpace(name: "container")
```

---

## Visual Styling

### `foregroundColor(_:)`
Sets foreground color (text, symbols).

**Use:** Coloring text and SF Symbols.

**Cons:** Deprecated in iOS 15+ for some contexts.

**Alternatives:** Use `.foregroundStyle()` in iOS 15+.

```swift
Text("Colored")
    .foregroundColor(.red)
```

### `foregroundStyle(_:)`
Sets foreground style with hierarchical support.

**Use:** Modern styling with materials, gradients.

**Pros:** Supports ShapeStyle protocol (colors, gradients, materials).

```swift
Text("Modern")
    .foregroundStyle(.blue)
```

### `foregroundStyle(_:_:)` (primary, secondary)
Sets hierarchical styles.

```swift
Label("Title", systemImage: "star")
    .foregroundStyle(.primary, .secondary)
```

### `foregroundStyle(_:_:_:)` (primary, secondary, tertiary)
Three-level style hierarchy.

```swift
// For complex layouts with three style levels
```

### `background(_:alignment:)`
Adds a view as background.

**Use:** Layer views behind content.

**Issues:** Apply after padding to include padding in background.

```swift
Text("Text")
    .padding()
    .background(Color.blue)
```

### `background(_:ignoresSafeAreaEdges:)`
Background with safe area control.

```swift
ScrollView {
    // content
}
.background(Color.gray, ignoresSafeAreaEdges: .all)
```

### `background(in:fillStyle:)`
Background with shape.

```swift
Text("Shaped")
    .padding()
    .background(in: RoundedRectangle(cornerRadius: 8))
```

### `background(_:in:fillStyle:)`
Background with style and shape.

```swift
Text("Custom")
    .padding()
    .background(.blue, in: Capsule())
```

### `overlay(_:alignment:)`
Adds a view as overlay.

**Use:** Layer views on top of content.

```swift
Image("photo")
    .overlay(
        Text("Caption")
            .padding()
            .background(.ultraThinMaterial),
        alignment: .bottom
    )
```

### `overlay(_:ignoresSafeAreaEdges:)`
Overlay with safe area control.

```swift
Color.clear
    .overlay(CustomView(), ignoresSafeAreaEdges: .all)
```

### `overlay(alignment:content:)`
Overlay with alignment closure.

```swift
Circle()
    .overlay(alignment: .topTrailing) {
        Badge()
    }
```

### `border(_:width:)`
Adds colored border.

**Use:** Simple rectangular borders.

**Cons:** Limited to rectangles.

**Alternatives:** Use `.overlay()` with shapes.

```swift
Text("Bordered")
    .border(Color.red, width: 2)
```

### `opacity(_:)`
Sets view transparency.

**Use:** Fade effects, disabled states.

```swift
Text("Faded")
    .opacity(0.5)
```

### `hidden()`
Hides the view while maintaining layout space.

**Use:** Conditional visibility preserving layout.

**Alternatives:** Use `if` conditions to remove from layout.

```swift
Text("Hidden")
    .hidden() // Space preserved
```

### `shadow(color:radius:x:y:)`
Adds drop shadow.

**Use:** Depth, elevation effects.

**Issues:** Performance impact with large radius values.

```swift
RoundedRectangle(cornerRadius: 10)
    .shadow(color: .gray, radius: 5, x: 0, y: 2)
```

### `blur(radius:opaque:)`
Applies gaussian blur.

**Use:** Backgrounds, depth effects.

**Cons:** Performance intensive; avoid on scrolling content.

```swift
Image("background")
    .blur(radius: 10)
```

### `brightness(_:)`
Adjusts brightness (-1 to 1).

```swift
Image("photo")
    .brightness(0.2)
```

### `contrast(_:)`
Adjusts contrast (0+).

```swift
Image("photo")
    .contrast(1.5)
```

### `saturation(_:)`
Adjusts color saturation (0+ where 0 is grayscale).

```swift
Image("photo")
    .saturation(0.5) // Desaturated
```

### `grayscale(_:)`
Applies grayscale effect (0 to 1).

```swift
Image("photo")
    .grayscale(1.0) // Full grayscale
```

### `hueRotation(_:)`
Rotates hue by angle.

```swift
Color.blue
    .hueRotation(Angle(degrees: 180))
```

### `colorInvert()`
Inverts colors.

```swift
Image("photo")
    .colorInvert()
```

### `colorMultiply(_:)`
Multiplies color channels.

```swift
Image("photo")
    .colorMultiply(.red)
```

### `luminanceToAlpha()`
Converts luminance to alpha channel.

```swift
Image("photo")
    .luminanceToAlpha()
```

### `tint(_:)`
Sets accent color for the view hierarchy.

**Use:** Buttons, controls, SF Symbols.

```swift
Button("Tap") { }
    .tint(.green)
```

### `accentColor(_:)`
Sets accent color (older API).

**Cons:** Deprecated in favor of `.tint()`.

```swift
Button("Tap") { }
    .accentColor(.blue)
```

---

## Shape & Clipping

### `clipped(antialiased:)`
Clips content to bounds.

**Use:** Prevent content overflow.

**Issues:** Apply after `.scaledToFill()` on images.

```swift
Image("photo")
    .resizable()
    .scaledToFill()
    .frame(width: 200, height: 200)
    .clipped()
```

### `clipShape(_:style:)`
Clips to a shape.

**Use:** Circular avatars, custom shapes.

```swift
Image("avatar")
    .resizable()
    .clipShape(Circle())
```

### `cornerRadius(_:antialiased:)`
Rounds corners.

**Use:** Rounded rectangles.

**Cons:** Limited control; doesn't allow per-corner radii.

**Alternatives:** Use `.clipShape(RoundedRectangle())`.

```swift
Rectangle()
    .fill(.blue)
    .cornerRadius(10)
```

### `mask(_:)`
Uses view as alpha mask.

**Use:** Complex masking effects.

```swift
Image("photo")
    .mask(
        LinearGradient(gradient: Gradient(colors: [.clear, .black]), 
                      startPoint: .top, endPoint: .bottom)
    )
```

### `mask(alignment:_:)`
Mask with alignment control.

```swift
Rectangle()
    .mask(alignment: .center) {
        Circle()
    }
```

### `containerShape(_:)`
Sets shape for containers.

**Use:** Defines interactive shape for buttons, lists.

```swift
Button("Tap") { }
    .containerShape(Capsule())
```

---

## Transformations

### `rotationEffect(_:anchor:)`
Rotates view by angle.

**Use:** Animations, orientations.

**Issues:** Doesn't affect layout space.

```swift
Text("Rotated")
    .rotationEffect(.degrees(45))
```

### `rotation3DEffect(_:axis:anchor:anchorZ:perspective:)`
3D rotation effect.

**Use:** Flip animations, 3D transforms.

```swift
Rectangle()
    .rotation3DEffect(
        .degrees(rotationValue),
        axis: (x: 0, y: 1, z: 0)
    )
```

### `perspective(_:)`
Sets perspective for 3D transforms.

```swift
Rectangle()
    .rotation3DEffect(.degrees(45), axis: (x: 1, y: 0, z: 0))
    .perspective(0.5)
```

### `projectionEffect(_:)`
Applies projection matrix transform.

**Use:** Advanced 3D transformations.

**Cons:** Requires understanding of transformation matrices.

```swift
// Advanced usage with ProjectionTransform
```

### `transformEffect(_:)`
Applies CGAffineTransform.

**Use:** Complex 2D transformations.

```swift
Text("Transformed")
    .transformEffect(CGAffineTransform(scaleX: 1.5, y: 0.8))
```

---

## Accessibility

### `accessibilityLabel(_:)`
Sets accessibility label.

**Use:** Describe view purpose for VoiceOver.

**Pros:** Essential for accessibility.

```swift
Image(systemName: "heart")
    .accessibilityLabel("Favorite")
```

### `accessibilityValue(_:)`
Sets current value description.

**Use:** Sliders, progress indicators.

```swift
Slider(value: $volume)
    .accessibilityValue("\(Int(volume))%")
```

### `accessibilityHint(_:)`
Provides usage hint.

**Use:** Explain what will happen when activated.

```swift
Button("Save") { }
    .accessibilityHint("Saves your current changes")
```

### `accessibilityHidden(_:)`
Hides from accessibility.

**Use:** Decorative elements.

```swift
Divider()
    .accessibilityHidden(true)
```

### `accessibilityIdentifier(_:)`
Sets identifier for UI testing.

**Use:** Target views in automated tests.

```swift
Button("Login") { }
    .accessibilityIdentifier("loginButton")
```

### `accessibilityElement(children:)`
Groups or separates accessibility elements.

```swift
VStack {
    Text("Title")
    Text("Subtitle")
}
.accessibilityElement(children: .combine)
```

### `accessibilityAction(_:_:)`
Adds custom accessibility action.

**Use:** Context menu alternatives for VoiceOver.

```swift
Text("Item")
    .accessibilityAction(named: "Delete") {
        deleteItem()
    }
```

### `accessibilityAdjustableAction(_:)`
Handles increment/decrement for adjustable elements.

```swift
CustomSlider()
    .accessibilityAdjustableAction { direction in
        // Handle increment/decrement
    }
```

### `accessibilityScrollAction(_:)`
Adds scroll action handler.

```swift
ScrollView {
    // content
}
.accessibilityScrollAction { edge in
    // Handle scroll to edge
}
```

### `accessibilityAddTraits(_:)`
Adds accessibility traits.

```swift
Text("Header")
    .accessibilityAddTraits(.isHeader)
```

### `accessibilityRemoveTraits(_:)`
Removes accessibility traits.

```swift
Button("Disabled") { }
    .disabled(true)
    .accessibilityRemoveTraits(.isButton)
```

### `accessibilityInputLabels(_:)`
Alternative labels for voice control.

```swift
TextField("Email", text: $email)
    .accessibilityInputLabels(["Email address", "E-mail"])
```

### `accessibilitySortPriority(_:)`
Sets reading order priority.

```swift
HStack {
    Text("Second").accessibilitySortPriority(0)
    Text("First").accessibilitySortPriority(1)
}
```

### `accessibilityActivationPoint(_:)`
Sets tap point for activation.

```swift
// For custom interactive areas
```

### `accessibilityRespondsToUserInteraction(_:)`
Indicates if view responds to interaction.

```swift
Text("Static")
    .accessibilityRespondsToUserInteraction(false)
```

---

## Gestures & Interactions

### `onTapGesture(count:perform:)`
Detects tap gestures.

**Use:** Make any view tappable.

**Pros:** Simpler than Button for custom designs.

```swift
Text("Tap me")
    .onTapGesture {
        print("Tapped")
    }
```

### `onLongPressGesture(minimumDuration:maximumDistance:perform:onPressingChanged:)`
Detects long press.

**Use:** Context menus, alternative actions.

```swift
Circle()
    .onLongPressGesture {
        showContextMenu = true
    }
```

### `gesture(_:including:)`
Adds gesture recognizer.

**Use:** Complex gesture handling.

```swift
Circle()
    .gesture(
        DragGesture()
            .onChanged { value in
                offset = value.translation
            }
    )
```

### `highPriorityGesture(_:including:)`
Adds high-priority gesture.

**Use:** Override child gestures.

```swift
ScrollView {
    // content
}
.highPriorityGesture(
    DragGesture()
        .onEnded { _ in handleDrag() }
)
```

### `simultaneousGesture(_:including:)`
Adds simultaneous gesture.

**Use:** Allow multiple gestures to trigger together.

```swift
Image("photo")
    .gesture(dragGesture)
    .simultaneousGesture(magnificationGesture)
```

### `disabled(_:)`
Disables interactions.

**Use:** Prevent user interaction conditionally.

```swift
Button("Submit") { }
    .disabled(isProcessing)
```

### `allowsHitTesting(_:)`
Enables/disables hit testing.

**Use:** Make views transparent to touches.

**Issues:** Different from `.disabled()` - doesn't show disabled state.

```swift
Rectangle()
    .fill(.blue)
    .allowsHitTesting(false) // Touches pass through
```

### `contentShape(_:eoFill:)`
Defines tappable area shape.

**Use:** Expand tappable area beyond visible bounds.

**Pros:** Essential for small tap targets.

```swift
Text("Tap")
    .contentShape(Rectangle()) // Makes entire frame tappable
```

### `hoverEffect(_:isEnabled:)`
Adds pointer hover effect (iPadOS).

**Use:** iPad cursor interactions.

```swift
Button("Hover") { }
    .hoverEffect()
```

### `onHover(perform:)`
Detects mouse hover (macOS/iPadOS).

```swift
Rectangle()
    .onHover { hovering in
        isHovered = hovering
    }
```

---

## Animation

### `animation(_:value:)`
Animates changes to a value.

**Use:** Animate view changes when value changes.

**Pros:** Simple declarative animations.

**Issues:** Apply to specific views, not entire hierarchies.

```swift
Circle()
    .scaleEffect(isExpanded ? 2.0 : 1.0)
    .animation(.spring(), value: isExpanded)
```

### `animation(_:)`
Applies animation to all changes (deprecated).

**Cons:** Deprecated; use `animation(_:value:)` instead.

**Issues:** Can cause unintended animations.

```swift
// Don't use - deprecated
.animation(.default)
```

### `transition(_:)`
Sets transition for appearance/removal.

**Use:** Animate view insertion/removal.

```swift
if showDetail {
    DetailView()
        .transition(.slide)
}
```

### `matchedGeometryEffect(id:in:properties:anchor:isSource:)`
Matches geometry between views.

**Use:** Hero animations between views.

**Pros:** Smooth shared element transitions.

```swift
@Namespace private var animation

Circle()
    .matchedGeometryEffect(id: "shape", in: animation)
```

### `drawingGroup(opaque:colorMode:)`
Renders into offscreen buffer.

**Use:** Optimize complex animations.

**Pros:** Better performance for layered animations.

**Cons:** Memory overhead.

```swift
ComplexAnimatedView()
    .drawingGroup()
```

---

## Text Modifiers

### `font(_:)`
Sets text font.

**Use:** Essential text styling.

**Pros:** Supports system dynamic type.

```swift
Text("Title")
    .font(.title)
```

### `fontWeight(_:)`
Sets font weight.

```swift
Text("Bold")
    .fontWeight(.bold)
```

### `fontWidth(_:)`
Sets font width (iOS 16+).

```swift
Text("Condensed")
    .fontWidth(.condensed)
```

### `fontDesign(_:)`
Sets font design style.

```swift
Text("Rounded")
    .fontDesign(.rounded)
```

### `bold()`
Makes text bold.

```swift
Text("Bold")
    .bold()
```

### `italic()`
Makes text italic.

```swift
Text("Italic")
    .italic()
```

### `underline(_:color:)`
Adds underline.

```swift
Text("Underlined")
    .underline(true, color: .red)
```

### `strikethrough(_:color:)`
Adds strikethrough.

```swift
Text("Strikethrough")
    .strikethrough(true, color: .gray)
```

### `baselineOffset(_:)`
Offsets text baseline.

**Use:** Superscript/subscript effects.

```swift
Text("x") + Text("2").baselineOffset(-5)
```

### `kerning(_:)`
Adjusts character spacing.

```swift
Text("Spaced")
    .kerning(2)
```

### `tracking(_:)`
Adjusts tracking (like kerning but includes trailing space).

```swift
Text("Tracked")
    .tracking(3)
```

### `lineLimit(_:)`
Limits number of lines.

**Use:** Truncate long text.

```swift
Text("Long text...")
    .lineLimit(2)
```

### `lineLimit(_:reservesSpace:)`
Limits lines with space reservation option.

```swift
Text("Text")
    .lineLimit(3, reservesSpace: true)
```

### `lineSpacing(_:)`
Sets spacing between lines.

```swift
Text("Line 1\nLine 2")
    .lineSpacing(10)
```

### `minimumScaleFactor(_:)`
Allows text to scale down.

**Use:** Fit text in constrained space.

```swift
Text("Long title")
    .minimumScaleFactor(0.5)
```

### `allowsTightening(_:)`
Allows letter tightening to fit.

```swift
Text("Tight")
    .allowsTightening(true)
```

### `truncationMode(_:)`
Sets truncation style.

```swift
Text("Long text...")
    .truncationMode(.middle)
```

### `textCase(_:)`
Sets text case transformation.

```swift
Text("lowercase")
    .textCase(.uppercase)
```

### `textSelection(_:)`
Enables text selection (iOS 15+).

**Use:** Allow users to copy text.

```swift
Text("Selectable")
    .textSelection(.enabled)
```

### `monospaced()`
Uses monospaced font variant.

```swift
Text("123456")
    .monospaced()
```

### `monospacedDigit()`
Uses monospaced digits only.

**Use:** Align numeric displays.

```swift
Text("\(count)")
    .monospacedDigit()
```

### `dynamicTypeSize(_:)`
Overrides dynamic type size.

```swift
Text("Fixed Size")
    .dynamicTypeSize(.large)
```

### `dynamicTypeSize(_:)` (range)
Limits dynamic type size range.

```swift
Text("Constrained")
    .dynamicTypeSize(.medium ... .xxxLarge)
```

---

## List & Form Styling

### `listStyle(_:)`
Sets list appearance style.

**Use:** Customize list presentation.

```swift
List {
    // items
}
.listStyle(.insetGrouped)
```

### `listRowBackground(_:)`
Sets row background.

```swift
List {
    Text("Row")
        .listRowBackground(Color.blue)
}
```

### `listRowInsets(_:)`
Sets row insets.

```swift
List {
    Text("Row")
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
}
```

### `listRowSeparator(_:edges:)`
Controls row separator visibility.

```swift
List {
    Text("Row")
        .listRowSeparator(.hidden)
}
```

### `listRowSeparatorTint(_:edges:)`
Tints row separator.

```swift
List {
    Text("Row")
        .listRowSeparatorTint(.red)
}
```

### `listSectionSeparator(_:edges:)`
Controls section separator visibility.

```swift
List {
    Section { }
        .listSectionSeparator(.hidden)
}
```

### `listSectionSeparatorTint(_:edges:)`
Tints section separator.

```swift
List {
    Section { }
        .listSectionSeparatorTint(.blue)
}
```

### `swipeActions(edge:allowsFullSwipe:content:)`
Adds swipe actions to list rows.

**Use:** Delete, edit actions on swipe.

```swift
List {
    Text("Item")
        .swipeActions {
            Button("Delete", role: .destructive) { }
        }
}
```

### `refreshable(action:)`
Adds pull-to-refresh.

**Use:** Refresh list content.

```swift
List {
    // items
}
.refreshable {
    await loadData()
}
```

### `searchable(text:placement:prompt:)`
Adds search bar.

**Use:** Filter list content.

```swift
List {
    // items
}
.searchable(text: $searchText)
```

### `formStyle(_:)`
Sets form style.

```swift
Form {
    // fields
}
.formStyle(.grouped)
```

---

## Navigation

### `navigationTitle(_:)`
Sets navigation bar title.

```swift
List {
    // content
}
.navigationTitle("Title")
```

### `navigationBarTitleDisplayMode(_:)`
Sets title display mode.

```swift
ScrollView {
    // content
}
.navigationTitle("Title")
.navigationBarTitleDisplayMode(.inline)
```

### `navigationBarHidden(_:)`
Hides navigation bar.

**Cons:** Deprecated in iOS 16+.

**Alternatives:** Use `.toolbar(.hidden)`.

```swift
ScrollView { }
    .navigationBarHidden(true)
```

### `navigationBarBackButtonHidden(_:)`
Hides back button.

```swift
DetailView()
    .navigationBarBackButtonHidden(true)
```

### `toolbar(_:for:)`
Shows/hides toolbars.

```swift
ScrollView { }
    .toolbar(.hidden, for: .navigationBar)
```

### `toolbar(content:)`
Adds toolbar items.

**Use:** Add buttons to navigation bar.

```swift
List { }
    .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Add") { }
        }
    }
```

### `toolbarBackground(_:for:)`
Sets toolbar background visibility.

```swift
ScrollView { }
    .toolbarBackground(.visible, for: .navigationBar)
```

### `toolbarBackground(_:for:)` (with ShapeStyle)
Sets toolbar background style.

```swift
ScrollView { }
    .toolbarBackground(.blue, for: .navigationBar)
```

### `toolbarColorScheme(_:for:)`
Sets toolbar color scheme.

```swift
List { }
    .toolbarColorScheme(.dark, for: .navigationBar)
```

### `toolbarRole(_:)`
Sets toolbar role for navigation.

```swift
DetailView()
    .toolbarRole(.editor)
```

### `navigationDestination(isPresented:destination:)`
Destination for navigation state.

**Use:** Programmatic navigation.

```swift
NavigationStack {
    Button("Go") {
        showDetail = true
    }
    .navigationDestination(isPresented: $showDetail) {
        DetailView()
    }
}
```

### `navigationDestination(for:destination:)`
Type-based navigation destination.

**Use:** Navigate to specific data types.

```swift
NavigationStack {
    List(items) { item in
        NavigationLink(value: item) {
            Text(item.name)
        }
    }
    .navigationDestination(for: Item.self) { item in
        DetailView(item: item)
    }
}
```

### `navigationDocument(_:)`
Sets document for navigation.

```swift
DocumentGroup(viewing: MyDocument.self) { file in
    ContentView()
        .navigationDocument(file.document)
}
```

### `navigationSplitViewStyle(_:)`
Sets split view style.

```swift
NavigationSplitView {
    // sidebar
} detail: {
    // detail
}
.navigationSplitViewStyle(.balanced)
```

### `navigationSplitViewColumnWidth(_:)`
Sets column width.

```swift
NavigationSplitView {
    // sidebar
} detail: {
    // detail
}
.navigationSplitViewColumnWidth(300)
```

### `navigationSplitViewColumnWidth(min:ideal:max:)`
Sets flexible column width.

```swift
NavigationSplitView {
    // sidebar
} detail: {
    // detail
}
.navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 350)
```

---

## Presentation

### `sheet(isPresented:onDismiss:content:)`
Presents modal sheet.

**Use:** Modal presentations.

```swift
Button("Show") {
    showSheet = true
}
.sheet(isPresented: $showSheet) {
    SheetView()
}
```

### `sheet(item:onDismiss:content:)`
Presents sheet for item.

**Use:** Present different sheets based on data.

```swift
.sheet(item: $selectedItem) { item in
    DetailView(item: item)
}
```

### `fullScreenCover(isPresented:onDismiss:content:)`
Presents full-screen modal.

**Use:** Immersive presentations.

```swift
Button("Show") {
    showFullScreen = true
}
.fullScreenCover(isPresented: $showFullScreen) {
    FullScreenView()
}
```

### `fullScreenCover(item:onDismiss:content:)`
Presents full-screen cover for item.

```swift
.fullScreenCover(item: $selectedItem) { item in
    DetailView(item: item)
}
```

### `popover(isPresented:attachmentAnchor:arrowEdge:content:)`
Presents popover.

**Use:** iPad-style popovers.

```swift
Button("Show") {
    showPopover = true
}
.popover(isPresented: $showPopover) {
    PopoverView()
}
```

### `popover(item:attachmentAnchor:arrowEdge:content:)`
Presents popover for item.

```swift
.popover(item: $selectedItem) { item in
    DetailView(item: item)
}
```

### `confirmationDialog(_:isPresented:titleVisibility:actions:)`
Shows action sheet.

**Use:** Multiple choice dialogs.

```swift
.confirmationDialog("Choose", isPresented: $showDialog) {
    Button("Option 1") { }
    Button("Option 2") { }
    Button("Cancel", role: .cancel) { }
}
```

### `confirmationDialog(_:isPresented:titleVisibility:actions:message:)`
Action sheet with message.

```swift
.confirmationDialog("Title", isPresented: $showDialog) {
    // actions
} message: {
    Text("Choose an option")
}
```

### `alert(_:isPresented:actions:)`
Shows alert dialog.

**Use:** Important messages, confirmations.

```swift
.alert("Error", isPresented: $showAlert) {
    Button("OK") { }
}
```

### `alert(_:isPresented:actions:message:)`
Alert with message body.

```swift
.alert("Title", isPresented: $showAlert) {
    Button("OK") { }
} message: {
    Text("Detailed message")
}
```

### `alert(_:isPresented:presenting:actions:)`
Alert presenting data.

```swift
.alert("Error", isPresented: $showAlert, presenting: error) { error in
    Button("OK") { }
} message: { error in
    Text(error.localizedDescription)
}
```

### `alert(_:isPresented:presenting:actions:message:)`
Full-featured data alert.

```swift
.alert("Delete", isPresented: $showAlert, presenting: item) { item in
    Button("Delete", role: .destructive) {
        delete(item)
    }
} message: { item in
    Text("Delete \(item.name)?")
}
```

### `fileImporter(isPresented:allowedContentTypes:allowsMultipleSelection:onCompletion:)`
Shows file picker.

**Use:** Import documents/files.

```swift
.fileImporter(isPresented: $showImporter, allowedContentTypes: [.image]) { result in
    // Handle result
}
```

### `fileExporter(isPresented:document:contentType:defaultFilename:onCompletion:)`
Shows file export dialog.

```swift
.fileExporter(isPresented: $showExporter, document: doc, contentType: .plainText) { result in
    // Handle result
}
```

### `fileMover(isPresented:file:onCompletion:)`
Shows file move dialog.

```swift
.fileMover(isPresented: $showMover, file: fileURL) { result in
    // Handle result
}
```

### `interactiveDismissDisabled(_:)`
Prevents swipe-to-dismiss.

**Use:** Prevent accidental dismissal.

```swift
.sheet(isPresented: $showSheet) {
    FormView()
        .interactiveDismissDisabled(hasUnsavedChanges)
}
```

### `presentationDetents(_:)`
Sets sheet height detents.

**Use:** Half-height sheets, custom sizes.

```swift
.sheet(isPresented: $showSheet) {
    SheetView()
        .presentationDetents([.medium, .large])
}
```

### `presentationDetents(_:selection:)`
Detents with selection binding.

```swift
.sheet(isPresented: $showSheet) {
    SheetView()
        .presentationDetents([.medium, .large], selection: $detent)
}
```

### `presentationDragIndicator(_:)`
Shows/hides drag indicator.

```swift
.sheet(isPresented: $showSheet) {
    SheetView()
        .presentationDragIndicator(.visible)
}
```

### `presentationContentInteraction(_:)`
Controls content scrolling behavior in sheets.

```swift
.sheet(isPresented: $showSheet) {
    ScrollView { }
        .presentationContentInteraction(.scrolls)
}
```

### `presentationCornerRadius(_:)`
Sets sheet corner radius.

```swift
.sheet(isPresented: $showSheet) {
    SheetView()
        .presentationCornerRadius(30)
}
```

### `presentationBackground(_:)`
Sets sheet background.

```swift
.sheet(isPresented: $showSheet) {
    SheetView()
        .presentationBackground(.ultraThinMaterial)
}
```

### `presentationBackground(alignment:content:)`
Custom background view.

```swift
.sheet(isPresented: $showSheet) {
    SheetView()
        .presentationBackground {
            Color.blue.opacity(0.3)
        }
}
```

### `presentationBackgroundInteraction(_:)`
Controls background interaction.

```swift
.sheet(isPresented: $showSheet) {
    SheetView()
        .presentationBackgroundInteraction(.enabled)
}
```

### `presentationCompactAdaptation(_:)`
Sets compact presentation style.

```swift
.sheet(isPresented: $showSheet) {
    SheetView()
        .presentationCompactAdaptation(.fullScreenCover)
}
```

---

## Environment & Preferences

### `environment(_:_:)`
Sets environment value.

**Use:** Pass data down view hierarchy.

```swift
ContentView()
    .environment(\.colorScheme, .dark)
```

### `environmentObject(_:)`
Provides observable object to environment.

**Use:** Share state across views.

```swift
ContentView()
    .environmentObject(appState)
```

### `preferredColorScheme(_:)`
Sets light/dark mode preference.

```swift
ContentView()
    .preferredColorScheme(.dark)
```

### `colorScheme(_:)`
Forces color scheme (deprecated).

**Alternatives:** Use `.preferredColorScheme()`.

```swift
ContentView()
    .colorScheme(.dark)
```

### `dynamicTypeSize(_:)`
Sets dynamic type size.

```swift
Text("Text")
    .dynamicTypeSize(.xxxLarge)
```

### `redacted(reason:)`
Redacts content (placeholder state).

**Use:** Loading states, privacy.

```swift
ProfileView()
    .redacted(reason: .placeholder)
```

### `unredacted()`
Unredacts specific content.

```swift
VStack {
    Text("Redacted")
    Text("Visible")
        .unredacted()
}
.redacted(reason: .placeholder)
```

### `preference(key:value:)`
Sets preference value.

**Use:** Pass data up view hierarchy.

**Cons:** Complex; requires understanding preferences.

```swift
struct MyPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

Text("Text")
    .background(GeometryReader { geo in
        Color.clear.preference(key: MyPreferenceKey.self, 
                             value: geo.size.height)
    })
```

### `onPreferenceChange(_:perform:)`
Observes preference changes.

```swift
VStack {
    // content
}
.onPreferenceChange(MyPreferenceKey.self) { value in
    print("Height: \(value)")
}
```

### `transformPreference(_:_:)`
Transforms preference value.

```swift
.transformPreference(MyPreferenceKey.self) { value in
    value += 10
}
```

### `anchorPreference(key:value:transform:)`
Creates anchor-based preference.

**Use:** Position-based calculations.

```swift
Text("Anchor")
    .anchorPreference(key: MyAnchorKey.self, value: .bounds) { $0 }
```

### `backgroundPreferenceValue(_:_:)`
Creates background based on preference.

```swift
.backgroundPreferenceValue(MyPreferenceKey.self) { value in
    // Create view based on preference
}
```

### `overlayPreferenceValue(_:_:)`
Creates overlay based on preference.

```swift
.overlayPreferenceValue(MyPreferenceKey.self) { value in
    // Create view based on preference
}
```

---

## State & Binding

### `id(_:)`
Sets stable identity.

**Use:** Force view recreation.

**Pros:** Useful for animations, resets.

```swift
DetailView()
    .id(selectedItem.id) // Recreate when item changes
```

### `equatable()`
Optimizes view diffing for Equatable types.

**Use:** Performance optimization.

```swift
MyExpensiveView()
    .equatable()
```

### `onChange(of:perform:)`
Observes value changes.

**Use:** Side effects on state changes.

**Cons:** Deprecated in iOS 17+.

**Alternatives:** Use `onChange(of:initial:_:)`.

```swift
TextField("Name", text: $name)
    .onChange(of: name) { newValue in
        validateName(newValue)
    }
```

### `onChange(of:initial:_:)`
Modern change observer with initial call option.

```swift
TextField("Name", text: $name)
    .onChange(of: name, initial: false) { oldValue, newValue in
        validateName(newValue)
    }
```

### `task(priority:_:)`
Runs async task on appear.

**Use:** Load data when view appears.

**Pros:** Automatically cancelled on disappear.

```swift
List {
    // items
}
.task {
    await loadData()
}
```

### `task(id:priority:_:)`
Runs async task when ID changes.

**Use:** Reload on dependency change.

```swift
DetailView()
    .task(id: selectedItem) {
        await loadDetails(for: selectedItem)
    }
```

### `onAppear(perform:)`
Runs when view appears.

**Use:** Setup, load data.

**Issues:** Not called reliably in some navigation scenarios.

```swift
ContentView()
    .onAppear {
        setupView()
    }
```

### `onDisappear(perform:)`
Runs when view disappears.

**Use:** Cleanup, save state.

```swift
EditorView()
    .onDisappear {
        saveChanges()
    }
```

### `onReceive(_:perform:)`
Observes publisher.

**Use:** Respond to Combine publishers.

```swift
ContentView()
    .onReceive(timer) { _ in
        updateTime()
    }
```

### `onSubmit(of:_:)`
Handles form submission.

**Use:** TextField return key handling.

```swift
TextField("Search", text: $query)
    .onSubmit {
        performSearch()
    }
```

### `onContinuousHover(coordinateSpace:perform:)`
Tracks continuous hover state.

```swift
Rectangle()
    .onContinuousHover { phase in
        switch phase {
        case .active(let location):
            handleHover(at: location)
        case .ended:
            endHover()
        }
    }
```

---

## Control & Input

### `buttonStyle(_:)`
Sets button style.

**Use:** Customize button appearance.

```swift
Button("Tap") { }
    .buttonStyle(.bordered)
```

### `buttonBorderShape(_:)`
Sets button border shape.

```swift
Button("Tap") { }
    .buttonStyle(.bordered)
    .buttonBorderShape(.capsule)
```

### `controlSize(_:)`
Sets control size.

**Use:** Adjust button, picker sizes.

```swift
Button("Tap") { }
    .controlSize(.large)
```

### `controlProminence(_:)`
Sets control visual prominence.

```swift
Button("Primary") { }
    .controlProminence(.increased)
```

### `keyboardType(_:)`
Sets keyboard type for text input.

```swift
TextField("Email", text: $email)
    .keyboardType(.emailAddress)
```

### `textContentType(_:)`
Sets text content type for autofill.

```swift
TextField("Email", text: $email)
    .textContentType(.emailAddress)
```

### `autocorrectionDisabled(_:)`
Disables autocorrection.

```swift
TextField("Username", text: $username)
    .autocorrectionDisabled()
```

### `textInputAutocapitalization(_:)`
Sets auto-capitalization.

```swift
TextField("Name", text: $name)
    .textInputAutocapitalization(.words)
```

### `submitLabel(_:)`
Sets keyboard return key label.

```swift
TextField("Search", text: $query)
    .submitLabel(.search)
```

### `focused(_:)`
Binds focus state.

**Use:** Programmatic focus control.

```swift
@FocusState private var isFocused: Bool

TextField("Name", text: $name)
    .focused($isFocused)

Button("Focus") {
    isFocused = true
}
```

### `focused(_:equals:)`
Binds focus to enum value.

**Use:** Manage multiple text fields.

```swift
@FocusState private var focusedField: Field?

TextField("First", text: $first)
    .focused($focusedField, equals: .first)
TextField("Last", text: $last)
    .focused($focusedField, equals: .last)
```

### `focusedValue(_:_:)`
Provides value to focused view.

```swift
TextField("Text", text: $text)
    .focusedValue(\.selectedText, text)
```

### `focusedSceneValue(_:_:)`
Provides scene-level focused value.

```swift
// For multi-window apps
```

### `defaultFocus(_:_:)`
Sets default focus.

```swift
TextField("Default", text: $text)
    .defaultFocus($focusedField, .firstField)
```

### `focusScope(_:)`
Creates focus scope.

```swift
VStack {
    // fields
}
.focusScope(namespace)
```

### `prefersDefaultFocus(_:in:)`
Prefers default focus in scope.

```swift
TextField("Preferred", text: $text)
    .prefersDefaultFocus(true, in: namespace)
```

### `focusSection()`
Creates focus section for tvOS.

```swift
// tvOS specific
VStack {
    // content
}
.focusSection()
```

### `pickerStyle(_:)`
Sets picker style.

```swift
Picker("Options", selection: $selection) {
    // options
}
.pickerStyle(.segmented)
```

### `datePickerStyle(_:)`
Sets date picker style.

```swift
DatePicker("Date", selection: $date)
    .datePickerStyle(.wheel)
```

### `toggleStyle(_:)`
Sets toggle style.

```swift
Toggle("Enabled", isOn: $isEnabled)
    .toggleStyle(.switch)
```

### `labelStyle(_:)`
Sets label style.

```swift
Label("Title", systemImage: "star")
    .labelStyle(.titleAndIcon)
```

### `progressViewStyle(_:)`
Sets progress view style.

```swift
ProgressView(value: progress)
    .progressViewStyle(.linear)
```

### `gaugeStyle(_:)`
Sets gauge style.

```swift
Gauge(value: speed, in: 0...100) {
    Text("Speed")
}
.gaugeStyle(.circular)
```

### `indexViewStyle(_:)`
Sets page indicator style.

```swift
TabView {
    // pages
}
.indexViewStyle(.page(backgroundDisplayMode: .always))
```

### `tabViewStyle(_:)`
Sets tab view style.

```swift
TabView {
    // tabs
}
.tabViewStyle(.page)
```

### `menuStyle(_:)`
Sets menu style.

```swift
Menu("Options") {
    // items
}
.menuStyle(.button)
```

### `menuOrder(_:)`
Sets menu item order.

```swift
Menu("Options") {
    // items
}
.menuOrder(.priority)
```

### `menuIndicator(_:)`
Shows/hides menu indicator.

```swift
Menu("Options") {
    // items
}
.menuIndicator(.visible)
```

### `disclosureGroupStyle(_:)`
Sets disclosure group style.

```swift
DisclosureGroup("Details") {
    // content
}
.disclosureGroupStyle(.automatic)
```

---

## Scroll & Grid

### `scrollContentBackground(_:)`
Shows/hides scroll content background.

**Use:** Hide list backgrounds.

```swift
List {
    // items
}
.scrollContentBackground(.hidden)
```

### `scrollIndicators(_:axes:)`
Controls scroll indicator visibility.

```swift
ScrollView {
    // content
}
.scrollIndicators(.hidden)
```

### `scrollDisabled(_:)`
Disables scrolling.

```swift
ScrollView {
    // content
}
.scrollDisabled(isLocked)
```

### `scrollDismissesKeyboard(_:)`
Controls keyboard dismissal on scroll.

```swift
ScrollView {
    // content with text fields
}
.scrollDismissesKeyboard(.immediately)
```

### `scrollPosition(id:anchor:)`
Binds scroll position to ID.

**Use:** Programmatic scrolling, scroll position tracking.

```swift
ScrollView {
    // content
}
.scrollPosition(id: $scrolledID)
```

### `scrollPosition(initialAnchor:)`
Sets initial scroll anchor.

```swift
ScrollView {
    // content
}
.scrollPosition(initialAnchor: .bottom)
```

### `scrollTargetBehavior(_:)`
Sets scroll snapping behavior.

```swift
ScrollView {
    // content
}
.scrollTargetBehavior(.paging)
```

### `scrollTargetLayout(isEnabled:)`
Enables scroll target layout.

```swift
ScrollView {
    LazyVStack {
        // items
    }
    .scrollTargetLayout()
}
```

### `scrollBounceBehavior(_:axes:)`
Controls scroll bounce behavior.

```swift
ScrollView {
    // content
}
.scrollBounceBehavior(.basedOnSize)
```

### `scrollClipDisabled(_:)`
Disables scroll view clipping.

```swift
ScrollView {
    // content
}
.scrollClipDisabled(true)
```

### `defaultScrollAnchor(_:)`
Sets default scroll anchor.

```swift
ScrollView {
    // content
}
.defaultScrollAnchor(.bottom)
```

### `scrollTransition(_:axis:transition:)`
Adds scroll-based transitions.

**Use:** Parallax effects, fade on scroll.

```swift
Image("photo")
    .scrollTransition { content, phase in
        content
            .opacity(phase.isIdentity ? 1 : 0.5)
            .scaleEffect(phase.isIdentity ? 1 : 0.8)
    }
```

### `containerRelativeFrame(_:count:span:spacing:alignment:)`
Sets frame relative to container.

**Use:** Grid-like layouts in scroll views.

```swift
ScrollView(.horizontal) {
    LazyHStack {
        ForEach(items) { item in
            ItemView(item)
                .containerRelativeFrame(.horizontal, count: 2, spacing: 10)
        }
    }
}
```

### `containerRelativeFrame(_:alignment:)`
Container-relative frame with alignment.

```swift
ScrollView {
    Color.blue
        .containerRelativeFrame([.horizontal, .vertical])
}
```

### `gridCellColumns(_:)`
Sets grid cell column span.

```swift
LazyVGrid(columns: columns) {
    ForEach(items) { item in
        if item.isWide {
            ItemView(item)
                .gridCellColumns(2)
        }
    }
}
```

### `gridCellAnchor(_:)`
Sets grid cell anchor.

```swift
LazyVGrid(columns: columns) {
    ItemView()
        .gridCellAnchor(.topLeading)
}
```

### `gridCellUnsizedAxes(_:)`
Sets axes where cell ignores grid sizing.

```swift
LazyVGrid(columns: columns) {
    ItemView()
        .gridCellUnsizedAxes(.vertical)
}
```

### `gridColumnAlignment(_:)`
Sets column alignment in grid.

```swift
Grid {
    GridRow {
        Text("Left")
            .gridColumnAlignment(.leading)
    }
}
```

---

## Graphics & Rendering

### `compositingGroup()`
Composites view and effects as a group.

**Use:** Ensure effects apply to group, not individuals.

**Pros:** Control opacity/blend of grouped views.

```swift
VStack {
    Text("Line 1")
    Text("Line 2")
}
.compositingGroup()
.opacity(0.5) // Affects group as whole
```

### `blendMode(_:)`
Sets blend mode for compositing.

**Use:** Blend effects, masking.

```swift
Circle()
    .blendMode(.multiply)
```

### `colorEffect(_:isEnabled:)`
Applies custom color effect shader.

**Use:** Custom GPU shaders (iOS 17+).

```swift
Rectangle()
    .colorEffect(ShaderLibrary.customShader())
```

### `distortionEffect(_:maxSampleOffset:isEnabled:)`
Applies distortion shader.

```swift
Image("photo")
    .distortionEffect(ShaderLibrary.ripple(), maxSampleOffset: .zero)
```

### `layerEffect(_:maxSampleOffset:isEnabled:)`
Applies layer effect shader.

```swift
VStack {
    // content
}
.layerEffect(ShaderLibrary.effect(), maxSampleOffset: .zero)
```

### `visualEffect(_:)`
Applies visual effect based on geometry.

**Use:** Scroll-based effects, dynamic transformations.

```swift
Image("photo")
    .visualEffect { content, geometryProxy in
        content.scaleEffect(geometryProxy.frame(in: .global).minY / 100)
    }
```

### `symbolEffect(_:options:isActive:)`
Applies SF Symbol animation.

**Use:** Animate system symbols.

```swift
Image(systemName: "wifi")
    .symbolEffect(.bounce, isActive: isAnimating)
```

### `symbolEffect(_:options:value:)`
Symbol animation triggered by value.

```swift
Image(systemName: "bell")
    .symbolEffect(.bounce, value: notificationCount)
```

### `symbolEffectsRemoved(_:)`
Removes symbol effects.

```swift
Image(systemName: "star")
    .symbolEffectsRemoved()
```

### `symbolRenderingMode(_:)`
Sets symbol rendering mode.

**Use:** Monochrome, multicolor, hierarchical rendering.

```swift
Image(systemName: "heart.fill")
    .symbolRenderingMode(.multicolor)
```

### `symbolVariant(_:)`
Sets symbol variant.

```swift
Image(systemName: "circle")
    .symbolVariant(.fill)
```

### `imageScale(_:)`
Scales image size.

**Use:** SF Symbol sizing.

```swift
Image(systemName: "star")
    .imageScale(.large)
```

### `resizable(capInsets:resizingMode:)`
Makes image resizable.

**Use:** Scale images to fit frames.

**Issues:** Required before using `.aspectRatio()` or scaling.

```swift
Image("photo")
    .resizable()
    .scaledToFit()
```

### `renderingMode(_:)`
Sets image rendering mode.

**Use:** Template images (single color).

```swift
Image("icon")
    .renderingMode(.template)
    .foregroundColor(.blue)
```

### `interpolation(_:)`
Sets image interpolation quality.

**Use:** Pixelated vs smooth scaling.

```swift
Image("pixelArt")
    .resizable()
    .interpolation(.none)
```

### `antialiased(_:)`
Controls antialiasing.

```swift
Circle()
    .antialiased(true)
```

---

## Advanced Layout

### `geometryGroup()`
Creates geometry grouping for effects.

**Use:** Improve performance of complex hierarchies.

```swift
VStack {
    // many views
}
.geometryGroup()
```

### `scenePadding(_:edges:)`
Adds scene-appropriate padding.

**Use:** Consistent margins across platforms.

```swift
ContentView()
    .scenePadding()
```

### `containerBackground(_:for:)`
Sets container background.

**Use:** Widget backgrounds, complications.

```swift
WidgetView()
    .containerBackground(.blue, for: .widget)
```

### `containerBackground(for:alignment:content:)`
Custom container background view.

```swift
WidgetView()
    .containerBackground(for: .widget) {
        LinearGradient(...)
    }
```

### `layoutDirectionBehavior(_:)`
Sets layout direction behavior.

**Use:** Control RTL/LTR behavior.

```swift
HStack {
    // content
}
.layoutDirectionBehavior(.fixed)
```

### `labeledContentStyle(_:)`
Sets labeled content style.

```swift
LabeledContent("Label", value: "Value")
    .labeledContentStyle(.automatic)
```

### `spring(_:blendDuration:)`
Creates spring animation.

**Use:** Bouncy animations.

```swift
Circle()
    .scaleEffect(isExpanded ? 2 : 1)
    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isExpanded)
```

---

## Text Input & Editing

### `textFieldStyle(_:)`
Sets text field style.

```swift
TextField("Name", text: $name)
    .textFieldStyle(.roundedBorder)
```

### `labelsHidden()`
Hides labels (accessibility label still works).

**Use:** Custom label layouts.

```swift
TextField("Name", text: $name)
    .labelsHidden()
```

### `horizontalRadioGroupLayout()`
Sets horizontal radio button layout.

```swift
// Picker with radio buttons
Picker("Options", selection: $selection) {
    // options
}
.horizontalRadioGroupLayout()
```

### `privacySensitive(_:)`
Marks content as privacy-sensitive.

**Use:** Redact in screenshots, screen recording.

```swift
Text(creditCardNumber)
    .privacySensitive()
```

### `speechAlwaysIncludesPunctuation(_:)`
Includes punctuation in speech output.

```swift
Text("Hello world")
    .speechAlwaysIncludesPunctuation(true)
```

### `speechSpellsOutCharacters(_:)`
Spells out characters in speech.

```swift
Text("ABC123")
    .speechSpellsOutCharacters(true)
```

### `speechAdjustedPitch(_:)`
Adjusts speech pitch.

```swift
Text("Important")
    .speechAdjustedPitch(1.5)
```

### `speechAnnouncementsQueued(_:)`
Queues speech announcements.

```swift
Text("Update")
    .speechAnnouncementsQueued(true)
```

---

## Status Bar & Chrome

### `statusBar(hidden:)`
Hides status bar.

**Cons:** Deprecated.

**Alternatives:** Use `.statusBarHidden()`.

```swift
ContentView()
    .statusBar(hidden: true)
```

### `statusBarHidden(_:)`
Hides status bar (modern API).

```swift
ContentView()
    .statusBarHidden(true)
```

### `persistentSystemOverlays(_:)`
Controls system overlay visibility.

**Use:** Immersive experiences.

```swift
GameView()
    .persistentSystemOverlays(.hidden)
```

### `defersSystemGestures(on:)`
Defers system gestures.

**Use:** Games, drawing apps.

```swift
GameView()
    .defersSystemGestures(on: .all)
```

### `contentMargins(_:for:)`
Sets content margins.

```swift
ScrollView {
    // content
}
.contentMargins(.horizontal, 20, for: .scrollContent)
```

### `contentMargins(_:_:for:)`
Content margins with edge insets.

```swift
ScrollView {
    // content
}
.contentMargins(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20), for: .scrollContent)
```

---

## watchOS Specific

### `digitalCrownRotation(_:from:through:by:sensitivity:isContinuous:isHapticFeedbackEnabled:)`
Binds to Digital Crown rotation.

**Use:** watchOS scrolling, value input.

```swift
Text("\(value)")
    .digitalCrownRotation($value, from: 0, through: 100)
```

### `focusable(_:onFocusChange:)`
Makes view focusable on tvOS/watchOS.

```swift
Button("Focus") { }
    .focusable(true)
```

### `handGestureShortcut(_:)`
Adds hand gesture shortcut (watchOS).

```swift
Button("Action") { }
    .handGestureShortcut(.primaryAction)
```

---

## Scene & Window

### `windowStyle(_:)`
Sets window style (macOS).

```swift
WindowGroup {
    ContentView()
}
.windowStyle(.hiddenTitleBar)
```

### `windowToolbarStyle(_:)`
Sets window toolbar style (macOS).

```swift
WindowGroup {
    ContentView()
}
.windowToolbarStyle(.unified)
```

### `windowResizability(_:)`
Sets window resize behavior (macOS).

```swift
Window("Settings", id: "settings") {
    SettingsView()
}
.windowResizability(.contentSize)
```

### `defaultSize(_:)`
Sets default window size (macOS).

```swift
WindowGroup {
    ContentView()
}
.defaultSize(width: 800, height: 600)
```

### `defaultPosition(_:)`
Sets default window position (macOS).

```swift
Window("Inspector", id: "inspector") {
    InspectorView()
}
.defaultPosition(.topTrailing)
```

### `keyboardShortcut(_:modifiers:)`
Adds keyboard shortcut.

**Use:** Menu items, buttons.

```swift
Button("Save") { }
    .keyboardShortcut("s", modifiers: .command)
```

### `keyboardShortcut(_:)`
Adds keyboard shortcut with key equivalent.

```swift
Button("Cancel") { }
    .keyboardShortcut(.cancelAction)
```

### `commands(content:)`
Adds menu bar commands (macOS).

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandMenu("Custom") {
                Button("Action") { }
            }
        }
    }
}
```

### `commandsRemoved()`
Removes default commands (macOS).

```swift
WindowGroup {
    ContentView()
}
.commandsRemoved()
```

### `commandsReplaced(content:)`
Replaces commands (macOS).

```swift
WindowGroup {
    ContentView()
}
.commandsReplaced {
    // Custom commands
}
```

---

## Context Menu & Menu Actions

### `contextMenu(menuItems:)`
Adds context menu.

**Use:** Right-click menus, long-press actions.

```swift
Text("Item")
    .contextMenu {
        Button("Copy") { }
        Button("Delete") { }
    }
```

### `contextMenu(forSelectionType:menu:primaryAction:)`
Context menu with selection type.

```swift
List(selection: $selection) {
    // items
}
.contextMenu(forSelectionType: Item.self) { items in
    // menu for selected items
}
```

### `menuActionDismissBehavior(_:)`
Controls menu dismissal behavior.

```swift
Menu("Options") {
    Button("Keep Open") { }
}
.menuActionDismissBehavior(.disabled)
```

---

## Drag & Drop

### `onDrag(_:)`
Makes view draggable.

**Use:** Drag and drop operations.

```swift
Text("Drag me")
    .onDrag {
        NSItemProvider(object: "Data" as NSString)
    }
```

### `onDrop(of:isTargeted:perform:)`
Handles drop operations.

**Use:** Accept dropped content.

```swift
Rectangle()
    .onDrop(of: [.text], isTargeted: nil) { providers in
        // Handle drop
        return true
    }
```

### `onDrop(of:delegate:)`
Drop with custom delegate.

```swift
Rectangle()
    .onDrop(of: [.text], delegate: dropDelegate)
```

### `itemProvider(_:)`
Provides item for drag.

```swift
Image("photo")
    .itemProvider {
        NSItemProvider(object: url as NSURL)
    }
```

### `draggable(_:)`
Makes content draggable (iOS 16+).

```swift
Text("Drag")
    .draggable("Data")
```

### `dropDestination(for:action:isTargeted:)`
Modern drop destination API.

```swift
Rectangle()
    .dropDestination(for: String.self) { items, location in
        handleDrop(items)
    }
```

---

## Inspector & Auxiliary Views

### `inspector(isPresented:content:)`
Adds inspector sidebar.

**Use:** Side panels, detail views (iOS 16+).

```swift
ContentView()
    .inspector(isPresented: $showInspector) {
        InspectorView()
    }
```

### `inspectorColumnWidth(min:ideal:max:)`
Sets inspector width.

```swift
ContentView()
    .inspector(isPresented: $showInspector) {
        InspectorView()
    }
    .inspectorColumnWidth(min: 200, ideal: 250, max: 300)
```

### `inspectorColumnWidth(_:)`
Sets fixed inspector width.

```swift
ContentView()
    .inspector(isPresented: $showInspector) {
        InspectorView()
    }
    .inspectorColumnWidth(250)
```

---

## Help & Documentation

### `help(_:)`
Adds help tooltip (macOS).

**Use:** Hover tooltips.

```swift
Button("Action") { }
    .help("Performs the action")
```

---

## Badge & Overlays

### `badge(_:)`
Adds badge to view.

**Use:** Notification counts, status indicators.

```swift
TabView {
    MessagesView()
        .tabItem { Label("Messages", systemImage: "message") }
        .badge(unreadCount)
}
```

### `badge(_:)` (Text)
Text badge variant.

```swift
.badge(Text("New"))
```

---

## Miscellaneous

### `tag(_:)`
Tags view with value.

**Use:** Identify views in pickers, tabs.

```swift
Picker("Options", selection: $selection) {
    Text("One").tag(1)
    Text("Two").tag(2)
}
```

### `contentTransition(_:)`
Sets content transition type.

**Use:** Smooth transitions between content states.

```swift
Text("\(count)")
    .contentTransition(.numericText())
```

### `repeatingBorder(_:count:)`
Creates repeating border pattern.

```swift
Rectangle()
    .repeatingBorder(.init(pattern: [4, 2]), count: 10)
```

### `measurementFormatter(_:)`
Sets measurement formatter for gauges.

```swift
Gauge(value: temperature, in: 0...100) { }
    .measurementFormatter(formatter)
```

### `sensoryFeedback(_:trigger:)`
Provides haptic feedback.

**Use:** Tactile feedback on state changes.

```swift
Button("Tap") {
    buttonTapped.toggle()
}
.sensoryFeedback(.impact, trigger: buttonTapped)
```

### `sensoryFeedback(_:trigger:condition:)`
Conditional haptic feedback.

```swift
Toggle("Enabled", isOn: $isEnabled)
    .sensoryFeedback(.success, trigger: isEnabled) { oldValue, newValue in
        newValue == true
    }
```

### `invalidatableContent(_:)`
Marks content as invalidatable.

**Use:** Widget timelines.

```swift
WidgetView()
    .invalidatableContent()
```

### `widgetAccentable(_:)`
Marks widget content as accentable.

```swift
Image(systemName: "star")
    .widgetAccentable()
```

### `widgetLabel(_:)`
Adds label to widget.

```swift
Text("Value")
    .widgetLabel {
        Text("Label")
    }
```

### `privacySensitive(_:)`
Marks content privacy-sensitive.

```swift
Text(password)
    .privacySensitive()
```

### `modelContainer(for:inMemory:isAutosaveEnabled:isUndoEnabled:onSetup:)`
Provides SwiftData model container.

**Use:** SwiftData persistence.

```swift
ContentView()
    .modelContainer(for: Item.self)
```

### `modelContext(_:)`
Provides model context.

```swift
ContentView()
    .modelContext(modelContext)
```

### `deleteDisabled(_:)`
Disables delete actions.

**Use:** Prevent deletion in lists.

```swift
List {
    ForEach(items) { item in
        Text(item.name)
            .deleteDisabled(item.isProtected)
    }
}
```

### `moveDisabled(_:)`
Disables move actions.

```swift
List {
    ForEach(items) { item in
        Text(item.name)
            .moveDisabled(item.isFixed)
    }
}
```

### `exportableToServices(_:)`
Makes content exportable to system services.

```swift
Text("Share this")
    .exportableToServices()
```

### `fileDialogBrowserOptions(_:)`
Sets file dialog browser options.

```swift
// File dialog customization
```

### `fileDialogConfirmationLabel(_:)`
Sets file dialog button label.

```swift
.fileDialogConfirmationLabel("Import")
```

### `fileDialogDefaultDirectory(_:)`
Sets default directory for file dialogs.

```swift
.fileDialogDefaultDirectory(URL(fileURLWithPath: "/Documents"))
```

### `fileDialogImportsUnresolvedAliases(_:)`
Controls alias resolution in file imports.

```swift
.fileDialogImportsUnresolvedAliases(true)
```

### `fileDialogMessage(_:)`
Sets file dialog message.

```swift
.fileDialogMessage("Choose a file to import")
```

### `fileDialogURLEnabled(_:)`
Enables/disables specific URLs in file dialog.

```swift
.fileDialogURLEnabled { url in
    url.pathExtension == "txt"
}
```

---

## Deprecated Modifiers

### `accentColor(_:)` 
Replaced by `.tint(_:)` in iOS 15+.

### `navigationBarTitle(_:)` 
Replaced by `.navigationTitle(_:)`.

### `navigationBarTitle(_:displayMode:)` 
Replaced by `.navigationTitle(_:)` and `.navigationBarTitleDisplayMode(_:)`.

### `navigationBarItems(leading:trailing:)` 
Replaced by `.toolbar(content:)`.

### `edgesIgnoringSafeArea(_:)` 
Replaced by `.ignoresSafeArea(_:edges:)`.

### `imageScale(_:)` (environment)
Now part of environment, not a direct modifier in some contexts.

---

## Tips for Modifier Ordering

**General Rule:** Modifiers apply inside-out (bottom-to-top in code).

**Common Patterns:**

1. **Background/Border/Padding:**
```swift
Text("Example")
    .padding()           // 1. Add padding
    .background(.blue)   // 2. Color includes padding
    .border(.red)        // 3. Border around background+padding
```

2. **Frame then Modifiers:**
```swift
Text("Example")
    .frame(width: 200, height: 100)  // 1. Set size
    .background(.blue)                // 2. Fill frame
    .clipShape(RoundedRectangle(cornerRadius: 10))  // 3. Clip to shape
```

3. **Gestures and Animations:**
```swift
Circle()
    .scaleEffect(scale)      // 1. Transform
    .animation(.spring())    // 2. Animate transforms
    .onTapGesture { }        // 3. Add interaction
```

4. **Accessibility Last:**
```swift
Button("Action") { }
    .padding()
    .background(.blue)
    .accessibilityLabel("Perform Action")  // Last
```

---

## Performance Considerations

**Expensive Modifiers:**
- `.blur(radius:)` - GPU intensive
- `.shadow(color:radius:x:y:)` - Multiple passes
- `.drawingGroup()` - Offscreen rendering overhead

**Optimization Tips:**
- Use `.equatable()` for expensive views
- Apply `.id(_:)` strategically to control view identity
- Minimize use of effects on scrolling content
- Use `.drawingGroup()` for complex layered animations

---

## Common Pitfalls

1. **`.animation(_:)` without value** - Deprecated and causes unintended animations
2. **`.frame()` vs `.fixedSize()`** - Understand when to use each
3. **Padding order** - Apply before background to include in colored area
4. **`.clipped()` placement** - Apply after frames and scaling
5. **Gesture conflicts** - Use `highPriorityGesture` or `simultaneousGesture` appropriately
6. **Modifier order** - Transform → Style → Layout → Interaction is generally safe

---

**Document Version:** iOS 17 / macOS 14 / watchOS 10 / tvOS 17  
**Last Updated:** November 2025

This reference covers 300+ SwiftUI view modifiers. For the latest additions and platform-specific modifiers, consult Apple's official SwiftUI documentation.
