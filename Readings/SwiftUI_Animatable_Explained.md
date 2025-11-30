# SwiftUI `animatableData` Explanation and Improved Approaches

## 1. Original Explanation

This document explains how the following property works:

``` swift
var animatableData: AnimatablePair<Double, AnimatablePair<Double, AnimatablePair<Double, Double>>> {
    get {
        let normalizedAttack = log(attackTimeMs / 2.0) / log(30000.0)
        return AnimatablePair(normalizedAttack,
            AnimatablePair(decay,
                AnimatablePair(sustain, release)
            )
        )
    }
    set {
        let normalizedAttack = max(0, min(1, newValue.first))
        attackTimeMs = 2.0 * exp(normalizedAttack * log(30000.0))
        decay = newValue.second.first
        sustain = newValue.second.second.first
        release = newValue.second.second.second
    }
}
```

SwiftUI can only animate values conforming to `VectorArithmetic`.\
`Double` works, and `AnimatablePair<A,B>` works.\
To animate 4 doubles, the values must be nested:

    (a, (b, (c, d)))

### Why the Log Scaling?

`attackTimeMs` represents a time parameter for audio envelopes. Human
perception reacts more naturally to changes on a **logarithmic** scale,
so the animation uses a normalized log-scale value instead of
interpolating milliseconds linearly.

### Getter Summary

-   Converts **attackTimeMs → normalized log value (0--1)**.
-   Packages (attack, decay, sustain, release) into nested
    `AnimatablePair` structures.

### Setter Summary

-   SwiftUI provides interpolated values during animation.
-   These are unpacked from the nested pairs.
-   The attack value is converted **back to milliseconds** using the
    inverse of the normalization.

------------------------------------------------------------------------

## 2. Cleaner Version Using a Custom Type

You can greatly simplify readability by defining your own animatable
struct.

### Custom Animatable ADSR Type

``` swift
struct ADSRAnimatable: VectorArithmetic {
    var attack: Double
    var decay: Double
    var sustain: Double
    var release: Double

    static var zero = ADSRAnimatable(attack: 0, decay: 0, sustain: 0, release: 0)

    static func + (lhs: Self, rhs: Self) -> Self {
        ADSRAnimatable(
            attack: lhs.attack + rhs.attack,
            decay: lhs.decay + rhs.decay,
            sustain: lhs.sustain + rhs.sustain,
            release: lhs.release + rhs.release
        )
    }

    static func - (lhs: Self, rhs: Self) -> Self {
        ADSRAnimatable(
            attack: lhs.attack - rhs.attack,
            decay: lhs.decay - rhs.decay,
            sustain: lhs.sustain - rhs.sustain,
            release: lhs.release - rhs.release
        )
    }

    mutating func scale(by amount: Double) {
        attack *= amount
        decay *= amount
        sustain *= amount
        release *= amount
    }

    var magnitudeSquared: Double {
        attack*attack + decay*decay + sustain*sustain + release*release
    }
}
```

### Using It in Your View

``` swift
var animatableData: ADSRAnimatable {
    get {
        let normAttack = log(attackTimeMs / 2.0) / log(30000.0)
        return ADSRAnimatable(
            attack: normAttack,
            decay: decay,
            sustain: sustain,
            release: release
        )
    }
    set {
        attackTimeMs = 2.0 * exp(newValue.attack * log(30000.0))
        decay = newValue.decay
        sustain = newValue.sustain
        release = newValue.release
    }
}
```

This keeps your UI code clean while retaining full animation behavior.

------------------------------------------------------------------------

## 3. Generic "Any Number of Animatable Values" System

If you want something extremely flexible, you can create a reusable type
that stores an arbitrary number of doubles and makes them animatable.

### Generic Animatable Array

``` swift
struct AnimatableVector: VectorArithmetic {
    var values: [Double]

    static var zero = AnimatableVector(values: [])

    static func + (lhs: Self, rhs: Self) -> Self {
        AnimatableVector(values: zip(lhs.values, rhs.values).map(+))
    }

    static func - (lhs: Self, rhs: Self) -> Self {
        AnimatableVector(values: zip(lhs.values, rhs.values).map(-))
    }

    mutating func scale(by amount: Double) {
        values = values.map { $0 * amount }
    }

    var magnitudeSquared: Double {
        values.map { $0 * $0 }.reduce(0, +)
    }
}
```

### Using It for ADSR

``` swift
var animatableData: AnimatableVector {
    get {
        let normAttack = log(attackTimeMs / 2.0) / log(30000.0)
        return AnimatableVector(values: [
            normAttack, decay, sustain, release
        ])
    }
    set {
        attackTimeMs = 2.0 * exp(newValue.values[0] * log(30000.0))
        decay = newValue.values[1]
        sustain = newValue.values[2]
        release = newValue.values[3]
    }
}
```

This system is fully scalable and ideal for animating models with many
properties.

------------------------------------------------------------------------

# Summary

  ------------------------------------------------------------------------
  Approach                       Pros                 Cons
  ------------------------------ -------------------- --------------------
  **Nested `AnimatablePair`**    Works out of the     Hard to read,
                                 box, no extra types  unwieldy for 3+
                                                      values

  **Custom `ADSRAnimatable`**    Clean, readable,     Requires manual
                                 reusable             VectorArithmetic
                                                      conformance

  **Generic `AnimatableVector`** Can animate *any     Slightly more
                                 number* of           overhead
                                 properties           
  ------------------------------------------------------------------------

This file contains all three explanations and their implementations.
