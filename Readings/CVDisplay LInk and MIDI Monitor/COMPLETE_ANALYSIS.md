# Complete Analysis: LFO View vs MIDI Graph View

## Table of Contents
1. [Overview](#overview)
2. [LFO View Architecture](#lfo-view-architecture)
3. [MIDI Graph View Architecture](#midi-graph-view-architecture)
4. [Key Differences](#key-differences)
5. [The Mystery: Why LFO Works But Graph Doesn't](#the-mystery)
6. [Detailed Code Analysis](#detailed-code-analysis)

---

## Overview

Both views attempt to create high-performance, continuously updating visualizations using CALayer. However:
- **LFO View**: ✅ Continues animating when other UI elements are touched
- **MIDI Graph View**: ❌ Stops updating when other UI elements are touched

This document analyzes both implementations to understand why they behave differently.

---

## LFO View Architecture

### Component Hierarchy

```
SwiftUI Layer:
    LFOAnimationView (SwiftUI View)
        ↓
    LFOLayerViewRepresentable (NSViewRepresentable)
        ↓
AppKit Layer:
    LFOLayerView (NSView)
        ↓
    CALayer hierarchy
        containerLayer
        ├── gridLayer (CAShapeLayer)
        ├── waveformLayer (CAShapeLayer)
        ├── trailLayer (CALayer)
        │   └── trailDots[] (CAShapeLayer)
        └── tracerLayer (CALayer)
            └── tracerDotLayer (CAShapeLayer)
```

### Data Flow

```
CVDisplayLink (separate thread)
    ↓
Callback (~60 Hz)
    ↓
DispatchQueue.main.async
    ↓
updateAnimation() [main thread]
    ↓
updateAnimationFrame()
    ↓
Updates internal state (phase, frequency)
    ↓
updateTracerPosition()
    ↓
CATransaction (disabled animations)
    ↓
Update CALayer positions/properties
    ↓
GPU renders changes
```

### Critical Design Decisions

#### 1. Self-Contained State
```swift
class LFOLayerView: NSView {
    private var phase: Double = 0           // ✅ Internal state
    private var frequency: Double = 1.0     // ✅ Internal state
    private var waveformType: LFOType = .sine // ✅ Internal state
    private var _isRunning: Bool = true     // ✅ Internal state
}
```

**Why this matters:**
- The view owns its animation state
- No external dependencies during animation loop
- CVDisplayLink just updates local variables
- No communication with SwiftUI needed during rendering

#### 2. CVDisplayLink Setup

```swift
private func startAnimation() {
    var link: CVDisplayLink?
    CVDisplayLinkCreateWithActiveCGDisplays(&link)
    displayLink = link
    
    if let displayLink = displayLink {
        CVDisplayLinkSetOutputCallback(
            displayLink, 
            { (displayLink, inNow, inOutputTime, flagsIn, flagsOut, context) -> CVReturn in
                // This runs on a SEPARATE THREAD
                let view = Unmanaged<LFOLayerView>.fromOpaque(context!).takeUnretainedValue()
                
                // Marshal back to main thread for UI updates
                DispatchQueue.main.async {
                    view.updateAnimation()
                }
                
                return kCVReturnSuccess
            }, 
            Unmanaged.passUnretained(self).toOpaque()
        )
        
        CVDisplayLinkStart(displayLink)
    }
}
```

**Key Points:**
1. **CVDisplayLink runs on separate thread** - Not tied to main thread/runloop
2. **Callback is automatic** - OS calls it, not SwiftUI
3. **Marshals to main thread** - Uses `DispatchQueue.main.async`
4. **No RunLoop modes** - Separate thread means no mode concerns

#### 3. Parameter Updates (External → Internal)

```swift
func update(speed: UInt8, shape: ContainedParameter?, isRunning: Bool) {
    // Convert MIDI to frequency
    let normalized = Double(speed) / 127.0
    frequency = pow(10, logFreq)  // ✅ Updates internal state
    
    // Update waveform type
    if case .lfo(let lfoType) = shape {
        if waveformType != lfoType {
            waveformType = lfoType  // ✅ Updates internal state
            updateWaveformPath()
        }
    }
    
    _isRunning = isRunning  // ✅ Updates internal state
}
```

**Why this works:**
- SwiftUI calls `update()` when parameters change
- Values are copied into internal state
- CVDisplayLink continues independently using internal state
- No dependency on SwiftUI after parameters are set

#### 4. NSViewRepresentable Bridge

```swift
struct LFOLayerViewRepresentable: NSViewRepresentable {
    var lfoSpeed: ProgramParameter      // SwiftUI binding
    var lfoShape: ProgramParameter      // SwiftUI binding
    var isRunning: Bool                 // SwiftUI state
    
    func makeNSView(context: Context) -> LFOLayerView {
        return LFOLayerView()  // ✅ Creates once
    }
    
    func updateNSView(_ nsView: LFOLayerView, context: Context) {
        // ✅ Called when SwiftUI parameters change
        nsView.update(
            speed: lfoSpeed.value, 
            shape: lfoShape.containedParameter, 
            isRunning: isRunning
        )
    }
}
```

**Critical insight:**
- `updateNSView()` is called when SwiftUI updates
- BUT it only updates parameters, not the animation loop
- CVDisplayLink continues running regardless
- The view never stops/restarts

---

## MIDI Graph View Architecture

### Component Hierarchy

```
SwiftUI Layer:
    MIDIMonitorView (SwiftUI View)
        ↓
    MIDIGraphView (SwiftUI View)
        @ObservedObject var viewModel: GraphViewModel
        ↓
    GraphLayerView (NSViewRepresentable)
        ↓
AppKit Layer:
    GraphContainerView (NSView)
        weak var viewModel: GraphViewModel?  // ⚠️ External reference
        ↓
    MIDIGraphLayer (CALayer)
        containerLayer
        ├── backgroundLayer
        ├── gridLayer (CAShapeLayer)
        ├── ccLineLayer (CAShapeLayer)
        ├── ccPointsLayer (CAShapeLayer)
        └── noteMarkersLayer (CALayer)
```

### Data Flow (Current Implementation)

```
Timer (main thread, 60 Hz)
    ↓
updateFromTimer()
    ↓
guard let viewModel = viewModel  // ⚠️ External reference
    ↓
let dataPoints = viewModel.dataPoints  // ⚠️ Access external state
    ↓
graphLayer.updateData(dataPoints)
    ↓
CATransaction (disabled animations)
    ↓
Update CALayer paths
    ↓
GPU renders changes
```

### Critical Design Decisions (and Problems)

#### 1. External Data Dependency

```swift
class GraphContainerView: NSView {
    weak var viewModel: GraphViewModel?  // ⚠️ EXTERNAL REFERENCE
    
    private func updateFromTimer() {
        guard let viewModel = viewModel else { return }
        let dataPoints = viewModel.dataPoints  // ⚠️ Accessing external state
        graphLayer.updateData(dataPoints)
    }
}
```

**Why this is different from LFO:**
- LFO: Updates internal state (`phase`, `frequency`)
- Graph: Reads external state (`viewModel.dataPoints`)
- Graph depends on `viewModel` remaining valid
- If SwiftUI recreates something, reference might break

#### 2. Timer Setup

```swift
func startTimer() {
    updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
        self?.updateFromTimer()
    }
    
    // ✅ Added to common mode
    if let timer = updateTimer {
        RunLoop.main.add(timer, forMode: .common)
    }
}
```

**Key Points:**
1. **Runs on main thread** - Unlike LFO's CVDisplayLink
2. **Added to .common mode** - Should survive UI interactions
3. **Weak reference to self** - Prevents retain cycle

**Potential issue:**
- Main thread timer might still be affected by SwiftUI updates
- Even in `.common` mode, main thread operations can be interrupted

#### 3. NSViewRepresentable Bridge

```swift
struct GraphLayerView: NSViewRepresentable {
    @ObservedObject var viewModel: GraphViewModel  // ⚠️ ObservedObject
    
    func makeNSView(context: Context) -> GraphContainerView {
        let view = GraphContainerView()
        view.viewModel = viewModel  // ⚠️ Assigns reference
        view.startTimer()
        return view
    }
    
    func updateNSView(_ nsView: GraphContainerView, context: Context) {
        // Intentionally empty
    }
    
    static func dismantleNSView(_ nsView: GraphContainerView, coordinator: ()) {
        nsView.stopTimer()
    }
}
```

**Potential issue:**
- `@ObservedObject var viewModel` means SwiftUI watches it
- When parent view updates, SwiftUI might think this view needs recreation
- Even with empty `updateNSView()`, SwiftUI's diffing might matter

---

## Key Differences

### 1. State Ownership

| Aspect | LFO View | MIDI Graph View |
|--------|----------|-----------------|
| **Animation State** | Internal (`phase`, `frequency`) | External (`viewModel.dataPoints`) |
| **Updates** | Copies values in | Reads values out |
| **Dependency** | Self-contained | Depends on ViewModel |
| **Lifecycle** | Independent | Tied to ViewModel |

### 2. Threading Model

| Aspect | LFO View | MIDI Graph View |
|--------|----------|-----------------|
| **Update Source** | CVDisplayLink (separate thread) | Timer (main thread) |
| **Thread Safety** | Marshals to main thread | Already on main thread |
| **Interruption** | Hard to interrupt | Easier to interrupt |
| **RunLoop Mode** | N/A (separate thread) | .common mode |

### 3. SwiftUI Integration

| Aspect | LFO View | MIDI Graph View |
|--------|----------|-----------------|
| **Parameters** | Primitive types (UInt8, Bool) | Complex type (GraphViewModel) |
| **Observation** | Not observed | @ObservedObject |
| **Recreation** | Parameters change, view stays | ViewModel observed, might trigger recreation |
| **Coupling** | Loose (parameters only) | Tight (ViewModel reference) |

---

## The Mystery: Why LFO Works But Graph Doesn't

### Hypothesis 1: SwiftUI Recreation

**Theory:**
When other UI elements change (slider, picker), SwiftUI's view diffing algorithm detects that `MIDIGraphView` contains `@ObservedObject var viewModel`, which triggers some internal state change, causing SwiftUI to think the view needs updating.

**Evidence:**
- LFO has no `@ObservedObject` in representable
- LFO parameters are simple value types
- Graph has `@ObservedObject var viewModel`

**Test:**
```swift
// Current (problematic?)
struct GraphLayerView: NSViewRepresentable {
    @ObservedObject var viewModel: GraphViewModel  // ⚠️
}

// Alternative (like LFO?)
struct GraphLayerView: NSViewRepresentable {
    let viewModel: GraphViewModel  // Just a reference, not observed
}
```

### Hypothesis 2: Main Thread Timer Interruption

**Theory:**
Even with `.common` RunLoop mode, timers on main thread can be deprioritized during active UI updates. CVDisplayLink on separate thread is immune to this.

**Evidence:**
- LFO uses CVDisplayLink (separate thread)
- Graph uses Timer (main thread)
- Main thread is where SwiftUI updates happen

**Test:**
Switch to CVDisplayLink like LFO

### Hypothesis 3: ViewModel Reference Invalidation

**Theory:**
When SwiftUI updates parent views, the `weak var viewModel` reference in `GraphContainerView` might be getting set to nil or reassigned.

**Evidence:**
- Timer fires: `guard let viewModel = viewModel else { return }`
- If this guard fails, update stops
- No error messages would appear

**Test:**
Add logging:
```swift
private func updateFromTimer() {
    if viewModel == nil {
        print("⚠️ ViewModel is nil!")
        return
    }
    print("✅ ViewModel valid, updating...")
}
```

### Hypothesis 4: NSViewRepresentable Lifecycle

**Theory:**
SwiftUI might be calling `dismantleNSView()` and `makeNSView()` when parent updates, even though we don't expect it to.

**Evidence:**
- LFO representable has simpler parameter types
- Graph representable has `@ObservedObject`
- SwiftUI's diffing might treat these differently

**Test:**
Add logging:
```swift
func makeNSView(context: Context) -> GraphContainerView {
    print("🔨 makeNSView called")
    let view = GraphContainerView()
    view.viewModel = viewModel
    view.startTimer()
    return view
}

static func dismantleNSView(_ nsView: GraphContainerView, coordinator: ()) {
    print("💀 dismantleNSView called")
    nsView.stopTimer()
}
```

---

## Detailed Code Analysis

### LFO View: Complete Flow

#### Step 1: SwiftUI Creates View

```swift
// In LFO_Editor_View.swift
LFOLayerViewRepresentable(
    lfoSpeed: program.lfoSpeed,      // ProgramParameter
    lfoShape: program.lfoShape,      // ProgramParameter
    isRunning: isRunning             // Bool
)
```

#### Step 2: NSViewRepresentable Bridge

```swift
// In LFO_CALayer.swift
struct LFOLayerViewRepresentable: NSViewRepresentable {
    var lfoSpeed: ProgramParameter    // VALUE TYPE (struct)
    var lfoShape: ProgramParameter    // VALUE TYPE (struct)
    var isRunning: Bool               // VALUE TYPE (primitive)
    
    func makeNSView(context: Context) -> LFOLayerView {
        return LFOLayerView()  
        // Creates NSView ONCE
        // CVDisplayLink starts automatically in init
    }
    
    func updateNSView(_ nsView: LFOLayerView, context: Context) {
        // Called when lfoSpeed, lfoShape, or isRunning change
        nsView.update(
            speed: lfoSpeed.value,              // Extracts UInt8
            shape: lfoShape.containedParameter, // Extracts enum
            isRunning: isRunning                // Passes Bool
        )
        // This just updates internal state
        // CVDisplayLink continues running
    }
}
```

#### Step 3: LFOLayerView Initialization

```swift
// In LFOLayerView.swift
override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
}

private func setup() {
    wantsLayer = true
    layer?.backgroundColor = NSColor.black.cgColor
    
    setupLayers()      // Creates CALayer hierarchy
    startAnimation()   // Starts CVDisplayLink
}
```

#### Step 4: CVDisplayLink Animation Loop

```swift
private func startAnimation() {
    // 1. Create CVDisplayLink
    var link: CVDisplayLink?
    CVDisplayLinkCreateWithActiveCGDisplays(&link)
    displayLink = link
    
    // 2. Set callback
    CVDisplayLinkSetOutputCallback(
        displayLink, 
        { (displayLink, inNow, inOutputTime, flagsIn, flagsOut, context) -> CVReturn in
            // THIS RUNS ON A SEPARATE THREAD
            // Called by the OS at display refresh rate (~60 Hz)
            
            let view = Unmanaged<LFOLayerView>.fromOpaque(context!).takeUnretainedValue()
            
            // Marshal back to main thread for UI updates
            DispatchQueue.main.async {
                view.updateAnimation()  // Safe to update UI here
            }
            
            return kCVReturnSuccess
        }, 
        Unmanaged.passUnretained(self).toOpaque()
    )
    
    // 3. Start the link
    CVDisplayLinkStart(displayLink)
}

private func updateAnimation() {
    updateAnimationFrame()  // On main thread now
}

private func updateAnimationFrame() {
    guard _isRunning else { return }
    
    // Calculate time delta
    let currentTime = CACurrentMediaTime()
    let deltaTime = currentTime - lastUpdateTime
    lastUpdateTime = currentTime
    
    // Update phase based on frequency
    let deltaPhase = 2 * .pi * frequency * deltaTime
    phase += deltaPhase
    
    // Update tracer position
    updateTracerPosition()
}

private func updateTracerPosition() {
    // Calculate new position based on phase
    let progress = phase / (2 * .pi)
    let x = progress * width
    let value = calculateWaveform(phase: phase, type: waveformType)
    let y = midY - (value * amplitude)
    
    // Update CALayer
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    
    tracerLayer.position = CGPoint(x: x, y: y)
    // ... update trail dots ...
    
    CATransaction.commit()
}
```

#### Step 5: Parameter Updates (from SwiftUI)

```swift
func update(speed: UInt8, shape: ContainedParameter?, isRunning: Bool) {
    // Called from updateNSView when parameters change
    
    // 1. Update frequency (internal state)
    let normalized = Double(speed) / 127.0
    frequency = pow(10, logFreq)  // INTERNAL STATE UPDATED
    
    // 2. Update waveform type (internal state)
    if case .lfo(let lfoType) = shape {
        if waveformType != lfoType {
            waveformType = lfoType  // INTERNAL STATE UPDATED
            updateWaveformPath()     // Redraw waveform
        }
    }
    
    // 3. Update running state (internal state)
    _isRunning = isRunning  // INTERNAL STATE UPDATED
}
```

**Key insight:** CVDisplayLink continues running. It just reads the updated `frequency`, `waveformType`, and `_isRunning` values.

---

### MIDI Graph View: Complete Flow

#### Step 1: SwiftUI Creates View

```swift
// In MIDI_Monitor_View.swift
MIDIGraphView(viewModel: viewModel)  // Passes GraphViewModel reference
```

#### Step 2: MIDIGraphView (SwiftUI)

```swift
struct MIDIGraphView: View {
    @ObservedObject var viewModel: GraphViewModel  // ⚠️ OBSERVED
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // ... grid, labels ...
                
                GraphLayerView(viewModel: viewModel)  // Pass reference
            }
        }
    }
}
```

**Potential issue:** `@ObservedObject` means SwiftUI monitors `viewModel` for changes. When `viewModel.dataPoints` changes (20 times/second!), does SwiftUI think this view needs updating?

#### Step 3: NSViewRepresentable Bridge

```swift
struct GraphLayerView: NSViewRepresentable {
    @ObservedObject var viewModel: GraphViewModel  // ⚠️ OBSERVED AGAIN
    
    func makeNSView(context: Context) -> GraphContainerView {
        print("🔨 Making NSView")  // Add this for debugging
        let view = GraphContainerView()
        view.viewModel = viewModel  // ⚠️ Store reference
        view.startTimer()
        return view
    }
    
    func updateNSView(_ nsView: GraphContainerView, context: Context) {
        print("🔄 Updating NSView")  // Add this for debugging
        // Empty - but is this still being called?
    }
    
    static func dismantleNSView(_ nsView: GraphContainerView, coordinator: ()) {
        print("💀 Dismantling NSView")  // Add this for debugging
        nsView.stopTimer()
    }
}
```

**Question:** When other UI updates, is SwiftUI calling `dismantleNSView()` then `makeNSView()`? This would stop/restart the timer.

#### Step 4: GraphContainerView Initialization

```swift
class GraphContainerView: NSView {
    private let graphLayer = MIDIGraphLayer()
    private var updateTimer: Timer?
    weak var viewModel: GraphViewModel?  // ⚠️ WEAK reference
    
    func startTimer() {
        print("⏰ Starting timer")  // Add this for debugging
        
        updateTimer = Timer.scheduledTimer(
            withTimeInterval: 1.0/60.0, 
            repeats: true
        ) { [weak self] _ in
            self?.updateFromTimer()
        }
        
        if let timer = updateTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
}
```

#### Step 5: Timer Update Loop

```swift
private func updateFromTimer() {
    // Called 60 times/second on main thread
    
    guard let viewModel = viewModel else { 
        print("⚠️ ViewModel is nil!")  // Add this for debugging
        return 
    }
    
    let dataPoints = viewModel.dataPoints  // Read external state
    
    if !dataPoints.isEmpty {
        graphLayer.updateData(dataPoints)  // Update CALayer
    }
}
```

**Questions:**
1. Is `viewModel` ever nil during this call?
2. Is the timer continuing to fire?
3. Is `updateData()` being called but not rendering?

#### Step 6: CALayer Update

```swift
// In MIDIGraphLayer
func updateData(_ dataPoints: [DataPoint]) {
    guard dataPoints.count > 1 else { return }
    
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    
    // Update paths
    updateCCLine(...)
    updateCCPoints(...)
    updateNoteMarkers(...)
    
    CATransaction.commit()
}
```

---

## CALayer Primer

### What is CALayer?

CALayer is Core Animation's fundamental building block. It's a lightweight object that manages:
- Visual content (colors, shapes, images)
- Geometric properties (position, size, transform)
- Animation and compositing

**Key concept:** CALayer is GPU-accelerated. When you change a property, the GPU handles the rendering, not the CPU.

### CALayer vs NSView

```swift
NSView                          CALayer
├── Heavy (full view hierarchy) ├── Lightweight
├── Event handling              ├── No event handling
├── Auto layout                 ├── Manual layout
├── CPU-based                   ├── GPU-accelerated
└── Good for UI controls        └── Good for visual effects
```

### CAShapeLayer

A subclass of CALayer specialized for vector shapes:

```swift
let shapeLayer = CAShapeLayer()
shapeLayer.path = somePath           // CGPath (vector)
shapeLayer.strokeColor = color.cgColor
shapeLayer.fillColor = color.cgColor
shapeLayer.lineWidth = 2
```

**Benefits:**
- GPU renders the path
- Smooth curves
- Resolution-independent
- Can animate path changes

### CATransaction

Controls animation:

```swift
CATransaction.begin()
CATransaction.setDisableActions(true)  // Disable implicit animations

layer.position = newPosition  // Change happens instantly
layer.path = newPath         // No animation

CATransaction.commit()
```

**Why disable animations?**
For real-time updates (like our graph), we want instant changes, not smooth transitions. We're creating the "animation" by rapidly updating positions.

### Layer Hierarchy

Layers are organized in a tree:

```
containerLayer (CALayer)
├── gridLayer (CAShapeLayer)
│   └── path: horizontal lines
├── ccLineLayer (CAShapeLayer)
│   └── path: connected line through data points
├── ccPointsLayer (CAShapeLayer)
│   └── path: small circles at each point
└── noteMarkersLayer (CALayer)
    ├── velocityGlowLayer (CAShapeLayer)
    ├── velocityLayer (CAShapeLayer)
    ├── positionGlowLayer (CAShapeLayer)
    └── positionLayer (CAShapeLayer)
```

Each layer renders independently on the GPU.

### Performance: CALayer vs Canvas

**Canvas (SwiftUI):**
```swift
Canvas { context, size in
    // Runs on CPU
    // Redraws entire canvas each frame
    // Creates paths, strokes them
}
```
Every frame: CPU does all the work, then sends bitmap to GPU.

**CALayer:**
```swift
CATransaction.begin()
shapeLayer.path = newPath  // Set once
CATransaction.commit()
```
One frame: CPU creates path, GPU renders it and keeps it.
Next frames: GPU just composites existing layers (much faster).

---

## Debugging Steps

### Step 1: Add Extensive Logging

Add these print statements to see what's happening:

```swift
// In GraphLayerView
func makeNSView(context: Context) -> GraphContainerView {
    print("🔨 [GraphLayerView] makeNSView called")
    let view = GraphContainerView()
    view.viewModel = viewModel
    view.startTimer()
    return view
}

func updateNSView(_ nsView: GraphContainerView, context: Context) {
    print("🔄 [GraphLayerView] updateNSView called")
}

static func dismantleNSView(_ nsView: GraphContainerView, coordinator: ()) {
    print("💀 [GraphLayerView] dismantleNSView called")
    nsView.stopTimer()
}

// In GraphContainerView
func startTimer() {
    print("⏰ [GraphContainer] Starting timer")
    updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
        self?.updateFromTimer()
    }
    
    if let timer = updateTimer {
        RunLoop.main.add(timer, forMode: .common)
        print("✅ [GraphContainer] Timer added to RunLoop")
    }
}

func stopTimer() {
    print("🛑 [GraphContainer] Stopping timer")
    updateTimer?.invalidate()
    updateTimer = nil
}

private var updateCount = 0
private func updateFromTimer() {
    updateCount += 1
    
    if updateCount % 60 == 0 {  // Print every second
        print("⏱️ [GraphContainer] Timer fired \(updateCount) times")
    }
    
    guard let viewModel = viewModel else {
        print("⚠️ [GraphContainer] ViewModel is nil!")
        return
    }
    
    let dataPoints = viewModel.dataPoints
    
    if updateCount % 60 == 0 {
        print("📊 [GraphContainer] DataPoints count: \(dataPoints.count)")
    }
    
    if !dataPoints.isEmpty {
        graphLayer.updateData(dataPoints)
    }
}
```

### Step 2: Test Scenario

1. Run the app
2. Watch console output
3. Touch a slider

**Expected output if working:**
```
🔨 [GraphLayerView] makeNSView called
⏰ [GraphContainer] Starting timer
✅ [GraphContainer] Timer added to RunLoop
⏱️ [GraphContainer] Timer fired 60 times
📊 [GraphContainer] DataPoints count: 150
⏱️ [GraphContainer] Timer fired 120 times
📊 [GraphContainer] DataPoints count: 200
[User touches slider]
🔄 [GraphLayerView] updateNSView called
⏱️ [GraphContainer] Timer fired 180 times
📊 [GraphContainer] DataPoints count: 200
```

**Problematic output if recreating:**
```
🔨 [GraphLayerView] makeNSView called
⏰ [GraphContainer] Starting timer
⏱️ [GraphContainer] Timer fired 60 times
[User touches slider]
💀 [GraphLayerView] dismantleNSView called  ← VIEW DESTROYED!
🛑 [GraphContainer] Stopping timer
🔨 [GraphLayerView] makeNSView called       ← VIEW RECREATED!
⏰ [GraphContainer] Starting timer
```

**Problematic output if ViewModel nil:**
```
⏱️ [GraphContainer] Timer fired 60 times
[User touches slider]
⚠️ [GraphContainer] ViewModel is nil!      ← REFERENCE LOST!
⚠️ [GraphContainer] ViewModel is nil!
⚠️ [GraphContainer] ViewModel is nil!
```

---

## Conclusion

The fundamental difference is:

**LFO View:**
- Self-contained animation state
- CVDisplayLink on separate thread
- Simple value-type parameters
- No `@ObservedObject` in representable
- Copy parameters in, run independently

**MIDI Graph View:**
- External data dependency (ViewModel)
- Timer on main thread
- Complex reference-type parameter
- `@ObservedObject` in representable
- Read data out, depends on reference staying valid

**Next Steps:**
1. Add logging to see what's actually happening
2. Test if ViewModel reference is breaking
3. Test if view is being recreated
4. Consider copying data into view's internal state (like LFO)

The answer lies in understanding exactly what SwiftUI is doing when other UI elements update. The logging will reveal it.
