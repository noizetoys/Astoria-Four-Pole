Yes, this is absolutely still a supported pattern in SwiftUI on both macOS and iPadOS — but *how* you do it differs a bit by platform and by the kind of thing you want (popover vs bubble vs sheet-like panel).

I’ll break it down by **pattern** and **platform**, and then show you how to get something that *visually* “points to” the control that spawned it.

---

## 1. Classic `.popover` in SwiftUI (macOS & iPadOS)

SwiftUI still has a real `.popover` modifier:

```swift
Button("Show Help") {
    isPopoverPresented = true
}
.popover(isPresented: $isPopoverPresented, arrowEdge: .bottom) {
    VStack {
        Text("Popover content")
            .font(.headline)
        Text("Extra details about this button.")
            .font(.caption)
    }
    .padding()
    .frame(width: 240)
}
```

**Platform behavior:**

* **macOS**: true popover attached to the button, with an arrow pointing to it.
* **iPadOS**: also a popover (like a form sheet bubble) anchored on the button, with an arrow.
* **iPhone**: historically turns into a full-screen or sheet-like presentation (no arrow).

On macOS and iPadOS, this is still the primary “tap button → attached popover pointing at it” pattern.

---

## 2. More control on macOS: `popover(item:attachmentAnchor:arrowEdge:)`

If you want fine-grained control over *where* the popover attaches, use `attachmentAnchor`:

```swift
struct ContentView: View {
    @State private var selectedHelpAnchor: CGRect? = nil
    @State private var showPopover = false

    var body: some View {
        VStack {
            Button("Show Popover") {
                showPopover.toggle()
            }
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            selectedHelpAnchor = proxy.frame(in: .global)
                        }
                }
            )
        }
        .popover(isPresented: $showPopover, attachmentAnchor: .rect(.bounds), arrowEdge: .top) {
            Text("Attached popover")
                .padding()
                .frame(width: 200)
        }
    }
}
```

On macOS this is very good at “pointing to the control it came from.”

> Note: In many cases you don’t even need `GeometryReader`; the `attachmentAnchor: .rect(.bounds)` applied to the button’s view hierarchy is sufficient to get an arrow anchored visually to that control.

---

## 3. iPadOS: popover vs “bubble” vs “bottom sheet”

On **iPadOS**, there are three main UX flavors you’re asking about:

### A. Real popovers (arrow pointing to the control)

Use `.popover`, same as above:

```swift
Button {
    isPopoverPresented = true
} label: {
    Label("Info", systemImage: "info.circle")
}
.popover(isPresented: $isPopoverPresented, arrowEdge: .bottom) {
    HelpPopoverView()
}
```

That is still supported and the recommended pattern for “this content is directly related to this control.”

---

### B. “Bubble” style anchored panels (custom overlay)

If you want a smaller “bubble” (like a tooltip/popover hybrid), you typically build it as an **overlay** anchored to the button’s frame, instead of using `.popover`.

Pattern:

1. Capture the button’s frame in some coordinate space.
2. Use `overlay(alignment:)` or a top-level `ZStack` to place a custom bubble near that rect.

Example:

```swift
struct BubbleExample: View {
    @State private var showBubble = false
    @State private var buttonFrame: CGRect = .zero

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack {
                Button {
                    withAnimation { showBubble.toggle() }
                } label: {
                    Text("Tap for bubble")
                }
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .onChange(of: proxy.frame(in: .global)) { newFrame in
                                buttonFrame = newFrame
                            }
                    }
                )

                Spacer()
            }

            if showBubble {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bubble Title")
                        .font(.headline)
                    Text("Some helpful info here.")
                        .font(.caption)
                }
                .padding(8)
                .background(.thinMaterial)
                .cornerRadius(10)
                .shadow(radius: 4)
                // position relative to captured button frame
                .position(x: buttonFrame.midX, y: buttonFrame.minY - 40)
                .transition(.opacity.combined(with: .scale))
            }
        }
    }
}
```

This works on **macOS and iPadOS/iOS** and visually feels like a bubble pointing at a control—even if you don’t use a literal arrow shape.

You can, of course, draw a little arrow triangle with `Path` or a `Capsule`/`RoundedRectangle` combo to get a “speech bubble” look.

---

### C. Bottom sheet anchored to a control (sheet-style UX)

SwiftUI’s `.sheet` is not anchored to a particular control; it’s modal relative to the window/screen. There’s no built-in “sheet with arrow to control” on iOS or macOS.

However, the **common pattern** is:

* Tap a control → present a **bottom sheet** using `.sheet(isPresented:)`
* Optionally include some contextual header referencing the control.

Example:

```swift
struct BottomSheetExample: View {
    @State private var showSheet = false

    var body: some View {
        Button("Show Bottom Sheet") {
            showSheet = true
        }
        .sheet(isPresented: $showSheet) {
            VStack(spacing: 16) {
                Capsule()
                    .frame(width: 40, height: 4)
                    .foregroundColor(.secondary)

                Text("Bottom Sheet")
                    .font(.headline)

                Text("Contextual info related to the control you tapped.")
                    .multilineTextAlignment(.center)

                Button("Close") {
                    showSheet = false
                }
                .padding(.top, 20)
            }
            .padding()
            .presentationDetents([.medium, .large])
        }
    }
}
```

* **iPadOS**: shows as a resizable bottom sheet (or page sheet) depending on size class.
* **macOS** (SwiftUI window-based): `.sheet` shows a modal window/dialog.

You *can* visually style this to look like a “panel spawned from a control,” but the arrow is not standard for sheets—sheets are generally screen-level, not control-level.

---

## 4. Is this still “supported in SwiftUI”?

Short answer: **yes, but with boundaries:**

* **Still supported:**

  * `.popover(isPresented:content:)` and related variants on **macOS** and **iPadOS**.
  * `.sheet` for bottom sheets / modals.
  * `overlay` / `ZStack` patterns for building your own bubbles and anchored views.
* **Not really a thing / not recommended:**

  * Trying to make bottom sheets that have **true arrows** pointing at a button (that’s not a native iOS pattern).
  * On **iPhone**, trying to force popovers-with-arrow everywhere: SwiftUI will adapt them into fullscreen or sheet-like UIs.

So if your requirement is:

> Tap a button and have a view appear that points to the control it spawned from

Your best options:

1. **macOS + iPadOS**: use **`.popover`**:

   ```swift
   Button("Details") { showPopover = true }
       .popover(isPresented: $showPopover, arrowEdge: .bottom) {
           DetailView()
       }
   ```

2. For more custom visuals (especially on iOS/iPadOS), build:

   * A **bubble or popover-like view** using `ZStack + GeometryReader + overlay`, and draw your own arrow.
   * A **bottom-sheet panel** using `.sheet` with `presentationDetents`, no arrow, but visually connected via content and copy.

---

If you’d like, I can:

* Draft a **single reusable “AnchoredPopover” view** that:

  * Works on macOS and iPadOS
  * Taps a button
  * Shows a bubble with a little arrow triangle
  * Automatically positions itself around the button edge using `GeometryReader`.
