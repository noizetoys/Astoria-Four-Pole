Nice — here are several practical ways to **read the window size on macOS and iPadOS** (Swift). I’ll give short explanations and copy-pasteable examples for:

* SwiftUI (simple & cross-platform using `GeometryReader`)
* SwiftUI (advanced: grab the actual `NSWindow` / `UIWindow`)
* Platform-specific: AppKit `NSWindow` (macOS) and UIKit/Scenes (iPadOS)
* A small reactive pattern to observe window-size changes

---

# 1) Easiest — SwiftUI: `GeometryReader` (works on macOS & iPadOS)

Use whenever you only care about the size that SwiftUI lays out to your view (safe, simple).

```swift
import SwiftUI

struct SizeReaderView: View {
    var body: some View {
        GeometryReader { geo in
            VStack {
                Text("Width: \(Int(geo.size.width))")
                Text("Height: \(Int(geo.size.height))")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // fill
            .background(Color(.secondarySystemBackground))
        }
    }
}
```

Notes:

* `geo.size` is the **view’s layout size** inside its parent (includes safe area insets as the layout gives).
* Works the same on macOS and iPadOS in SwiftUI apps.
* Use `GeometryReader` high in the view hierarchy (e.g. top of window content) to approximate window content size.

---

# 2) When you need the *actual window* size (pixel/frame of the OS window)

Sometimes you need the real `NSWindow` frame (macOS) or `UIWindow`/`UIWindowScene` size (iPadOS). In SwiftUI you can bridge to AppKit/UIKit via representables.

## 2A — SwiftUI helper to get `NSWindow` (macOS)

```swift
import SwiftUI
import AppKit

struct WindowAccessorMac: NSViewRepresentable {
    var callback: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { // window is set after view is in hierarchy
            self.callback(view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
```

Usage inside a SwiftUI view:

```swift
struct ContentView: View {
    @State private var windowSize: CGSize = .zero

    var body: some View {
        VStack {
            Text("Window: \(Int(windowSize.width)) × \(Int(windowSize.height))")
            // rest of UI...
        }
        .background(WindowAccessorMac { window in
            if let w = window {
                self.windowSize = w.frame.size
                // You can also observe w.didResizeNotification
            }
        })
        .frame(minWidth: 300, minHeight: 200)
    }
}
```

To observe changes: register for `NSWindow.didResizeNotification` on that `NSWindow`.

## 2B — SwiftUI helper to get `UIWindow` (iPadOS / iOS)

```swift
import SwiftUI
import UIKit

struct WindowAccessorIOS: UIViewRepresentable {
    var callback: (UIWindow?) -> Void

    func makeUIView(context: Context) -> UIView {
        let v = UIView()
        DispatchQueue.main.async {
            self.callback(v.window)
        }
        return v
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
```

Usage:

```swift
struct ContentViewIOS: View {
    @State private var windowSize: CGSize = .zero

    var body: some View {
        VStack {
            Text("Window: \(Int(windowSize.width)) × \(Int(windowSize.height))")
        }
        .background(WindowAccessorIOS { win in
            if let w = win {
                self.windowSize = w.bounds.size // bounds in points
            }
        })
    }
}
```

Notes:

* On iPadOS multi-window, `v.window` returns the actual `UIWindow` for that scene.
* If you need to handle rotations or split-view changes, observe the view controller layout callbacks or KVO on `bounds` / `frame` changes.

---

# 3) Platform-specific direct methods

## macOS (AppKit)

If you control the `NSWindow` (AppKit), reading size is trivial:

```swift
let size = myWindow.frame.size            // frame in screen coordinates (points)
let contentSize = myWindow.contentLayoutRect.size // content area (excludes titlebar)
```

Observe changes:

```swift
NotificationCenter.default.addObserver(forName: NSWindow.didResizeNotification, object: myWindow, queue: .main) { _ in
    print("new size:", myWindow.frame.size)
}
```

## iPadOS (UIKit with Scenes)

If you have a SceneDelegate or a view controller:

```swift
if let windowScene = view.window?.windowScene {
    let size = windowScene.screen.bounds.size  // whole screen size for that scene
}
```

or directly from a view controller:

```swift
let size = view.window?.bounds.size ?? view.bounds.size
```

Observe layout changes in `viewWillLayoutSubviews()` / `viewDidLayoutSubviews()` or implement `view.safeAreaInsetsDidChange()`.

For multi-window apps, use the `UIScene` APIs:

```swift
for scene in UIApplication.shared.connectedScenes {
    if let scene = scene as? UIWindowScene {
        for window in scene.windows {
            let size = window.bounds.size
            // window is the actual UIWindow
        }
    }
}
```

---

# 4) Reactive pattern (Combine) — publish window size updates

Example (iOS/iPadOS) — create a publisher that emits when the main window layout changes:

```swift
import Combine
import UIKit

final class WindowSizeObserver: ObservableObject {
    @Published var size: CGSize = .zero
    private var view: UIView?

    init(hostingView: UIView) {
        self.view = hostingView
        updateSize()
    }

    func updateSize() {
        guard let v = view, let w = v.window else { return }
        size = w.bounds.size
    }
}
```

You can call `updateSize()` from `layoutSubviews()` or a SwiftUI `UIViewRepresentable` when layout changes.

For macOS, similar idea using `NSWindowDelegate` + `@Published` size.

---

# 5) Practical tips & gotchas

* **GeometryReader vs Window frame**: `GeometryReader` reports the SwiftUI layout size available to that view — which is what you usually need for responsive UI. The OS window frame (title bar, screen position) is different.
* **Safe area**: On iPad, subtract `safeAreaInsets` if you need usable content size. In SwiftUI use `safeAreaInset` or `ignoresSafeArea()` appropriately.
* **Points vs pixels**: `frame.size` are in *points*. Multiply by `window.screen.backingScaleFactor` (macOS) or `UIScreen.main.scale` (iPad) for device pixels.
* **Multiple windows/scenes**: On iPadOS, don’t assume a single `UIApplication.shared.keyWindow` — use scenes and the specific `UIWindow` for that scene.
* **When to observe**: For continuous updates prefer view controller layout methods, `NSWindow` resize notifications, or SwiftUI `onChange(of: geometry.size)` patterns.

---

# Quick examples: SwiftUI onChange + GeometryReader

```swift
struct ResponsiveView: View {
    @State private var size: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            VStack {
                Text("W: \(Int(size.width)) H: \(Int(size.height))")
            }
            .onAppear {
                size = geo.size
            }
            .onChange(of: geo.size) { newSize in
                size = newSize
            }
        }
    }
}
```

`onChange(of: geo.size)` works in iOS 14+/macOS 11+ for SwiftUI.

---

If you tell me which environment you're using right now (pure SwiftUI app, UIKit-based iPad app with scenes, AppKit macOS app, or a multiplatform target), I can drop a single polished snippet tailored exactly to that setup (including observing / Combine wiring). Want that?


To **set a window’s size in a macOS SwiftUI app**, you have a few clean options depending on **(1)** whether you use the *new SwiftUI App lifecycle* or **(2)** the *old AppKit/AppDelegate* setup.

Below are the *correct, idiomatic* ways for **macOS SwiftUI window sizing**.

---

# ✅ **1. SwiftUI App Lifecycle (macOS 11+) — via `.windowStyle` / `WindowGroup` modifiers**

The *official* SwiftUI way to control window size:

### **A) Fixed minimum / ideal / maximum window size**

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)              // The window resizes to its content
        .defaultSize(width: 800, height: 600)          // Initial window size
        .defaultMinSize(width: 400, height: 300)       // Optional
        .defaultMaxSize(width: 1200, height: 1000)     // Optional
    }
}
```

### What this does:

* `.defaultSize` = **initial size** the moment the window is created.
* `.windowResizability(.contentSize)` = makes SwiftUI’s layout define the window size.
* `.defaultMinSize` & `.defaultMaxSize` = enforce window constraints (just like AppKit).

**Starting in macOS 13+**, these modifiers are the recommended approach.

---

# ✅ **2. Programmatically setting window size (AppKit bridge inside SwiftUI)**

If you need to **resize the window later** (e.g., when the user selects "Small", "Medium", "Large" view modes), you MUST access the underlying `NSWindow`.

### Use a small `NSViewRepresentable` accessor:

```swift
import SwiftUI
import AppKit

struct WindowAccessor: NSViewRepresentable {
    var onUpdate: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                onUpdate(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let window = nsView.window {
            onUpdate(window)
        }
    }
}
```

### Then call it inside your SwiftUI view:

```swift
struct ContentView: View {
    @State private var window: NSWindow?

    var body: some View {
        VStack {
            Text("Resize Window")

            Button("Set to 800×600") {
                if let w = window {
                    w.setContentSize(NSSize(width: 800, height: 600))
                    w.center()
                }
            }

            Button("Set to 1200×800") {
                window?.setContentSize(NSSize(width: 1200, height: 800))
            }
        }
        .background(
            WindowAccessor { win in
                self.window = win
            }
        )
        .frame(width: 400, height: 200)
    }
}
```

### What this gives you:

* You can **programmatically set window size anytime**.
* No AppDelegate required.
* Works 100% in SwiftUI lifecycle apps.

---

# ✅ **3. If using AppKit AppDelegate (NSWindow / NSWindowController)**

If your app uses the older AppKit lifecycle:

### AppDelegate:

```swift
func applicationDidFinishLaunching(_ notification: Notification) {
    if let window = NSApp.windows.first {
        window.setContentSize(NSSize(width: 800, height: 600))
        window.center()
    }
}
```

If you created your own `NSWindow`:

```swift
window.setContentSize(NSSize(width: 900, height: 700))
window.makeKeyAndOrderFront(nil)
```

---

# 🎯 **Which approach should you use?**

| Need                            | Use                                    |
| ------------------------------- | -------------------------------------- |
| Set initial window size         | `.defaultSize(width:height:)`          |
| Lock min/max                    | `.defaultMinSize`, `.defaultMaxSize`   |
| Resize window in response to UI | `WindowAccessor` + `.setContentSize()` |
| Old-style AppKit window control | Direct AppKit APIs                     |

---

# If you want, tell me which of these scenarios you're in:

### **(a)** pure SwiftUI macOS app

### **(b)** macOS Catalyst

### **(c)** SwiftUI embedded in an AppKit NSWindow

### **(d)** programmatically creating multiple windows

I can produce a *minimal, perfect* snippet tailored to your exact setup.


Here are the **two correct ways** to make your macOS SwiftUI window:

### ✅ **Full Screen**

### ❌ **Not Resizable**

Because **macOS fullscreen is always resizable by the OS**, you cannot *lock the size while in native fullscreen mode* — macOS manages the space.
**BUT** you *can*:

### **Option A — Launch the window borderless at full screen size (fake fullscreen)**

### **Option B — Enter real fullscreen + disable manual resizing in normal windowed mode**

Below are both solutions.

---

# ✅ **OPTION A — “Fake Fullscreen” (Recommended if you want no resizing at all)**

This creates a **borderless window**, sized to the screen, with **no resizing possible**, and behaves like fullscreen without entering macOS’ native fullscreen mode.

### AppDelegate + NSWindow override

**App.swift**

```swift
@main
struct MyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

**AppDelegate.swift**

```swift
import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let window = NSApp.windows.first {

            // Remove title bar and resizing
            window.styleMask = [
                .borderless,       // No controls
                .fullSizeContentView
            ]

            // Make window fill the entire main screen
            if let screen = NSScreen.main {
                window.setFrame(screen.frame, display: true)
            }

            window.isMovable = false
            window.isMovableByWindowBackground = false
            window.level = .normal
        }
    }
}
```

### Result

* Window covers entire screen
* Cannot resize
* Cannot move
* Looks fullscreen
* No macOS green-button animation or “Spaces” fullscreen behavior

This is what apps like video-game launchers do.

---

# ✅ **OPTION B — Real macOS Fullscreen, but NO RESIZING in normal mode**

macOS **will allow resizing when in actual fullscreen** — this cannot be disabled —
but you *can* disable resizing **before/after fullscreen**.

### Step 1 — Disable resizing for the window

```swift
struct NoResizeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(WindowAccessor { window in
                window.styleMask.remove(.resizable)
            })
    }
}
```

### Step 2 — Enter fullscreen via window toggle

```swift
struct ContentView: View {
    @State private var window: NSWindow?

    var body: some View {
        VStack {
            Button("Go Fullscreen") {
                window?.toggleFullScreen(nil)
            }
        }
        .background(WindowAccessor { win in
            self.window = win
            win.styleMask.remove(.resizable)   // Disable resize
        })
    }
}
```

### Result

* The app **can enter fullscreen**
* Users **cannot resize the window in normal mode**
* macOS **still resizes content automatically in fullscreen** (mandatory)

If you need a game-like fullscreen where resizing never happens, use **Option A**.

---

# 🧩 Which behavior do you want?

1. **True fullscreen** (green button / its own macOS Space)
   → You cannot prevent resizing during fullscreen — only outside fullscreen.

2. **Fullscreen appearance, cannot resize ever**
   → Use **borderless fullscreen** (Option A).

3. **Fixed-size window (never fullscreen)**
   → I can give you a minimal snippet if needed.

---

If you tell me **exactly** which you want —
**A) real fullscreen**, or **B) fake fullscreen but no resizing**,
I’ll generate a perfect drop-in SwiftUI 5 project skeleton.


Below is the **correct, clean, modern SwiftUI way** to make a **single-window macOS app** with:

### ✅ **One window only (no documents, no additional windows)**

### ✅ **A fixed window size that CANNOT be resized**

### ✅ **A window that uses the exact size you choose**

### 🎯 No AppKit document architecture, no multi-window behavior.

This is the standard setup for tools, utilities, games, launchers, etc.

---

# ✅ **THE SOLUTION**

SwiftUI gives you a *single window* automatically when you use a single `WindowGroup`.
From there, we override the window’s style mask to remove `.resizable` and set a fixed size.

Here is the **fully working example**:

---

# 🚀 **App.swift (SwiftUI Lifecycle)**

```swift
import SwiftUI

@main
struct FixedWindowApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .background(FixedWindowSetup(width: 900, height: 600))
        }
        // Prevent multiple windows
        .defaultSize(width: 900, height: 600)
        .windowResizability(.contentSize)
    }
}
```

---

# 🪟 **FixedWindowSetup** — Enforces window size & disables resizing

```swift
import SwiftUI
import AppKit

struct FixedWindowSetup: NSViewRepresentable {
    let width: CGFloat
    let height: CGFloat

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                configure(window: window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let window = nsView.window {
            configure(window: window)
        }
    }

    private func configure(window: NSWindow) {
        let size = NSSize(width: width, height: height)

        // Set initial size
        window.setContentSize(size)

        // Lock size (cannot resize)
        window.minSize = size
        window.maxSize = size

        // Remove resizing ability
        window.styleMask.remove(.resizable)

        // Optional: prevent full screen
        // window.collectionBehavior.remove(.fullScreenPrimary)

        // Optional: center window
        window.center()
    }
}
```

---

# 🧱 **ContentView.swift**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("Fixed-size single-window macOS app")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
    }
}
```

---

# 🧾 **What this gives you**

### ✔ Fixed, exact window size (900 × 600 in the example)

### ✔ No resizing of ANY kind

### ✔ Only ONE window in the whole app

### ✔ No document architecture

### ✔ Works in SwiftUI macOS apps with no AppKit boilerplate

### ✔ Window stays fixed even if user tries to drag the edges

### ✔ Optional: disable fullscreen entirely

---

# 🔒 Optional: Disable Fullscreen Button

Add this line inside `configure(window:)`:

```swift
window.collectionBehavior.remove(.fullScreenPrimary)
```

This removes the green fullscreen button.

---

# 🔒 Optional: Remove ALL titlebar controls

Add:

```swift
window.titleVisibility = .hidden
window.titlebarAppearsTransparent = true
window.standardWindowButton(.zoomButton)?.isHidden = true
window.standardWindowButton(.miniaturizeButton)?.isHidden = true
window.standardWindowButton(.closeButton)?.isHidden = false // change as desired
```

---

# 🎉 If you'd like…

I can produce variants for:

* **Borderless fixed-size window (game launcher style)**
* **Window with hidden title bar**
* **Non-resizable but still allows fullscreen**
* **Multiple fixed-size windows**
* **macOS Catalyst version**
* **SwiftUI 6 .windowStyle approach**

Just tell me what style you want → I’ll generate the exact code.
