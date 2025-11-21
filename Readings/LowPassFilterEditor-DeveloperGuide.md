# Low Pass Filter Editor – Developer Guide

This document explains how the **LowPassFilterEditor** and **FilterResponseView** work, and shows several options for extending or reusing the code in other audio–UI contexts.

---

## 1. Architectural Overview

The filter editor is made of two main pieces:

1. `LowPassFilterEditor` (high–level UI)
   - Manages user–facing parameters (cutoff, resonance, modulation).
   - Presents sliders, pickers, and status indicators.
   - Owns the state in MIDI–style 0–127 ranges.

2. `FilterResponseView` (visualization)
   - Renders a **log–frequency grid** (20 Hz → 20 kHz).
   - Computes a **24 dB/octave** low–pass response.
   - Converts dB values into screen coordinates.
   - Shows modulation arrows for visual feedback.

You can think of `LowPassFilterEditor` as a **controller** and `FilterResponseView` as a **view** over a mathematical model of the filter.

---

## 2. Parameter Model and Ranges

### 2.1 MIDI–style Ranges (0–127)

All primary controls use **0–127** as their internal representation:

- `frequency`: 0 → 127 maps to 20 Hz → 20 kHz (logarithmically).
- `resonance`: 0 → 127 maps to a Q range (0.707 → max Q).
- `frequencyModAmount`: 0 → 127 maps to –100% → +100%.
- `resonanceModAmount`: 0 → 127 maps to –100% → +100%.

This has several advantages:

- Easy integration with MIDI/CC.
- Easy storage (fits in 7 bits).
- Clear, device–style semantics (“this value is the *raw* parameter”).

### 2.2 Frequency Conversion (0–127 → 20 Hz–20 kHz)

```swift
private func frequencyToHz(_ value: Double) -> Double {
    let minFreq = log10(20.0)
    let maxFreq = log10(20000.0)
    let normalized = value / 127.0
    let logFreq = minFreq + normalized * (maxFreq - minFreq)
    return pow(10, logFreq)
}
```

**Key ideas:**

- Work in **log space** (`log10`) so each octave is equally spaced on the UI.
- Interpolate between log(20) and log(20000).
- Convert back to linear Hz with `pow(10, logFreq)`.

You can change the min/max range for a more “analog synth” feel, for example:

- 16 Hz → 16 kHz
- 30 Hz → 12 kHz
- 80 Hz → 8 kHz (for a low–pass dedicated to mid/treble work).

---

## 3. Resonance, Q Factor, and Self–Oscillation

The function `resonanceToQ(_:)` maps 0–127 into a Q range:

```swift
private func resonanceToQ(_ value: Double) -> Double {
    if value < 1 { return 0.707 }   // Butterworth (no peak)
    let normalized = value / 127.0
    return 0.707 + pow(normalized, 1.2) * 3.0
}
```

Notes:

- A Q of **0.707** is the classic **Butterworth** value (maximally flat magnitude).
- The `pow(normalized, 1.2)` makes the curve **non–linear** so that small resonance values only slightly bump Q, and higher resonance values ramp up more aggressively.
- The `* 3.0` factor sets the maximum additional Q.

To increase the dramatics of the resonance peak:

- Raise the multiplier: `* 3.0` → `* 5.0` or higher.
- Adjust the exponent: `pow(normalized, 1.2)` → `pow(normalized, 1.5)` for a more sudden onset.

You can also clamp or remap the range for each specific synth emulation.

---

## 4. 24 dB/Octave Low–Pass Response

The 24 dB/oct low–pass response is modeled as a **4th–order filter** made from **two cascaded biquads**:

```swift
private func lowPassResponse24dB(freq: Double, cutoff: Double, Q: Double) -> Double {
    let ratio = freq / cutoff
    if ratio < 0.00001 { return 0 } // DC

    let s = ratio
    let butterQ1 = 0.541
    let butterQ2 = 1.307

    let q1 = butterQ1 + (Q - 0.707) * 1.5
    let q2 = butterQ2 + (Q - 0.707) * 1.0

    let denom1 = pow(1.0 - s*s, 2) + pow(s / q1, 2)
    let denom2 = pow(1.0 - s*s, 2) + pow(s / q2, 2)

    let mag1Sq = 1.0 / denom1
    let mag2Sq = 1.0 / denom2

    let magnitude = sqrt(mag1Sq * mag2Sq)
    return 20 * log10(max(1e-8, magnitude))
}
```

### Why Two Biquads?

- A single biquad is **2nd order**, ~12 dB/oct at far above cutoff.
- Two cascaded biquads give **4th order**, ~24 dB/oct.
- This is standard for many analog synth low–pass filters.

### How Resonance is Distributed

We start from two base Q values (`butterQ1`, `butterQ2`) and add the user–defined Q:

- First stage gets more resonance (`* 1.5`).
- Second stage gets a bit less (`* 1.0`).

You can experiment with these multipliers to change the **shape** of the resonance peak:

- Higher `* 1.5` makes the first stage dominate.
- Adjusting these independently lets you emulate different hardware topologies.

---

## 5. From dB to Screen Coordinates

The visualization is *not* the audio filter itself, but a mapping from dB values into pixel positions.

### 5.1 Baseline and Margins

- `baselineY` (e.g., `height * 0.45`) is the **0 dB line**.
- Above baseline: resonance peak region.
- Below baseline: roll–off / attenuation region.
- `topMargin` reserves room for resonance to draw without hitting the very top.
- `bottomThreshold` is where we stop rendering the line (no horizontal line to the right).

### 5.2 Visual Slope Steepness

The critical line in the slope section is:

```swift
let normalizedAttenuation = min(1.0, abs(response) / 90.0)
```

- Smaller divisor (e.g., `90.0`) → **steeper visual slope** because you reach maximum attenuation (normalized = 1) faster.
- Larger divisor (e.g., `160.0` or `200.0`) → **gentler visual slope** because the line takes longer to bottom out.

This mapping only changes the **drawing**, not the underlying dB values.

---

## 6. Alternative Rendering Approaches

The current implementation uses `Path` and `stroke` inside SwiftUI. Here are several other approaches if you want more flexibility or performance.

### 6.1 `Canvas` (SwiftUI)

`Canvas` gives you low–level drawing primitives with better performance and fine–grained control.

Use it if:

- You need to render multiple curves in real time (e.g., modulation preview).
- You want per–segment styling, gradients, or blending.

High–level idea:

```swift
Canvas { context, size in
    let path = makeFilterCurvePath(size: size)
    context.stroke(path, with: .color(.blue), lineWidth: 3)
}
```

You can reuse your existing math (frequency → x, dB → y) directly inside `makeFilterCurvePath`.

### 6.2 Metal/Shader–Based Rendering

Use a custom **Metal shader** or **Core Animation layer** if you:

- Need extremely smooth animations at high frame rates.
- Want to render many simultaneous filters (e.g., EQ bands, multi–filter UI).
- Want GPU–accelerated transitions or special effects (glows, dynamic blur).

In this case:

- Precompute your dB values on the CPU, or compute them in a compute shader.
- Pass them as uniform buffers/vertex data to a Metal pipeline.
- Render as line strips or triangle strips.

### 6.3 CoreImage / Offscreen Rendering

`CoreImage` is more commonly used for image filters, but you could:

- Render an offscreen image of the curve using Core Graphics.
- Apply glow, blur, or color grading via CoreImage filters.
- Present the final result as an `Image` in SwiftUI.

This is overkill for static curves but can be handy when the filter curve is one part of a larger composited UI.

---

## 7. Comparative Slopes: 12 dB, 24 dB, 36 dB, 48 dB

To understand how slope order affects visuals and sound, it can be useful to compare:

- **12 dB/oct (2nd order)** – gentle, musical, more “open” sound.
- **24 dB/oct (4th order)** – classic synth low–pass, strong separation between passband and stopband.
- **36 dB/oct (6th order)** – very steep, more surgical but can ring.
- **48 dB/oct (8th order)** – extremely steep, often for special–effect or digital EQ scenarios.

You could expose this in the UI as:

- A “slope” selector (12, 24, 36, 48).
- Internally: number of biquad stages (1, 2, 3, 4).

Each additional biquad adds another 12 dB/oct to the far–above–cutoff slope.

### 7.1 Example Table

| Order | Approx. Slope | Typical Use Case                      |
|-------|---------------|---------------------------------------|
| 2nd   | 12 dB/oct     | Gentle tone shaping, musical filters |
| 4th   | 24 dB/oct     | Classic synth low–pass                |
| 6th   | 36 dB/oct     | Strong isolation of bands             |
| 8th   | 48 dB/oct     | Surgical filtering / special FX      |

---

## 8. Extending the UI and the Editor

Here are some ideas for extending the current component into a full–featured filter module:

1. **Multiple Filter Types**
   - Add high–pass, band–pass, notch, and peak modes.
   - Parameterize the response function by filter type.

2. **Drive / Saturation**
   - Add an input drive parameter and approximate its effect visually (e.g., slightly lifting the passband and adding color changes).

3. **Modulation Visualization**
   - Animate the cutoff position using the modulation depth.
   - Draw a “shadow” curve that shows the range of motion as modulation is applied.

4. **A/B Comparison**
   - Let the user store two snapshots (A and B) of parameter sets.
   - Show both curves overlapped (e.g., one in blue, one in orange).

5. **MIDI Integration**
   - Map filter parameters to MIDI CCs.
   - Update the view live from hardware.

---

## 9. Homework / Practice Ideas

To solidify your understanding, try the following exercises:

1. **Implement a 12 dB/oct Filter Curve**
   - Remove one biquad from the response function and redraw.
   - Compare the visual and conceptual difference.

2. **Add a `slopeOrder` Parameter**
   - Let the user choose between 12/24/36/48 dB/oct.
   - Internally, change how many times you apply the biquad magnitude.

3. **Visualize Modulation Range**
   - Draw a second, faint curve representing the maximum positive modulation of cutoff.
   - Optionally draw a third one for maximum negative modulation.

4. **Resonance–Sensitive Coloring**
   - Change the curve’s color gradually as resonance increases.
   - For example: blue → green → yellow → orange → red as you approach self–oscillation.

Working through these will give you a deep, practical grasp of:

- Mapping math models to visuals.
- Controlling the tradeoff between realism and clarity.
- How to scale this component into a complete filter editor or synth front–end.

---

**End of Guide**  
You can safely copy and adapt any part of this for other filters (high–pass, band–pass, EQ, etc.).
