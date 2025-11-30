# MIDI + CVDisplayLink Integration: Complete Analysis

## Table of Contents
1. [Understanding the Two Data Streams](#understanding-the-two-data-streams)
2. [The Fundamental Pattern](#the-fundamental-pattern)
3. [MIDI Callback Structure](#midi-callback-structure)
4. [Threading Considerations](#threading-considerations)
5. [Should CVDisplayLink Be Slowed Down?](#should-cvdisplaylink-be-slowed-down)
6. [Complete Implementation Examples](#complete-implementation-examples)
7. [Common Misconceptions](#common-misconceptions)
8. [Performance Analysis](#performance-analysis)

---

## Understanding the Two Data Streams

### MIDI Stream Characteristics

MIDI data arrives **asynchronously** and **irregularly**:

```
MIDI Events Over Time:

0ms     45ms    52ms          120ms   125ms        200ms
 |       |       |              |       |            |
CC=64  CC=65   CC=66          CC=70   Note On    CC=72

Irregular timing! No fixed rate!
```

**Key Properties:**
- **Variable rate**: Could be 0 events/sec or 1000+ events/sec
- **Bursty**: User wiggling a knob = rapid stream of CC messages
- **Unpredictable**: No way to know when next message arrives
- **Event-driven**: You react to events, not poll for them

**Typical MIDI Rates:**
```
Scenario                  Rate
------------------------  ------------------
Idle (nothing happening)  0 messages/sec
Slow knob turn            5-10 messages/sec
Fast knob turn            50-100 messages/sec
Real-time control         100-300 messages/sec
Theoretical maximum       ~3000 messages/sec (MIDI bandwidth limit)
```

### CVDisplayLink Stream Characteristics

CVDisplayLink fires **synchronously** and **regularly**:

```
CVDisplayLink Callbacks:

0ms     16.7ms  33.3ms  50ms    66.7ms  83.3ms  100ms
 |       |       |       |       |       |       |
 ↓       ↓       ↓       ↓       ↓       ↓       ↓
Tick    Tick    Tick    Tick    Tick    Tick    Tick

Perfect 60 Hz timing!
```

**Key Properties:**
- **Fixed rate**: 60 Hz (or 120 Hz on ProMotion displays)
- **Predictable**: Fires every 16.67ms like clockwork
- **Display-synchronized**: Aligned with screen refresh
- **Continuous**: Runs constantly while active

---

## The Fundamental Pattern

### Concept: Producer-Consumer with Sample-and-Hold

This is a classic **producer-consumer** pattern with **sample-and-hold** rendering:

```
Producer (MIDI):                Consumer (CVDisplayLink):
    ↓                               ↓
Writes to shared state         Reads from shared state
    ↓                               ↓
Irregular timing               Regular timing (60 Hz)
    ↓                               ↓
ccValue = 64                   Read ccValue → Draw
    (45ms later)                   (16.7ms later)
ccValue = 65                   Read ccValue → Draw
    (7ms later)                    (16.7ms later)
ccValue = 66                   Read ccValue → Draw
```

**Key insight:** These streams are **independent**:
- MIDI writes when it has data
- CVDisplayLink reads when it's time to render
- They don't coordinate or wait for each other

### Why This Works

**Sample-and-Hold Visualization:**

```
MIDI Value:
    64        65  66              70  71    72
    |         |   |               |   |     |
    v         v   v               v   v     v
Timeline:
|-------|-------|-------|-------|-------|-------|
0ms     16.7    33.3    50      66.7    83.3    100ms

CVDisplayLink samples:
↓       ↓       ↓       ↓       ↓       ↓       ↓
64      65      66      66      70      72      72

Display shows:
[64]    [65]    [66]    [66]    [70]    [72]    [72]
```

**What happens:**
1. MIDI writes `ccValue = 66` at 52ms
2. CVDisplayLink reads at 50ms (samples 66)
3. CVDisplayLink reads again at 66.7ms (still 66, MIDI hasn't updated yet)
4. MIDI writes `ccValue = 70` at 120ms
5. CVDisplayLink reads at 83.3ms (samples 70)

**Result:** Smooth visualization that adapts to MIDI timing without coordination.

---

## MIDI Callback Structure

### Option 1: Simple Write (Recommended for Your Case)

```swift
@MainActor
class MIDIGraphContainerView: NSView {
    // MARK: - Shared State
    private var currentCCValue: UInt8 = 0
    private var currentNoteVelocity: UInt8 = 0
    
    // MARK: - MIDI Setup
    
    func configure(source: MIDIDevice, ccNumber: ContinuousController) {
        // Start listening to CC stream
        ccListenerTask = Task { @MainActor [weak self] in
            for await ccData in await midiService.ccStream(from: source) {
                guard let self else { return }
                
                // Filter for the CC we care about
                guard ccData.cc == ccNumber else { continue }
                
                // SIMPLE: Just write the value
                self.currentCCValue = ccData.value
                
                // That's it! CVDisplayLink will read it when ready.
            }
        }
        
        // Start listening to note stream
        noteListenerTask = Task { @MainActor [weak self] in
            for await noteData in await midiService.noteStream(from: source) {
                guard let self else { return }
                
                // SIMPLE: Just write the value
                self.currentNoteVelocity = noteData.velocity
            }
        }
    }
}
```

**Why this works:**
- `@MainActor` ensures thread safety
- AsyncStream delivers on main actor
- CVDisplayLink marshals to main thread
- Both touching same data, but on same thread = safe
- No locks, no synchronization needed

**Flow:**
```
MIDI arrives → AsyncStream → Update currentCCValue (main thread)
                                        ↓
CVDisplayLink fires → Marshal to main → Read currentCCValue (main thread)
```

### Option 2: Atomic Access (If Not Using @MainActor)

```swift
class MIDIGraphContainerView: NSView {
    // MARK: - Thread-Safe State
    
    private let dataQueue = DispatchQueue(label: "com.midi.graph.data")
    private var _currentCCValue: UInt8 = 0
    
    private var currentCCValue: UInt8 {
        get { dataQueue.sync { _currentCCValue } }
        set { dataQueue.async { self._currentCCValue = newValue } }
    }
    
    // MARK: - MIDI Setup
    
    func configure(source: MIDIDevice, ccNumber: ContinuousController) {
        ccListenerTask = Task { [weak self] in
            for await ccData in await midiService.ccStream(from: source) {
                guard let self else { return }
                guard ccData.cc == ccNumber else { continue }
                
                // Thread-safe write
                self.currentCCValue = ccData.value
            }
        }
    }
    
    // MARK: - CVDisplayLink Callback
    
    CVDisplayLinkSetOutputCallback(displayLink, { (_, _, _, _, _, context) -> CVReturn in
        let view = Unmanaged<MIDIGraphContainerView>.fromOpaque(context!).takeUnretainedValue()
        
        DispatchQueue.main.async {
            // Thread-safe read
            let value = view.currentCCValue
            view.updateGraph(with: value)
        }
        
        return kCVReturnSuccess
    }, ...)
}
```

**When to use this:**
- If MIDI callbacks might arrive on different threads
- If you can't use @MainActor
- If you need guaranteed atomic access

**Trade-offs:**
- More complex
- Slight performance overhead (queue sync)
- Probably unnecessary if using @MainActor

### Option 3: Buffered Approach (For High-Rate MIDI)

```swift
class MIDIGraphContainerView: NSView {
    // MARK: - Buffered State
    
    private var recentCCValues: [UInt8] = []
    private let maxBufferSize = 10
    
    // MARK: - MIDI Callback
    
    func configure(source: MIDIDevice, ccNumber: ContinuousController) {
        ccListenerTask = Task { @MainActor [weak self] in
            for await ccData in await midiService.ccStream(from: source) {
                guard let self else { return }
                guard ccData.cc == ccNumber else { continue }
                
                // Buffer recent values
                self.recentCCValues.append(ccData.value)
                if self.recentCCValues.count > self.maxBufferSize {
                    self.recentCCValues.removeFirst()
                }
            }
        }
    }
    
    // MARK: - CVDisplayLink Callback
    
    private func updateFromDisplayLink() {
        guard !recentCCValues.isEmpty else { return }
        
        // Option A: Use latest value
        let latestValue = recentCCValues.last!
        
        // Option B: Average recent values (smoothing)
        let averageValue = recentCCValues.reduce(0, +) / UInt8(recentCCValues.count)
        
        // Option C: Use all values (for visualizing bursts)
        for value in recentCCValues {
            addDataPoint(value)
        }
        recentCCValues.removeAll()
    }
}
```

**When to use this:**
- Very high-rate MIDI (100+ messages/sec)
- Want to smooth jitter
- Want to visualize bursts
- Don't want to miss rapid changes

**Trade-offs:**
- More memory
- More complex
- Might add latency

---

## Threading Considerations

### Thread Safety Matrix

| Scenario | MIDI Thread | CVDisplayLink Thread | Main Thread | Safe? |
|----------|-------------|----------------------|-------------|-------|
| MIDI writes, CVDisplayLink reads (both on main) | Main | Main via marshal | Main | ✅ Yes |
| MIDI writes (background), CVDisplayLink reads (main), no sync | Background | Main | Main | ❌ Race condition |
| MIDI writes (background), atomic property, CVDisplayLink reads | Background | Main | Main | ✅ Yes (with queue) |
| @MainActor everywhere | Main | Main via marshal | Main | ✅ Yes |

### Recommended: @MainActor Approach

```swift
@MainActor
class MIDIGraphContainerView: NSView {
    private var currentCCValue: UInt8 = 0
    
    // MIDI callback (runs on main actor via Task)
    func setupMIDI() {
        Task { @MainActor in
            for await cc in stream {
                self.currentCCValue = cc.value  // Main actor
            }
        }
    }
    
    // CVDisplayLink callback
    CVDisplayLinkSetOutputCallback(link, { (_, _, _, _, _, context) in
        let view = Unmanaged<MIDIGraphContainerView>.fromOpaque(context!).takeUnretainedValue()
        
        DispatchQueue.main.async {  // Marshal to main
            // Now on main actor
            let value = view.currentCCValue  // Main actor
            view.render(value)
        }
        
        return kCVReturnSuccess
    }, ...)
}
```

**Why this is safe:**
```
MIDI AsyncStream:
  @MainActor Task → for await → Write currentCCValue
                                        ↓
                                    (Main Thread)
                                        ↓
CVDisplayLink:
  Separate Thread → Callback → DispatchQueue.main.async → Read currentCCValue
                                                               ↓
                                                          (Main Thread)

Both access on same thread (main) = Safe!
```

### Visual Timeline

```
Time →   0ms        16.7ms      33.3ms      50ms
         |          |           |           |
Main     MIDI       Display     MIDI        Display
Thread:  Write      Read        Write       Read
         CC=64      CC=64       CC=70       CC=70
         
Display  [Separate  [Callback]  [Separate  [Callback]
Link     Thread]    Marshal→    Thread]    Marshal→
Thread:            Main                    Main

No overlap! No race conditions!
```

---

## Should CVDisplayLink Be Slowed Down?

### Short Answer: **NO**

### Long Answer: Understanding Why

#### Misconception: "CVDisplayLink polls too fast"

**What you might think:**
```
MIDI sends 10 messages/second
CVDisplayLink reads 60 times/second
60 > 10, so we're wasting 50 reads!
Should we slow CVDisplayLink to match MIDI rate?
```

**Why this is wrong:**

1. **CVDisplayLink doesn't "poll" - it samples**
```
Polling (bad):
  "Hey MIDI, do you have data?"
  "No"
  "Hey MIDI, do you have data?"
  "No"
  "Hey MIDI, do you have data?"
  "Yes! Here's 64"
  
Sampling (what actually happens):
  currentCCValue = 64  (MIDI wrote this)
  Read currentCCValue → 64  (CVDisplayLink reads)
  Read currentCCValue → 64  (Still 64)
  Read currentCCValue → 64  (Still 64)
  currentCCValue = 70  (MIDI wrote this)
  Read currentCCValue → 70  (CVDisplayLink reads new value)
```

No wasted work! Just reading a variable.

2. **Display refresh rate is constant**

```
Your display refreshes at 60 Hz no matter what.

If you update at 30 Hz:
  Display shows: [Frame 1] [Frame 1] [Frame 2] [Frame 2]
                  New      Same     New      Same
                  
  Result: Stuttery animation (frame doubling)

If you update at 60 Hz:
  Display shows: [Frame 1] [Frame 2] [Frame 3] [Frame 4]
                  New      New      New      New
                  
  Result: Smooth animation
```

3. **MIDI timing is preserved automatically**

```
MIDI messages:
  T=0ms:    CC=64
  T=100ms:  CC=70
  T=120ms:  CC=75

CVDisplayLink samples (60 Hz):
  T=0ms:    64  ────┐
  T=16.7ms: 64      │ Held for ~6 frames
  T=33.3ms: 64      │ (Smooth!)
  T=50ms:   64      │
  T=66.7ms: 64      │
  T=83.3ms: 64  ────┘
  T=100ms:  70  ────┐ Jumps instantly when MIDI updates
  T=116.7ms: 70     │ (Responsive!)
  T=133.3ms: 75 ────┘

The graph AUTOMATICALLY shows:
- Smooth rendering (60 FPS)
- Accurate timing (jumps when MIDI changes)
- No interpolation needed
```

#### What If You Slowed It Down?

**Scenario: CVDisplayLink at 20 Hz to "match" MIDI rate**

```
MIDI messages:
  T=0ms:    CC=64
  T=25ms:   CC=70
  T=55ms:   CC=75

CVDisplayLink samples (20 Hz):
  T=0ms:    64
  T=50ms:   70   ← Missed the change at 25ms!
  T=100ms:  75   ← Missed the change at 55ms!

Display (60 Hz) shows:
  T=0-50ms:   64 64 64 (same frame 3 times - stuttery!)
  T=50-100ms: 70 70 70 (same frame 3 times - stuttery!)
```

**Problems:**
- Stuttery animation (display updates 60 times but you only give it new frames 20 times)
- Missed rapid changes
- Worse latency
- No benefit!

### Performance Analysis: 60 Hz vs Slower

```
Metric                  | 60 Hz           | 30 Hz          | 20 Hz
------------------------|-----------------|----------------|------------------
Visual smoothness       | Excellent       | Acceptable     | Stuttery
Frame doubling          | None            | Some           | Significant
CPU per frame           | Same            | Same           | Same
Total CPU               | 60 reads/sec    | 30 reads/sec   | 20 reads/sec
CPU savings             | Baseline        | 50%            | 67%
But reading is cheap!   | ~0.01% CPU      | ~0.005% CPU    | ~0.003% CPU

Real CPU cost:
  Reading variable:     Negligible
  Updating CALayer:     Moderate (GPU does work)
  
Conclusion: Slowing down saves negligible CPU, ruins smoothness
```

### The Real Cost Analysis

**What actually uses CPU/GPU:**

```swift
private func updateFromDisplayLink() {
    // 1. Read variable (CHEAP - nanoseconds)
    let value = currentCCValue
    
    // 2. Create data point (CHEAP - microseconds)
    let point = DataPoint(value: value)
    dataPoints.append(point)
    
    // 3. Update CALayer path (MODERATE - milliseconds)
    let path = createPath(from: dataPoints)
    
    // 4. GPU renders (FREE - happens in parallel)
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    layer.path = path
    CATransaction.commit()
}
```

**Cost breakdown:**
- Reading `currentCCValue`: ~10 nanoseconds
- Appending to array: ~100 nanoseconds
- Creating CGPath: ~1-5 milliseconds (for 200 points)
- GPU rendering: Parallel, doesn't block CPU

**Total CPU per frame:** ~1-5ms
**Available time at 60 Hz:** 16.7ms
**CPU usage:** ~6-30% of available time

**Slowing to 30 Hz saves:** 30-60ms per second (negligible)
**Slowing to 30 Hz costs:** Choppy animation (unacceptable)

### When Would You Throttle?

**Only if:**

1. **Path creation is extremely expensive**
```swift
// If you have thousands of points:
private func updateFromDisplayLink() {
    if dataPoints.count > 10000 {  // Huge dataset
        // Throttle to 30 Hz
        frameCounter += 1
        if frameCounter % 2 != 0 { return }
    }
    
    updatePath()
}
```

2. **Battery life is critical (laptops)**
```swift
// On battery, reduce to 30 Hz:
if ProcessInfo.processInfo.isOperatingOnBattery {
    frameCounter += 1
    if frameCounter % 2 != 0 { return }
}
```

3. **Multiple expensive animations**
```swift
// If running 10 simultaneous graphs:
// Each at 60 Hz = 600 path updates/sec
// Throttle to 30 Hz = 300 path updates/sec
```

**For your MIDI graph:** None of these apply. Run at full 60 Hz.

---

## Complete Implementation Examples

### Example 1: Minimal MIDI + CVDisplayLink

```swift
@MainActor
class SimpleMIDIGraphView: NSView {
    // MARK: - State
    private var displayLink: CVDisplayLink?
    private var currentCCValue: UInt8 = 64
    private let graphLayer = CAShapeLayer()
    
    // MARK: - Setup
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayer()
        setupDisplayLink()
        setupMIDI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("Use init(frame:)")
    }
    
    private func setupLayer() {
        wantsLayer = true
        layer?.addSublayer(graphLayer)
        graphLayer.strokeColor = NSColor.cyan.cgColor
    }
    
    private func setupDisplayLink() {
        var link: CVDisplayLink?
        CVDisplayLinkCreateWithActiveCGDisplays(&link)
        displayLink = link
        
        guard let displayLink = displayLink else { return }
        
        CVDisplayLinkSetOutputCallback(displayLink, { (_, _, _, _, _, context) -> CVReturn in
            let view = Unmanaged<SimpleMIDIGraphView>.fromOpaque(context!).takeUnretainedValue()
            
            DispatchQueue.main.async {
                view.updateGraph()
            }
            
            return kCVReturnSuccess
        }, Unmanaged.passUnretained(self).toOpaque())
        
        CVDisplayLinkStart(displayLink)
    }
    
    private func setupMIDI() {
        Task { @MainActor in
            guard let source = await MIDIService.shared.availableSources().first else { return }
            
            for await ccData in await MIDIService.shared.ccStream(from: source) {
                // Simple: just write the value
                self.currentCCValue = ccData.value
                // CVDisplayLink will read it when ready
            }
        }
    }
    
    // MARK: - Update
    
    private func updateGraph() {
        // Sample current value
        let value = CGFloat(currentCCValue) / 127.0
        
        // Draw simple line
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: bounds.height * (1 - value)))
        path.addLine(to: CGPoint(x: bounds.width, y: bounds.height * (1 - value)))
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        graphLayer.path = path
        CATransaction.commit()
    }
    
    // MARK: - Cleanup
    
    deinit {
        if let displayLink = displayLink {
            CVDisplayLinkStop(displayLink)
        }
    }
}
```

**Key points:**
- MIDI writes `currentCCValue` whenever it arrives
- CVDisplayLink reads `currentCCValue` at 60 Hz
- No coordination, no synchronization
- Works perfectly!

### Example 2: Complete Scrolling Graph

```swift
@MainActor
class ScrollingMIDIGraphView: NSView {
    // MARK: - State
    private var displayLink: CVDisplayLink?
    private var dataPoints: [CGFloat] = []
    private let maxDataPoints = 200
    private var currentCCValue: UInt8 = 64
    private var currentNoteVelocity: UInt8 = 0
    private var lastNoteVelocity: UInt8 = 0
    
    private let graphLayer = CAShapeLayer()
    private let noteMarkersLayer = CALayer()
    
    // MARK: - Setup
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
        setupDisplayLink()
    }
    
    required init?(coder: NSCoder) {
        fatalError("Use init(frame:)")
    }
    
    private func setupLayers() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
        
        graphLayer.strokeColor = NSColor.cyan.cgColor
        graphLayer.fillColor = nil
        graphLayer.lineWidth = 2
        layer?.addSublayer(graphLayer)
        
        layer?.addSublayer(noteMarkersLayer)
    }
    
    private func setupDisplayLink() {
        var link: CVDisplayLink?
        CVDisplayLinkCreateWithActiveCGDisplays(&link)
        displayLink = link
        
        guard let displayLink = displayLink else { return }
        
        CVDisplayLinkSetOutputCallback(displayLink, { (_, _, _, _, _, context) -> CVReturn in
            let view = Unmanaged<ScrollingMIDIGraphView>.fromOpaque(context!).takeUnretainedValue()
            
            DispatchQueue.main.async {
                view.sampleAndRender()
            }
            
            return kCVReturnSuccess
        }, Unmanaged.passUnretained(self).toOpaque())
        
        CVDisplayLinkStart(displayLink)
    }
    
    // MARK: - MIDI Configuration
    
    func configure(source: MIDIDevice, 
                   ccNumber: ContinuousController,
                   noteNumber: UInt8) {
        
        // CC stream
        Task { @MainActor in
            for await ccData in await MIDIService.shared.ccStream(from: source) {
                guard ccData.cc == ccNumber else { continue }
                self.currentCCValue = ccData.value
            }
        }
        
        // Note stream
        Task { @MainActor in
            for await noteData in await MIDIService.shared.noteStream(from: source) {
                guard noteData.note == noteNumber else { continue }
                self.currentNoteVelocity = noteData.velocity
            }
        }
    }
    
    // MARK: - Sampling and Rendering (60 Hz)
    
    private func sampleAndRender() {
        // Sample current MIDI values
        let ccValue = CGFloat(currentCCValue) / 127.0
        
        // Detect note event
        var noteValue: CGFloat? = nil
        if currentNoteVelocity != lastNoteVelocity && currentNoteVelocity > 0 {
            noteValue = CGFloat(currentNoteVelocity) / 127.0
            lastNoteVelocity = currentNoteVelocity
        } else if currentNoteVelocity == 0 && lastNoteVelocity > 0 {
            lastNoteVelocity = 0
        }
        
        // Create data point
        dataPoints.append(ccValue)
        
        // Maintain max size (scrolling)
        if dataPoints.count > maxDataPoints {
            dataPoints.removeFirst()
        }
        
        // Render
        updateGraphPath()
        if noteValue != nil {
            addNoteMarker(at: dataPoints.count - 1, velocity: noteValue!)
        }
    }
    
    private func updateGraphPath() {
        guard dataPoints.count > 1 else { return }
        
        let width = bounds.width
        let height = bounds.height
        let xStep = width / CGFloat(dataPoints.count - 1)
        
        let path = CGMutablePath()
        
        for (index, value) in dataPoints.enumerated() {
            let x = CGFloat(index) * xStep
            let y = height * (1 - value)
            
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        graphLayer.path = path
        CATransaction.commit()
    }
    
    private func addNoteMarker(at index: Int, velocity: CGFloat) {
        let width = bounds.width
        let height = bounds.height
        let xStep = width / CGFloat(dataPoints.count - 1)
        
        let x = CGFloat(index) * xStep
        let y = height * (1 - velocity)
        
        let marker = CAShapeLayer()
        marker.path = CGPath(ellipseIn: CGRect(x: x - 4, y: y - 4, width: 8, height: 8), transform: nil)
        marker.fillColor = NSColor.red.cgColor
        
        noteMarkersLayer.addSublayer(marker)
    }
    
    // MARK: - Cleanup
    
    deinit {
        if let displayLink = displayLink {
            CVDisplayLinkStop(displayLink)
        }
    }
}
```

**Flow:**
```
MIDI CC arrives    → currentCCValue = 70
MIDI Note arrives  → currentNoteVelocity = 100

CVDisplayLink fires (60 Hz):
  ↓
sampleAndRender():
  ↓
Sample: ccValue = 70, noteVelocity = 100
  ↓
Create data point with ccValue
  ↓
Detect note event (velocity changed)
  ↓
Add to dataPoints array
  ↓
Update graph path
  ↓
Add note marker if note detected
  ↓
Done (16.7ms later, repeat)
```

### Example 3: High-Performance with Buffering

```swift
@MainActor
class BufferedMIDIGraphView: NSView {
    // MARK: - State
    private var displayLink: CVDisplayLink?
    private var ccValueBuffer: [UInt8] = []
    private var dataPoints: [CGFloat] = []
    private let maxDataPoints = 200
    private let maxBufferSize = 5
    
    // MARK: - MIDI Configuration
    
    func configure(source: MIDIDevice, ccNumber: ContinuousController) {
        Task { @MainActor in
            for await ccData in await MIDIService.shared.ccStream(from: source) {
                guard ccData.cc == ccNumber else { continue }
                
                // Buffer the value
                self.ccValueBuffer.append(ccData.value)
                if self.ccValueBuffer.count > self.maxBufferSize {
                    self.ccValueBuffer.removeFirst()
                }
            }
        }
    }
    
    // MARK: - CVDisplayLink Callback
    
    private func sampleAndRender() {
        guard !ccValueBuffer.isEmpty else {
            // No new data, just repeat last value
            if let lastValue = dataPoints.last {
                dataPoints.append(lastValue)
            }
            return
        }
        
        // Option A: Use latest value
        let latestValue = CGFloat(ccValueBuffer.last!) / 127.0
        
        // Option B: Average buffered values (smoothing)
        // let sum = ccValueBuffer.reduce(0, +)
        // let average = CGFloat(sum) / CGFloat(ccValueBuffer.count) / 127.0
        
        dataPoints.append(latestValue)
        ccValueBuffer.removeAll()
        
        if dataPoints.count > maxDataPoints {
            dataPoints.removeFirst()
        }
        
        updateGraphPath()
    }
}
```

**When to use buffering:**
- Very rapid MIDI (100+ messages/sec)
- Want smoothing option
- Don't want to miss bursts

---

## Common Misconceptions

### Misconception 1: "I need to throttle CVDisplayLink"

**Wrong thinking:**
```
MIDI: 20 messages/sec
CVDisplayLink: 60 callbacks/sec
60 > 20, wasteful!
```

**Reality:**
```
CVDisplayLink reading a variable 60 times/sec:
  Cost per read: ~10 nanoseconds
  Total cost: 600 nanoseconds/sec
  Percentage of CPU: 0.00006%

Not wasteful. Negligible cost.
```

### Misconception 2: "MIDI and CVDisplayLink must synchronize"

**Wrong thinking:**
```
When MIDI arrives, notify CVDisplayLink
When CVDisplayLink fires, wait for MIDI
```

**Reality:**
```
They don't coordinate at all!

MIDI writes when it wants
CVDisplayLink reads when it wants
Both on main thread = safe
No synchronization needed
```

### Misconception 3: "Need to queue MIDI messages"

**Wrong thinking:**
```
MIDI arrives → Queue message
CVDisplayLink → Dequeue message
Process in order
```

**Reality:**
```
For visualization, you usually want LATEST value:

MIDI: 64 → 65 → 66 → 67 → 68
CVDisplayLink reads: 68 (latest)

Old values already visualized or irrelevant.
Simple variable assignment is perfect.
```

### Misconception 4: "60 Hz is too fast for MIDI"

**Wrong thinking:**
```
MIDI is slow (20-100 messages/sec)
60 Hz is overkill
```

**Reality:**
```
Your DISPLAY refreshes at 60 Hz.
If you update slower, you get stuttery animation.

Even if MIDI is 20 Hz:
  MIDI:    [64    ] [65    ] [66    ]
  Display: [64][64][64][65][65][65]
           Smooth hold between updates!

At 20 Hz update:
  Display: [64][64][64][65][65][65]
           But GPU only gets new frame every 3rd refresh
           Result: Stutter/judder
```

---

## Performance Analysis

### CPU Usage Breakdown

```
Component                          CPU Time    Frequency    Total/sec
--------------------------------------------------|-----------|----------
MIDI AsyncStream callback          1 μs        20/sec       20 μs
  - Filter CC number               0.1 μs
  - Write to variable              0.05 μs
  - Swift overhead                 0.85 μs

CVDisplayLink callback             0.5 μs      60/sec       30 μs
  - Context retrieval              0.1 μs
  - Marshal to main                0.4 μs

Main thread update                 2000 μs     60/sec       120,000 μs
  - Read variable                  0.01 μs
  - Create DataPoint               0.1 μs
  - Array operations               10 μs
  - Create CGPath (200 points)    1500 μs
  - CATransaction                  500 μs

Total CPU per second: ~120 ms
Available time: 1000 ms
CPU usage: ~12%

Breakdown:
  MIDI: 0.002%
  CVDisplayLink callback: 0.003%
  Rendering: 11.995%

Conclusion: MIDI and CVDisplayLink overhead is NEGLIGIBLE
```

### Memory Usage

```
Component                    Memory
----------------------------------------
currentCCValue               1 byte
currentNoteVelocity          1 byte
dataPoints array (200)       1600 bytes (200 * 8)
CALayer                      ~4 KB
CVDisplayLink                ~1 KB
Total:                       ~7 KB

Negligible!
```

### Best Practices Summary

1. **Use simple variable assignment for MIDI**
```swift
✅ self.currentCCValue = ccData.value
❌ self.ccQueue.enqueue(ccData.value)
```

2. **Use @MainActor for safety**
```swift
✅ @MainActor class MIDIGraphView
❌ Manual synchronization with locks
```

3. **Let CVDisplayLink run at full speed**
```swift
✅ CVDisplayLinkStart(displayLink)  // 60 Hz
❌ if frameCounter % 2 == 0 { ... }  // Throttled
```

4. **Sample on every frame**
```swift
✅ let value = currentCCValue  // Every frame
❌ if newDataAvailable { ... }  // Conditional
```

5. **Keep MIDI callback simple**
```swift
✅ self.currentCCValue = value  // Just write
❌ self.updateGraph()           // Don't trigger render here
```

---

## Summary

### Key Principles

1. **MIDI and CVDisplayLink are independent streams**
   - MIDI writes when data arrives (irregular)
   - CVDisplayLink reads when display refreshes (regular)
   - No synchronization needed

2. **Sample-and-hold is the pattern**
   - MIDI writes latest value
   - CVDisplayLink samples latest value
   - Automatically preserves timing

3. **Thread safety via @MainActor**
   - Both access main thread
   - No race conditions
   - No locks needed

4. **Don't throttle CVDisplayLink**
   - Display refreshes at 60 Hz
   - Update at 60 Hz for smoothness
   - Reading variable is negligible cost

5. **Keep it simple**
   - MIDI callback: Just write the value
   - CVDisplayLink: Just read and render
   - No queues, no coordination, no complexity

### Recommended Structure

```swift
@MainActor
class MIDIGraphView: NSView {
    // Simple state
    private var currentCCValue: UInt8 = 0
    
    // MIDI: Write when data arrives
    func setupMIDI() {
        Task { @MainActor in
            for await cc in stream {
                self.currentCCValue = cc.value  // Simple!
            }
        }
    }
    
    // CVDisplayLink: Read at 60 Hz
    CVDisplayLinkSetOutputCallback(...) {
        DispatchQueue.main.async {
            let value = view.currentCCValue  // Simple!
            view.render(value)
        }
    }
}
```

This is elegant, performant, and correct. Don't overthink it!
