# Swift Concurrency: `Task` — Master Class

> Complete guide, examples, gotchas, best practices, and runnable playground.

---

## Table of Contents
1. Overview
2. Task types & creation
3. Cancellation
4. `async let` and `TaskGroup`
5. Actors + Tasks
6. Task priorities
7. Common patterns (ViewModel, debounce, timeouts)
8. Gotchas & pitfalls
9. Best practices
10. Examples (runnable)
11. Appendix: Useful APIs

---

## 1. Overview
A `Task` represents a unit of asynchronous work in Swift's concurrency model. Tasks are lightweight, cooperatively scheduled, and can return values or throw errors. Tasks integrate with actors and structured concurrency rules.

---

## 2. Task types & creation

### 2.1 Unstructured task (top-level)
```swift
Task {
    // runs in current context (actor inheritance applies)
    let value = await fetchValue()
    print("Value:", value)
}
```

### 2.2 Detached task
```swift
Task.detached {
    // runs independently of actor isolation / parent
    await independentWork()
}
```
Use detached sparingly. Detached tasks do not inherit actor context or priority.

### 2.3 Tasks with return value
```swift
let task = Task { () -> Int in
    return await compute()
}
let result = await task.value   // awaits and rethrows if needed
```

### 2.4 Child tasks and structured concurrency
Creating tasks inside another Task makes them children — cancellation flows from parent to children.

---

## 3. Cancellation
Cancellation is cooperative. Calling `task.cancel()` sets cancellation state. Code must check `Task.isCancelled` or call `try Task.checkCancellation()` to stop.

```swift
let t = Task {
    for i in 0..<1000 {
        try Task.checkCancellation()
        // work...
    }
}
t.cancel()
```

Use `Task.checkCancellation()` to throw `CancellationError` for early exit.

---

## 4. `async let` and `TaskGroup`

### 4.1 `async let`
Good for a fixed number of child tasks that start immediately:
```swift
async let a = fetchA()
async let b = fetchB()
let (ra, rb) = await (try await a, try await b)
```

### 4.2 `withTaskGroup` (dynamic concurrency)
```swift
func fetchAll(urls: [URL]) async throws -> [Data] {
    return try await withThrowingTaskGroup(of: Data.self) { group in
        for url in urls {
            group.addTask { try await fetch(url) }
        }
        var results: [Data] = []
        for try await data in group {
            results.append(data)
        }
        return results
    }
}
```

`TaskGroup` lets you `addTask` dynamically and `for await` results as they complete.

---

## 5. Actors + Tasks
Actors protect mutable state. Use `await` to call actor functions. Avoid `Task.detached` when you need actor isolation.

```swift
actor Counter {
    private var value = 0
    func increment() { value += 1 }
    func read() -> Int { value }
}

let c = Counter()
Task {
    await c.increment()
    print(await c.read())
}
```

To run background work and update actor/UI afterwards:
```swift
Task.detached(priority: .background) {
    let data = await heavyCompute()
    await MainActor.run { model.data = data }
}
```

---

## 6. Task priorities
You can pass `priority:` to `Task` or `Task.detached`. Priority is advisory to the scheduler; avoid relying on it for correctness.

```swift
Task(priority: .userInitiated) {
    // high priority work
}
```

Be cautious of priority inversion (a high-priority task waiting on low-priority work).

---

## 7. Common patterns

### 7.1 ViewModel with cancellable load
```swift
@MainActor
class VM: ObservableObject {
    @Published var items: [String] = []
    private var loadTask: Task<Void, Never>?

    func load() {
        loadTask?.cancel()
        loadTask = Task {
            do {
                let newItems = try await fetchItems()
                self.items = newItems
            } catch {
                if Task.isCancelled { return }
                print("Load error:", error)
            }
        }
    }
}
```

### 7.2 Debounce pattern
```swift
class SearchModel: ObservableObject {
    @Published var results: [String] = []
    private var searchTask: Task<Void, Never>?

    func update(query: String) {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            if Task.isCancelled { return }
            let r = await performSearch(query)
            await MainActor.run { results = r }
        }
    }
}
```

### 7.3 Timeout wrapper
```swift
func withTimeout<T>(_ seconds: Double, operation: @escaping () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask { try await operation() }
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw CancellationError()
        }
        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}
```

---

## 8. Gotchas & pitfalls
- **Cancellation is cooperative** — always check for cancellation if work can be long-running.
- **Detached tasks break actor isolation** and may cause race conditions.
- **SwiftUI `.onAppear` + `Task {}` leaks** if not cancelled or used carelessly; prefer `.task` modifier.
- **Blocking the thread** (e.g., using long synchronous I/O) inside Task can starve the scheduler.
- **Accidental retain cycles**: `Task { self.doSomething() }` can capture `self`; use `[weak self]` closures by making an explicit `Task { [weak self] in ... }` with careful unwrapping.
- **Priority inversion**: a high priority task depending on low priority work may be delayed.

---

## 9. Best practices (summary)
- Prefer structured concurrency (`async let`, `withTaskGroup`, `Task` inside well-defined lifecycles).
- Minimize `Task.detached`.
- Check for cancellation in loops or long operations.
- Use `MainActor.run` to update UI from background tasks.
- Cancel previous tasks when starting new ones (debounce, reload).
- Avoid expensive synchronous work on the main actor.

---

## 10. Examples (runnable)
Below are several runnable examples. Save them in an Xcode playground `Contents.swift` or an Xcode project.

### Example 1 — Basic Task and cancellation
```swift
import Foundation

let t = Task {
    for i in 1...10 {
        try Task.checkCancellation()
        print("tick", i)
        try await Task.sleep(nanoseconds: 300_000_000)
    }
    print("done")
}

Task {
    try await Task.sleep(nanoseconds: 1_000_000_000)
    t.cancel()
    print("requested cancel")
}
```

### Example 2 — async let
```swift
import Foundation

func fetchA() async -> String {
    try? await Task.sleep(nanoseconds: 500_000_000)
    return "A"
}
func fetchB() async -> String {
    try? await Task.sleep(nanoseconds: 800_000_000)
    return "B"
}

Task {
    async let a = fetchA()
    async let b = fetchB()
    let (ra, rb) = await (a, b)
    print("results:", ra, rb)
}
```

### Example 3 — withTaskGroup
```swift
import Foundation

func compute(_ n: Int) async -> Int {
    try? await Task.sleep(nanoseconds: UInt64(200_000_000 + (n * 10_000_000)))
    return n * n
}

Task {
    await withTaskGroup(of: Int.self) { group in
        for i in 1...8 {
            group.addTask { await compute(i) }
        }
        var results: [Int] = []
        for await r in group {
            results.append(r)
            print("completed", r)
        }
        print("all results:", results)
    }
}
```

### Example 4 — Actor + Task
```swift
import Foundation

actor BankAccount {
    private var balance: Int = 0
    func deposit(_ amount: Int) { balance += amount }
    func withdraw(_ amount: Int) -> Bool {
        guard balance >= amount else { return false }
        balance -= amount
        return true
    }
    func read() -> Int { balance }
}

let account = BankAccount()
Task {
    await account.deposit(100)
    print("balance after deposit:", await account.read())
}
```

---

## 11. Appendix — Useful APIs
- `Task { }`, `Task.detached { }`
- `Task.sleep(nanoseconds:)`
- `Task.checkCancellation()`
- `Task.isCancelled`
- `withTaskGroup`, `withThrowingTaskGroup`
- `async let`
- `MainActor.run { }`
- `Task.yield()` (give up time slice to allow other tasks to run)

---

## Credits and Further Reading
- Swift Concurrency documentation (Apple)
- Swift Evolution proposals SE-0304 and related threads
- Concurrency Talks and WWDC sessions

---

