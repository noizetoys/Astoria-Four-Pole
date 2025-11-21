
# SwiftUI & UIKit Tooltip Techniques (Complete Guide)

This document combines:

- Cross‑platform SwiftUI tooltip solutions  
- macOS-native tooltip behaviors  
- iOS/iPadOS long‑press and pointer-hover tooltips  
- UIKit + SwiftUI interoperability  
- **An opinionated `TooltipStyle` protocol with pluggable visual styles**  
- Complete example implementations  

---

# 1. Cross‑Platform SwiftUI Tooltip (`.tooltip`)

This modifier:

- Uses `.help()` on macOS (native tooltips)
- Uses a long‑press gesture to show a floating bubble on iOS
- Works automatically inside UIKit hosting controllers

```swift
import SwiftUI

struct TooltipModifier: ViewModifier {
    let text: String

    #if os(iOS)
    @State private var isPresented = false
    #endif

    func body(content: Content) -> some View {
        #if os(macOS)
        content.help(text)
        #else
        ZStack(alignment: .top) {
            content
                .onLongPressGesture(minimumDuration: 0.4) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isPresented.toggle()
                    }
                }

            if isPresented {
                Text(text)
                    .font(.caption)
                    .padding(8)
                    .background(.thinMaterial)
                    .cornerRadius(8)
                    .shadow(radius: 4)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(
                        .move(edge: .top)
                        .combined(with: .opacity)
                    )
                    .offset(y: -40)
            }
        }
        #endif
    }
}

extension View {
    func tooltip(_ text: String) -> some View {
        modifier(TooltipModifier(text: text))
    }
}
```

Usage:

```swift
Button("Delete") { }
    .tooltip("Deletes the selected item.")
```

---

# 2. Pointer‑Aware Tooltips (Hover on iPad + Catalyst)

```swift
struct PointerAwareTooltipModifier: ViewModifier {
    let text: String

    #if os(iOS)
    @State private var isPresented = false
    #endif

    func body(content: Content) -> some View {
        #if os(macOS)
        content.help(text)
        #else
        content
            .overlay(alignment: .top) {
                if isPresented {
                    Text(text)
                        .font(.caption)
                        .padding(8)
                        .background(.thinMaterial)
                        .cornerRadius(8)
                        .shadow(radius: 4)
                        .fixedSize()
                        .offset(y: -40)
                        .transition(.opacity)
                }
            }
            .onHover { hover in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isPresented = hover
                }
            }
        #endif
    }
}

extension View {
    func hoverTooltip(_ text: String) -> some View {
        modifier(PointerAwareTooltipModifier(text: text))
    }
}
```

---

# 3. UIKit + SwiftUI Integration

### Hosting SwiftUI Inside UIKit

```swift
let vc = UIHostingController(rootView: ContentView())
```

Tooltip features work automatically.

### Using SwiftUI Tooltip on UIKit Controls

```swift
struct UIKitButtonWrapper: UIViewRepresentable {
    func makeUIView(context: Context) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle("UIKit Button", for: .normal)
        return b
    }

    func updateUIView(_ uiView: UIButton, context: Context) {}
}

struct Example: View {
    var body: some View {
        UIKitButtonWrapper()
            .tooltip("Wrapped UIKit button tooltip")
    }
}
```

---

# 4. Opinionated TooltipStyle Protocol (Pluggable Visuals)

This system lets you switch tooltip styles simply by changing the environment value.

## 4.1 TooltipStyle Protocol

```swift
protocol TooltipStyle {
    associatedtype Body: View
    func makeBody(text: String) -> Body
}
```

## 4.2 TooltipStyleKey + Environment Value

```swift
private struct TooltipStyleKey: EnvironmentKey {
    static var defaultValue: any TooltipStyle = BubbleTooltipStyle()
}

extension EnvironmentValues {
    var tooltipStyle: any TooltipStyle {
        get { self[TooltipStyleKey.self] }
        set { self[TooltipStyleKey.self] = newValue }
    }
}

extension View {
    func tooltipStyle(_ style: some TooltipStyle) -> some View {
        environment(\.tooltipStyle, style)
    }
}
```

## 4.3 Bubble Style (Default)

```swift
struct BubbleTooltipStyle: TooltipStyle {
    func makeBody(text: String) -> some View {
        Text(text)
            .font(.caption)
            .padding(8)
            .background(.thinMaterial)
            .cornerRadius(10)
            .shadow(radius: 3)
    }
}
```

## 4.4 Card Style (Like a mini popover)

```swift
struct CardTooltipStyle: TooltipStyle {
    func makeBody(text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Info")
                .font(.headline)
            Text(text)
                .font(.caption)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThickMaterial))
        .shadow(radius: 6)
    }
}
```

## 4.5 HUD Style (Dark translucent)

```swift
struct HUDTooltipStyle: TooltipStyle {
    func makeBody(text: String) -> some View {
        Text(text)
            .font(.caption)
            .padding(10)
            .background(Color.black.opacity(0.75))
            .foregroundColor(.white)
            .cornerRadius(12)
    }
}
```

---

# 5. Tooltip Modifier Using TooltipStyle

This version plugs into the environment.

```swift
struct StyledTooltipModifier: ViewModifier {
    @Environment(\.tooltipStyle) private var style

    let text: String

    #if os(iOS)
    @State private var isPresented = false
    #endif

    func body(content: Content) -> some View {
        #if os(macOS)
        content.help(text)
        #else
        ZStack(alignment: .top) {
            content
                .onLongPressGesture {
                    withAnimation { isPresented.toggle() }
                }

            if isPresented {
                style.makeBody(text: text)
                    .offset(y: -46)
                    .transition(.opacity)
            }
        }
        #endif
    }
}

extension View {
    func styledTooltip(_ text: String) -> some View {
        modifier(StyledTooltipModifier(text: text))
    }
}
```

Usage:

```swift
VStack {
    Button("Info") { }
        .styledTooltip("This is a styled tooltip example.")
}
.tooltipStyle(HUDTooltipStyle())   // <— Swap styles
```

Swap the style anywhere in the view hierarchy.

---

# 6. Summary

### macOS
- `.help` shows native hover tooltips

### iOS/iPadOS
- No hover → use long‑press, overlays, or pointer hover for iPad trackpad

### Cross‑Platform
- Unified `.tooltip`
- Pointer-aware `.hoverTooltip`
- **Pluggable visuals through `TooltipStyle`**

### UIKit + SwiftUI Hybrid
- Tooltips fully functional inside hosting controllers
- UIKit views wrapped in SwiftUI gain tooltip support with modifiers

---

# End of Document
