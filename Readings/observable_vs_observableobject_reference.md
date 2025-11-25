# Observable vs ObservableObject in SwiftUI

## Introduction
This document compares `@Observable` (introduced with Swift's new Observation framework) and `@ObservableObject` (part of Combine and used in SwiftUI since iOS 13). It explains similarities, differences, pros/cons, edge cases, use cases, issues, advanced topics, and includes example code.

---

## Overview

### `@Observable`
- Part of Swift's native **Observation** framework.
- Provides **automatic change tracking** via compiler synthesis.
- Designed for **value-type and reference-type models**.
- More efficient and less boilerplate compared to Combine.
- Compatible with SwiftUI starting iOS 17, macOS 14.

### `@ObservableObject`
- Part of **Combine**.
- Used heavily in SwiftUI from iOS 13 to iOS 16.
- Requires `@Published` properties for change notifications.
- More manual, more overhead.
- Still necessary for older OS targets.

---

## Comparison Table

| Feature | `@Observable` | `@ObservableObject` |
|--------|----------------|----------------------|
| Framework | Swift Observation | Combine |
| Introduced | iOS 17 | iOS 13 |
| Model types | Class or struct | Class only |
| Update mechanism | Automatic (compiler synthesized) | `@Published` and manual publishing |
| Requires protocol? | No | Yes (`ObservableObject`) |
| Change granularity | Field-level tracking | Whole-object updates |
| Performance | High (uses access tracking) | Lower (KVO-like) |
| Works outside SwiftUI | Yes | Limited |
| Observable collections | Via macros | Requires custom wrappers |
| Observation in non-view code | Easy | Often clunky |
| Backward compatibility | Low | High |

---

## When to Use `@Observable`

### **Use when:**
- Targeting **iOS 17+ or macOS 14+**.
- You want **automatic tracking** without `@Published`.
- You prefer using **structs** instead of classes.
- You want **fast, granular updates**.
- You need observation in **non-SwiftUI contexts**.

### **Avoid when:**
- You must support **older OS versions**.
- You rely on Combine pipelines.
- You use Objective‑C interoperability (Observation does not support it).

---

## When to Use `@ObservableObject`

### **Use when:**
- Supporting **iOS 13–16**.
- You already have an app structured around Combine.
- You need **fine-grained control** over update notifications.
- You're using **Combine publishers** extensively.

### **Avoid when:**
- Building new apps for modern OSes.
- You want leaner, faster code.
- You need to observe **structs**.

---

## Pros & Cons

### `@Observable`
**Pros:**
- Minimal boilerplate.
- Supports structs **and** classes.
- Granular, efficient change tracking.
- No need for `@Published`.
- Cleaner code and easier to maintain.

**Cons:**
- Requires newest OS versions.
- Cannot customize publishing behavior.
- Limited interoperability with Combine.
- Observation tracking can be subtle (e.g., non-isolated tasks).

### `@ObservableObject`
**Pros:**
- Backward compatible.
- Compatible with Combine pipelines.
- Introspectable with `objectWillChange`.
- Control over publishing (manual or `@Published`).

**Cons:**
- Boilerplate-heavy.
- Class-only.
- Less efficient.
- Easy to forget `@Published`, causing silent UI failures.

---

## Code Examples

### Basic `@Observable` Example
```swift
import Observation

@Observable
class CounterModel {
    var count = 0
}

struct ExampleView: View {
    @State private var model = CounterModel()

    var body: some View {
        VStack {
            Text("Count: \(model.count)")
            Button("Increment") { model.count += 1 }
        }
    }
}
```

### Basic `@ObservableObject` Example
```swift
class CounterModel: ObservableObject {
    @Published var count = 0
}

struct ExampleView: View {
    @StateObject private var model = CounterModel()

    var body: some View {
        VStack {
            Text("Count: \(model.count)")
            Button("Increment") { model.count += 1 }
        }
    }
}
```

---

## Advanced Behaviors

### Observing Structs (only with `@Observable`)
```swift
@Observable
struct Settings {
    var volume: Double = 0.5
}

struct AudioView: View {
    @State private var settings = Settings()

    var body: some View {
        Slider(value: $settings.volume)
    }
}
```

### Manually controlling publishes (`@ObservableObject`)
```swift
class LoginModel: ObservableObject {
    let objectWillChange = PassthroughSubject<Void, Never>()
    var username: String = "" {
        willSet { objectWillChange.send() }
    }
}
```

---

## Advanced Observation Mechanics

### Field-Level Observation (`@Observable`)
- Only properties actually **read** by the view trigger updates.
- This avoids unnecessary redraws.

### Whole-Object Observation (`@ObservableObject`)
- Any `@Published` property fires a single `objectWillChange`.
- Less efficient, but more predictable.

---

## Edge Cases & Issues

### `@Observable`: Known Issues
- Mutation inside an actor can confuse tracking.
- Nested data structures may not publish deeply.
- Passing observed models across tasks may break tracking.

### `@ObservableObject`: Common Issues
- Forgetting `@Published` on a property.
- Using `@ObservedObject` instead of `@StateObject` (causing resets).
- Collections (arrays, dictionaries) don’t publish element-level changes.

---

## Rare/Underused Capabilities

### `withObservationTracking` (powerful but underused)
```swift
let tracker = withObservationTracking {
    print(model.value)
} onChange: {
    print("Model changed!")
}
```

### Observation outside SwiftUI
```swift
let (_, cancellable) = model.observe { changes in
    print("Updated: \(changes)")
}
```

### Custom Publishers in `@ObservableObject`
```swift
extension CounterModel {
    var doubledPublisher: AnyPublisher<Int, Never> {
        $count.map { $0 * 2 }.eraseToAnyPublisher()
    }
}
```

---

## Guidance for Choosing

### Choose `@Observable` if:
- Building a new app.
- Targeting modern OSes.
- You prefer cleaner, faster data models.

### Choose `@ObservableObject` if:
- Supporting older OS versions.
- You need Combine.
- You want explicit control over publishing behavior.

---

## Final Notes
- `@Observable` is the future direction of Apple platforms.
- `@ObservableObject` remains relevant for legacy support.
- Both coexist peacefully; you can mix them when needed.

---

## Summary Diagram
```
                 ┌────────────────────────────┐
                 │        @Observable          │
                 │  (+ Modern, Fast, Simple)  │
                 └────────────▲───────────────┘
                                
                                (Use for new apps)
                                
                 ┌────────────────────────────┐
                 │     @ObservableObject      │
                 │ (+ Legacy, Combine-friendly)│
                 └────────────▼───────────────┘
```

---

If you want, I can add:
- inline diagrams
- flowcharts on the decision-making process
- more complex examples (networking, game loops, data stores)
- performance benchmarks
- migration guide from one to the other

