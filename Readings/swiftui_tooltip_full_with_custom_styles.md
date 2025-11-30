
# SwiftUI & UIKit Tooltip Techniques (Complete Guide with Custom Tooltip Types)

This guide includes:

- Cross‑platform SwiftUI tooltip
- macOS native hover behavior
- iOS/iPadOS long‑press and pointer‑hover tooltips
- UIKit + SwiftUI interoperability
- **A full pluggable `TooltipStyle` system**
- **Custom tooltip types:**  
  ✓ Bubble Tooltip  
  ✓ Popover Tooltip  
  ✓ Bottom Sheet Tooltip  
- A unified modifier supporting all styles

---

# 1. Cross‑Platform SwiftUI Tooltip (`.tooltip`)

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
                    withAnimation { isPresented.toggle() }
                }

            if isPresented {
                Text(text)
                    .font(.caption)
                    .padding(8)
                    .background(.thinMaterial)
                    .cornerRadius(8)
                    .shadow(radius: 4)
                    .offset(y: -40)
                    .transition(.opacity)
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

---

# 2. Pointer‑Aware Tooltip for iPadOS + Catalyst

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
                        .offset(y: -40)
                        .transition(.opacity)
                }
            }
            .onHover { hover in
                withAnimation { isPresented = hover }
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

Tooltip system works inside UIKit-hosted SwiftUI.

### Wrapping a UIKit Control:

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
            .tooltip("UIKit wrapped tooltip")
    }
}
```

---

# 4. TooltipStyle System (Pluggable Visual Styles)

The custom system lets you switch between Bubble, Popover, Bottom Sheet, and future styles.

---

## 4.1 TooltipStyle Protocol

```swift
protocol TooltipStyle {
    associatedtype Body: View
    func makeBody(text: String) -> Body
}
```

---

## 4.2 Environment Support

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

---

# 5. Built‑In Custom Tooltip Styles

---

## 5.1 Bubble Tooltip

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

---

## 5.2 Popover Tooltip

```swift
struct PopoverTooltipStyle: TooltipStyle {
    func makeBody(text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(text).font(.footnote)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .shadow(radius: 8)
        )
        .frame(maxWidth: 200)
    }
}
```

---

## 5.3 Bottom Sheet Tooltip

```swift
struct BottomSheetTooltipStyle: TooltipStyle {
    func makeBody(text: String) -> some View {
        VStack(spacing: 12) {
            Capsule()
                .frame(width: 40, height: 4)
                .foregroundColor(.gray.opacity(0.5))

            Text(text)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.bottom, 20)
        .padding(.top, 10)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(radius: 10)
    }
}
```

---

# 6. Unified Styled Tooltip Modifier

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
                    .offset(y: -50)
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

---

# 7. Using Styled Tooltip Styles

### Bubble Tooltip

```swift
Text("Info")
    .styledTooltip("Bubble style")
    .tooltipStyle(BubbleTooltipStyle())
```

### Popover Tooltip

```swift
Button("Help") { }
    .styledTooltip("Popover style")
    .tooltipStyle(PopoverTooltipStyle())
```

### Bottom Sheet Tooltip

```swift
Image(systemName: "questionmark.circle")
    .styledTooltip("Bottom sheet")
    .tooltipStyle(BottomSheetTooltipStyle())
```

---

# 8. Summary

- **macOS** → Native `.help()` hover support  
- **iOS/iPadOS** → Long‑press, pointer hover  
- **Custom styles** → Bubble, Popover, Bottom Sheet  
- **Unified styling** → `.tooltipStyle(...)` to swap visuals  
- **UIKit support** → Works automatically in wrappers and hosting  

---

# End of Document

