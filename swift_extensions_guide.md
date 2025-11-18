# Swift Extensions: Complete Guide (Including Actors)

## Overview

This document explains how Swift extensions behave across all major
types, with special focus on **Actors**, **Classes**, **Structs**,
**Enums**, and **Protocols**. It includes examples, rules, and a final
cheat‑sheet.

------------------------------------------------------------------------

# 1. Actor Extensions

## Key Rules

-   Functions in an actor extension are **actor-isolated by default**.
-   Must be called with `await` from outside the actor.
-   Can be marked `nonisolated` for globally safe access.
-   Extensions cannot add stored properties.

## Examples

### Example 1 --- Normal actor extension (isolated)

``` swift
actor SynthEngine {
    var volume: Int = 64
}

extension SynthEngine {
    func setVolume(_ v: Int) {
        volume = v
    }
}
```

Usage:

``` swift
let engine = SynthEngine()
await engine.setVolume(100)   // must use await
```

### Example 2 --- Nonisolated actor extension

``` swift
actor SynthEngine {
    let model = "SE-01"
}

extension SynthEngine {
    nonisolated func version() -> String {
        "1.0.0"
    }
}
```

Usage:

``` swift
let engine = SynthEngine()
print(engine.version())       // no await needed
```

------------------------------------------------------------------------

# 2. Class Extensions

## Key Rules

-   Methods behave the same as if defined in the class.
-   Cannot add stored properties.
-   Can add protocol conformance.
-   Can override superclass methods only in the main class body (not in
    an extension).

## Examples

``` swift
class Filter {
    func cutoff() -> Int { 100 }
}

extension Filter {
    func resonance() -> Int { 50 }
}
```

Usage:

``` swift
let f = Filter()
print(f.resonance())
```

------------------------------------------------------------------------

# 3. Struct Extensions

## Key Rules

-   Cannot add stored properties.
-   Can add methods, computed properties, and protocol conformance.

## Example

``` swift
struct Envelope {
    var attack: Double
    var decay: Double
}

extension Envelope {
    var totalTime: Double { attack + decay }
}
```

------------------------------------------------------------------------

# 4. Enum Extensions

## Key Rules

-   Cannot add new cases.
-   Can add computed properties, methods, protocol conformance.

## Example

``` swift
enum Waveform {
    case sine, square, saw
}

extension Waveform {
    var description: String {
        switch self {
        case .sine: return "Smooth"
        case .square: return "Harmonic"
        case .saw: return "Bright"
        }
    }
}
```

------------------------------------------------------------------------

# 5. Protocol Extensions

## Key Rules

-   Cannot add stored properties.
-   Can add default method implementations.
-   Cannot require conformance to another protocol from the extension.

## Example

``` swift
protocol Processor {
    func process()
}

extension Processor {
    func reset() {
        print("Resetting to default...")
    }
}
```

------------------------------------------------------------------------

# 6. Summary Table

  -----------------------------------------------------------------------------------------
  Type           Stored Properties New Methods       Protocol Conformance   Notes
  -------------- ----------------- ----------------- ---------------------- ---------------
  **Actor**      ❌                ✅                ✅                     Methods
                                                                            isolated unless
                                                                            `nonisolated`

  **Class**      ❌                ✅                ✅                     Cannot override
                                                                            in extension

  **Struct**     ❌                ✅                ✅                     Pure value-type
                                                                            behavior

  **Enum**       ❌                ✅                ✅                     Cannot add
                                                                            cases

  **Protocol**   ❌                Default           N/A                    No stored
                                   implementations                          properties
                                   only                                     
  -----------------------------------------------------------------------------------------

------------------------------------------------------------------------

# 7. Cheat Sheet

## When to Use Extensions

-   Group related behavior
-   Add protocol conformances
-   Organize code into logical modules
-   Add convenience initializers (for classes/structs/enums)
-   Add computed properties and helper methods

## When *Not* to Use Extensions

-   When you need stored properties\
-   When you need to override class methods\
-   When adding enum cases\
-   When changing actor isolation rules unintentionally

## Actor Isolation Quick Reference

-   `func f()` inside extension → **isolated**
-   `nonisolated func f()` → **not isolated**
-   Accessing actor state always requires `await`
-   Nonisolated methods may only access static or Sendable values safely

## Extension Safety Rules

### ✔ Allowed

-   Methods\
-   Computed properties\
-   Convenience initializers\
-   Protocol conformances

### ❌ Not Allowed

-   Stored properties\
-   Deinitializers\
-   Designated initializers (except in structs)

------------------------------------------------------------------------

# End of Document
