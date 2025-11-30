# LFO Tracer View - Educational Guide

This guide explains the key concepts, mathematics, and SwiftUI techniques used in the LFO Tracer View application.

## Table of Contents
1. [What is an LFO?](#what-is-an-lfo)
2. [Understanding Phase and Radians](#understanding-phase-and-radians)
3. [The Animation Loop](#the-animation-loop)
4. [Waveform Mathematics](#waveform-mathematics)
5. [SwiftUI Drawing Concepts](#swiftui-drawing-concepts)
6. [Logarithmic Frequency Control](#logarithmic-frequency-control)
7. [Musical Note Conversion](#musical-note-conversion)

---

## What is an LFO?

An **LFO (Low Frequency Oscillator)** is a repeating waveform that cycles at frequencies typically below human hearing range (< 20 Hz).

### Key Terms:
- **Frequency (Hz)**: How many complete cycles occur per second
  - 1 Hz = 1 cycle per second
  - 10 Hz = 10 cycles per second
  
- **Period**: Time for one complete cycle
  - Period = 1 / frequency
  - At 1 Hz: period = 1 second
  - At 10 Hz: period = 0.1 seconds

- **Phase**: Current position within a cycle (measured in radians)
  - Range: 0 to 2π radians
  - 0 = start of cycle
  - π = halfway through
  - 2π = end of cycle (back to start)

- **Amplitude**: The height/strength of the waveform
  - Our waveforms output values from -1 to +1

---

## Understanding Phase and Radians

### Why Radians Instead of Degrees?

In trigonometry and oscillation, we measure angles in **radians** rather than degrees because:
1. Sine and cosine functions naturally work with radians
2. Simplifies calculus and periodic motion formulas
3. One complete circle = 2π radians

### Conversion Table:
```
Radians    Degrees    Position in Cycle
0          0°         Start
π/2        90°        Quarter way
π          180°       Halfway
3π/2       270°       Three quarters
2π         360°       End (back to start)
```

### Why 2π?

The number 2π (approximately 6.28) represents one complete circle. This comes from the circumference formula:
```
Circumference = 2π × radius
For a unit circle (radius = 1): Circumference = 2π
```

---

## The Animation Loop

Our animation runs at **60 frames per second (FPS)** using a Timer.

### The Core Formula:

```swift
deltaPhase = 2π × frequency × (1/60)
```

Let's break this down:

1. **`frequency`** = cycles per second (Hz)
2. **`(1/60)`** = time per frame (one 60th of a second)
3. **`2π`** = radians per complete cycle
4. **Result** = how many radians to advance per frame

### Example at 1 Hz:

```
deltaPhase = 2π × 1 × (1/60)
           = 2π / 60
           ≈ 0.1047 radians per frame

After 60 frames (1 second):
total = 0.1047 × 60 = 2π radians = one complete cycle ✓
```

### Example at 10 Hz:

```
deltaPhase = 2π × 10 × (1/60)
           ≈ 1.047 radians per frame

After 60 frames:
total = 1.047 × 60 ≈ 20π radians = 10 complete cycles ✓
```

### Phase Wrapping:

To keep phase manageable, we wrap it back to the 0-2π range:

```swift
if phase >= 2π {
    phase = phase.truncatingRemainder(dividingBy: 2π)
}
```

Example:
- phase = 7.5 radians (more than one full cycle)
- 7.5 % 2π = 7.5 - 6.28 = 1.22 radians (wrapped back)

---

## Waveform Mathematics

Each waveform type uses different mathematics to generate its characteristic shape.

### 1. Sine Wave

```swift
value = sin(phase)
```

**Properties:**
- Smooth, natural oscillation
- Output: -1 to +1
- Continuous and differentiable
- Most "musical" sounding

**Graph Shape:**
```
  1 ┤     ╭─╮
  0 ┤   ╭─╯ ╰─╮
 -1 ┤ ╭─╯     ╰─╮
```

### 2. Triangle Wave

```swift
let progress = phase / (2π)  // 0.0 to 1.0

if progress < 0.25:
    value = progress × 4           // Rising: 0 → 1
else if progress < 0.75:
    value = 1 - (progress - 0.25) × 4  // Falling: 1 → -1
else:
    value = -1 + (progress - 0.75) × 4 // Rising: -1 → 0
```

**Properties:**
- Linear rise and fall
- Sharper than sine but still continuous
- Good for pronounced modulation

**Graph Shape:**
```
  1 ┤   ╱╲
  0 ┤  ╱  ╲
 -1 ┤ ╱    ╲╱
```

### 3. Sawtooth Wave

```swift
let progress = phase / (2π)
value = (progress × 2) - 1
```

**Calculation:**
- At 0% progress: (0 × 2) - 1 = -1
- At 50% progress: (0.5 × 2) - 1 = 0
- At 100% progress: (1.0 × 2) - 1 = +1
- Then instantly drops back to -1

**Graph Shape:**
```
  1 ┤      ╱
  0 ┤    ╱
 -1 ┤╱╱╱╱
```

### 4. Pulse (Square) Wave

```swift
value = progress < 0.5 ? 1.0 : -1.0
```

**Properties:**
- Instantly jumps between +1 and -1
- 50% duty cycle (equal high/low time)
- Most abrupt modulation

**Graph Shape:**
```
  1 ┤───╮   ╭───
  0 ┤   │   │
 -1 ┤   ╰───╯
```

### 5. Sample & Hold

```swift
// Holds random values for periods of time
value = randomValue  // Updates periodically
```

**Properties:**
- Random stepped values
- Stays constant, then jumps to new random value
- Creates unpredictable modulation
- Useful for adding randomness

**Graph Shape:**
```
  1 ┤  ──╮
  0 ┤    │  ──╮
 -1 ┤──╮ ╰──╯ ╰──
```

---

## SwiftUI Drawing Concepts

### GeometryReader

Gives us access to the container's dimensions:

```swift
GeometryReader { geometry in
    let width = geometry.size.width   // Container width in pixels
    let height = geometry.size.height // Container height in pixels
    // ... use these for responsive drawing
}
```

This allows our drawing to adapt to any screen size automatically.

### Path Drawing

A `Path` is like drawing with a pen. You move to points and draw lines:

```swift
Path { path in
    path.move(to: CGPoint(x: 0, y: 100))    // Move without drawing
    path.addLine(to: CGPoint(x: 50, y: 50)) // Draw line
    path.addLine(to: CGPoint(x: 100, y: 100)) // Draw another line
}
.stroke(Color.blue, lineWidth: 2)
```

### Coordinate System

**IMPORTANT:** SwiftUI's coordinate system is different from math class!

```
(0,0) ────────────────► X increases right
  │
  │
  │
  ▼
  Y increases DOWN (not up!)
```

This is why we **subtract** Y values to go "up" on screen:

```swift
let y = midY - (value × amplitude)
//           ↑ minus sign makes positive values go UP
```

### Drawing the Waveform

We create a smooth curve by drawing many small line segments:

```swift
let points = 500  // Draw 500 segments

for i in 0..<points {
    // 1. Calculate horizontal position
    let x = (Double(i) / Double(points)) × width
    
    // 2. Calculate phase at this X position
    let localPhase = (Double(i) / Double(points)) × 2π
    
    // 3. Get waveform value at this phase
    let value = calculateWaveform(phase: localPhase)
    
    // 4. Convert to screen Y coordinate
    let y = midY - (value × amplitude)
    
    // 5. Add to path
    if i == 0 {
        path.move(to: CGPoint(x: x, y: y))
    } else {
        path.addLine(to: CGPoint(x: x, y: y))
    }
}
```

**Step-by-step explanation:**

1. **X position**: Spread points evenly across width
   - Point 0: x = 0
   - Point 250: x = width/2
   - Point 500: x = width

2. **Phase**: Map X to a phase value
   - At x=0: phase=0 (start of cycle)
   - At x=width/2: phase=π (halfway)
   - At x=width: phase=2π (end of cycle)

3. **Waveform value**: Get the waveform's output (-1 to +1)

4. **Y coordinate**: Convert value to pixel position
   ```
   value = +1  →  y = midY - amplitude  (top of screen)
   value = 0   →  y = midY              (center)
   value = -1  →  y = midY + amplitude  (bottom)
   ```

5. **Add to path**: Connect the dots!

---

## Logarithmic Frequency Control

Our frequency range spans from **0.008 Hz to 261.6 Hz** — a ratio of over **32,000:1**!

### The Problem with Linear Sliders:

If we used a normal (linear) slider:
- 99.9% of the slider would control 0.008 to 2.616 Hz
- Only 0.1% would control 2.616 to 261.6 Hz
- Impossible to precisely control low frequencies!

### The Solution: Logarithmic Scale

With logarithmic scaling, equal slider movements create equal **ratios** (not differences):

```
Linear slider:  |----|----|----|----|  equal steps = equal additions
                0    50   100  150  200

Log slider:     |----|----|----|----| equal steps = equal multiplications
                1    10   100  1000 10000
```

### Implementation:

```swift
Slider(value: Binding(
    get: { log10(frequency) },        // Convert to log for display
    set: { frequency = pow(10, $0) }  // Convert back from log
), in: log10(minFrequency)...log10(maxFrequency))
```

**How it works:**

1. **GET (display)**: Convert frequency to logarithmic scale
   ```
   frequency = 0.008  → log10(0.008) = -2.10
   frequency = 1.0    → log10(1.0)   = 0.0
   frequency = 100.0  → log10(100.0) = 2.0
   frequency = 261.6  → log10(261.6) = 2.42
   ```

2. **SET (update)**: Convert logarithmic value back to frequency
   ```
   slider = -2.10 → pow(10, -2.10) = 0.008
   slider = 0.0   → pow(10, 0.0)   = 1.0
   slider = 2.0   → pow(10, 2.0)   = 100.0
   slider = 2.42  → pow(10, 2.42)  = 261.6
   ```

### Benefits:

- ✓ Equal control across the entire range
- ✓ Natural feel for audio/musical parameters
- ✓ Easy to make precise adjustments at any frequency
- ✓ Standard practice in audio software

---

## Musical Note Conversion

Musical notes follow a **logarithmic frequency relationship**. Each octave doubles the frequency.

### The Formula:

```swift
MIDI_note = 12 × log₂(frequency / 440) + 69
```

### Why This Works:

1. **Reference point**: A4 = 440 Hz = MIDI note 69
2. **Octaves**: Each octave doubles frequency
   - A3 = 220 Hz (half of A4)
   - A5 = 880 Hz (double A4)
3. **Semitones**: 12 semitones per octave
   - Each semitone multiplies frequency by 2^(1/12) ≈ 1.0595
4. **Logarithm**: Converts exponential relationship to linear

### Examples:

```
Frequency   Calculation                      Note   MIDI
220.0 Hz    12×log₂(220/440) + 69 = -12+69  A3     57
261.6 Hz    12×log₂(261.6/440) + 69 = 60    C4     60  ← Middle C
440.0 Hz    12×log₂(440/440) + 69 = 0+69    A4     69  ← Reference
880.0 Hz    12×log₂(880/440) + 69 = 12+69   A5     81
```

### Cents:

A **cent** is 1/100th of a semitone. It shows fine-tuning accuracy:

```
cents = (MIDI_float - MIDI_rounded) × 100
```

Examples:
- `+0¢` = exactly on pitch
- `+50¢` = halfway to next semitone (25 cents sharp)
- `-50¢` = halfway to previous semitone (25 cents flat)

---

## Summary

The LFO Tracer View combines several concepts:

1. **Mathematics**: Trigonometry, logarithms, and periodic functions
2. **Animation**: Timer-based updates at 60 FPS
3. **SwiftUI**: GeometryReader, Path drawing, @State reactivity
4. **Audio Theory**: Musical intervals, MIDI, and frequency relationships

By understanding these concepts, you can:
- Create custom waveforms
- Implement different animation techniques
- Build responsive UIs that adapt to any screen size
- Convert between musical and frequency domains
- Control wide parameter ranges intuitively

---

## Further Exploration

Try modifying the code to:
- Add new waveform types (e.g., reverse sawtooth, random wave)
- Change the duty cycle of the pulse wave (not 50/50)
- Implement waveform morphing (blend between shapes)
- Add multiple LFOs that interact with each other
- Create 3D visualizations of the waveforms
- Sync the LFO to musical tempo (BPM)

Happy coding! 🎵
