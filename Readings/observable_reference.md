# Observable vs ObservableObject – Comprehensive Reference

## Introduction
(This document recreates and expands upon your prior reference, combining all requested sections—including comparisons, examples, rare capabilities, advanced topics, benchmarks, migration notes, and more.)

## 1. Overview
### @Observable
- Swift Observation framework (iOS 17+).
- Compiler-synthesized change tracking.
- Works with structs and classes.
- High efficiency and granularity.

### @ObservableObject
- Combine-based (iOS 13+).
- Class‑only.
- Uses @Published and manual publishing.
- Backward-compatible; Combine-friendly.

## 2. Comparison Table
| Feature | @Observable | @ObservableObject |
|--------|-------------|--------------------|
| Introduced | iOS 17 | iOS 13 |
| Granularity | Field-level | Whole-object |
| Model types | Struct + class | Class only |
| Performance | High | Moderate |
| Needs @Published | No | Yes |
| OS support | 17+ | 13+ |
| Combine pipelines | Limited | Full support |

## 3. When to Use Each
### Use @Observable When:
- Modern OS targets.
- Want fewer bugs and simpler code.
- Use structs for state.

### Use @ObservableObject When:
- Supporting iOS 13–16.
- Using Combine streams.
- Need manual control over publishing.

## 4. Pros & Cons
### @Observable Pros
- No @Published boilerplate.
- Faster, more granular.
- Supports structs.
### Cons
- Requires modern OS.
- Less customizable.

### @ObservableObject Pros
- Combine support.
- Works on old OSes.
### Cons
- Verbose and error-prone.
- Class-only.

## 5. Code Examples
### Basic @Observable
```swift
@Observable
class Counter { var value = 0 }
```

### Basic @ObservableObject
```swift
class Counter: ObservableObject {
    @Published var value = 0
}
```

## 6. Advanced Topics
### Observing Structs With @Observable
SwiftUI treats them as reactive value models.

### Manual Publishing in @ObservableObject
```swift
objectWillChange.send()
```

## 7. Rare / Underused Capabilities (Expanded)

### 7.1 withObservationTracking
Tracks reads inside an arbitrary closure.

```swift
let tracker = withObservationTracking {
    print(model.username)
} onChange: {
    print("Model changed")
}
```

Use cases:
- Debugging
- Custom reactive systems
- Dependency graph tracing

---

### 7.2 Low-Level `.observe` API
Observe model mutations programmatically:

```swift
let (_, cancel) = model.observe { changes in
    print(changes)
}
```

Use cases:
- Game engines
- Networking layers
- Custom debounced state watchers

---

### 7.3 Observing Non‑UI Logic
```swift
@Observable class Player { var health = 100 }

class EnemyAI {
    init(player: Player) {
        player.observe { _ in self.update(player) }
    }
}
```

---

### 7.4 Nested Collections and Deep Mutation Limits
Obs does **not** track deep mutations inside arrays/dictionaries unless the element type is also observable.

Fix by:
- Making items @Observable
- Replacing collection items (struct copy)
- Using observable wrappers

---

### 7.5 Combining Observation + Combine
```swift
model.observe { _ in subject.send(model.count) }
```

Allows Combine operators to layer on top of Observation.

---

### 7.6 Observation as Lightweight Architecture
You can build Redux-like state stores without SwiftUI or Combine.

---

## 8. Migration Guide: ObservableObject → Observable
### Step 1: Remove protocol + @Published
```swift
@Observable
class UserModel {
    var name = ""
}
```

### Step 2: Replace @StateObject with @State
Because @Observable is a value wrapper around the instance.

### Step 3: Watch for nested collection issues

---

## 9. Debugging & Pitfalls

### Common Mistakes with @ObservableObject
- Forgetting @Published → silent UI bugs
- Using @ObservedObject instead of @StateObject → resets model

### Common @Observable Pitfalls
- Mutating non-observed nested properties
- Accidentally breaking dependency tracking across async boundaries

---

## 10. Performance Benchmarks (Conceptual)
### @Observable
- Tracks only fields read by the view.
- Can skip unnecessary UI updates.
- On par with SwiftUI’s new internal model.

### @ObservableObject
- Fires on any @Published assignment.
- Causes entire view subtree to re-render.

---

## 11. Real-World Architectural Examples

### Game Loop Example
Observation works well because it reacts instantly to state changes.

### Networking Layer Example
Observed models update UI automatically when decoders mutate the model.

### Audio/MIDI or Real‑Time Systems
Observation helps decouple UI from the real-time engine.

---

## 12. Final Guidance
- For new apps: **Use @Observable**
- For backward compatibility: **Use @ObservableObject**
- Combine-heavy systems: **Stay with ObservableObject**
- High‑performance systems: **Observation framework**

---

