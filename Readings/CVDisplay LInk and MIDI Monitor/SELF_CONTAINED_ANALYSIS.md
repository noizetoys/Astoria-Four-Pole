# Self-Contained Graph View: Direct MIDI Integration Analysis

## Overview of Proposed Architecture

Instead of:
```
MIDI → GraphViewModel → Timer → GraphContainerView → MIDIGraphLayer
```

We would have:
```
MIDI → GraphContainerView (owns data) → CVDisplayLink → MIDIGraphLayer
```

This mirrors the LFO architecture exactly.

---

## Detailed Analysis

### Current Architecture (External ViewModel)

```
┌─────────────────────────────────────────────────────────────┐
│ GraphViewModel (@MainActor class)                           │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ MIDI Service Integration                             │  │
│  │                                                       │  │
│  │  - ccListenerTask: Task<Void, Never>                │  │
│  │  - noteListenerTask: Task<Void, Never>              │  │
│  │  - Listens to: midiService.ccStream(from: source)   │  │
│  │  - Listens to: midiService.noteStream(from: source) │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ Data Management                                       │  │
│  │                                                       │  │
│  │  @Published var dataPoints: [DataPoint] = []        │  │
│  │  @Published var ccValue: UInt8 = 0                  │  │
│  │  @Published var noteValue: UInt8 = 0                │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ Timer-based Sampling                                  │  │
│  │                                                       │  │
│  │  Timer.scheduledTimer(0.05s) → samples cc/note      │  │
│  │  Creates DataPoint with current values               │  │
│  │  Appends to dataPoints array                         │  │
│  │  Manages scrolling (removes old points)              │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              ↓
                    @ObservedObject binding
                              ↓
┌─────────────────────────────────────────────────────────────┐
│ GraphContainerView (NSView)                                 │
│                                                              │
│  weak var viewModel: GraphViewModel?  ← EXTERNAL REFERENCE  │
│                                                              │
│  Timer (60 Hz) → reads viewModel.dataPoints                │
│                                                              │
│  updateFromTimer() {                                        │
│    guard let viewModel = viewModel                         │
│    let dataPoints = viewModel.dataPoints  ← EXTERNAL READ  │
│    graphLayer.updateData(dataPoints)                       │
│  }                                                          │
└─────────────────────────────────────────────────────────────┘
```

**Key characteristics:**
- ViewModel lives in SwiftUI world (@MainActor)
- View has weak reference to ViewModel
- View READS data from external source
- Two-tier sampling: AsyncStream → ViewModel timer → View timer
- Published properties trigger SwiftUI updates

---

### Proposed Architecture (Self-Contained View)

```
┌─────────────────────────────────────────────────────────────┐
│ GraphContainerView (NSView) - SELF-CONTAINED                │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ MIDI Service Integration (INTERNAL)                  │  │
│  │                                                       │  │
│  │  private var ccListenerTask: Task<Void, Never>?     │  │
│  │  private var noteListenerTask: Task<Void, Never>?   │  │
│  │  private weak var midiService: MIDIService = .shared│  │
│  │                                                       │  │
│  │  Listens to: midiService.ccStream(from: source)     │  │
│  │  Listens to: midiService.noteStream(from: source)   │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ Data Management (INTERNAL)                           │  │
│  │                                                       │  │
│  │  private var dataPoints: [DataPoint] = []           │  │
│  │  private var ccValue: UInt8 = 0                     │  │
│  │  private var noteValue: UInt8 = 0                   │  │
│  │  private var lastNoteValue: UInt8 = 0               │  │
│  │  private let maxDataPoints = 200                    │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ CVDisplayLink Animation (like LFO)                   │  │
│  │                                                       │  │
│  │  private var displayLink: CVDisplayLink?            │  │
│  │                                                       │  │
│  │  CVDisplayLink callback (~60 Hz)                    │  │
│  │    → DispatchQueue.main.async                       │  │
│  │    → updateFromDisplayLink()                        │  │
│  │    → samples current cc/note values                 │  │
│  │    → creates DataPoint                              │  │
│  │    → manages dataPoints array                       │  │
│  │    → calls graphLayer.updateData(dataPoints)        │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ Configuration (from SwiftUI)                         │  │
│  │                                                       │  │
│  │  func configure(source: MIDIDevice,                 │  │
│  │                 channel: UInt8,                     │  │
│  │                 ccNumber: ContinuousController,     │  │
│  │                 noteNumber: UInt8)                  │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              ↑
                    No @ObservedObject
                              ↑
┌─────────────────────────────────────────────────────────────┐
│ GraphLayerView (NSViewRepresentable)                        │
│                                                              │
│  var source: MIDIDevice          ← VALUE TYPES              │
│  var channel: UInt8              ← VALUE TYPES              │
│  var ccNumber: CC                ← VALUE TYPES              │
│  var noteNumber: UInt8           ← VALUE TYPES              │
│                                                              │
│  makeNSView() {                                             │
│    let view = GraphContainerView()                         │
│    view.configure(source, channel, cc, note)               │
│    view.startListening()                                   │
│    return view                                             │
│  }                                                          │
│                                                              │
│  updateNSView() {                                           │
│    // Only if configuration changed                        │
│    nsView.configure(source, channel, cc, note)            │
│  }                                                          │
└─────────────────────────────────────────────────────────────┘
```

**Key characteristics:**
- View owns all state
- View listens to MIDI directly (like LFO listens to display)
- CVDisplayLink on separate thread
- Single-tier sampling: AsyncStream → View's CVDisplayLink
- No SwiftUI @Published properties

---

## Advantages of Self-Contained Approach

### 1. Architectural Consistency with LFO

**LFO Pattern:**
```swift
class LFOLayerView: NSView {
    private var phase: Double = 0
    private var frequency: Double = 1.0
    private var displayLink: CVDisplayLink?
    
    func update(speed: UInt8, shape: ...) {
        frequency = convertToFrequency(speed)  // Copy in
    }
    
    private func updateAnimation() {
        phase += deltaPhase  // Update internal state
        updateTracerPosition()  // Render
    }
}
```

**Graph Pattern (proposed):**
```swift
class GraphContainerView: NSView {
    private var dataPoints: [DataPoint] = []
    private var ccValue: UInt8 = 0
    private var displayLink: CVDisplayLink?
    
    func configure(source: MIDIDevice, ...) {
        setupMIDIListeners(source)  // Set up streams
    }
    
    private func updateFromDisplayLink() {
        sampleCurrentValues()  // Sample cc/note
        createDataPoint()      // Add to array
        graphLayer.updateData(dataPoints)  // Render
    }
}
```

**Similarity:** Both views own their animation state and update it internally.

### 2. Elimination of External Dependencies

**Current (problematic):**
```swift
// GraphContainerView depends on GraphViewModel
weak var viewModel: GraphViewModel?  // Can become nil

private func updateFromTimer() {
    guard let viewModel = viewModel else { return }  // Fragile
    let dataPoints = viewModel.dataPoints  // External read
}
```

**Proposed (robust):**
```swift
// GraphContainerView owns its data
private var dataPoints: [DataPoint] = []

private func updateFromDisplayLink() {
    // Direct access to own data
    graphLayer.updateData(dataPoints)  // No external dependency
}
```

**Benefit:** No weak reference that can break. No external state access.

### 3. Thread Independence

**Current:**
```
Main Thread:
  - SwiftUI updates
  - ViewModel timer (50ms)
  - View timer (16.7ms)
  - All competing for main thread time
```

**Proposed:**
```
CVDisplayLink Thread:
  - Runs independently
  - Not affected by main thread
  - Callback marshals to main thread only for UI update

Main Thread:
  - SwiftUI updates (don't affect CVDisplayLink)
  - AsyncStream updates (append to view's state)
```

**Benefit:** CVDisplayLink immune to SwiftUI's main thread activity.

### 4. Simpler State Management

**Current:**
```
GraphViewModel:
  @Published var dataPoints  → SwiftUI observes
  Timer samples every 50ms   → Updates dataPoints
  GraphContainerView:
    Timer reads every 16.7ms → Reads dataPoints from ViewModel
```

Two timers, published properties, external observation.

**Proposed:**
```
GraphContainerView:
  AsyncStream updates      → Sets ccValue/noteValue
  CVDisplayLink samples    → Reads ccValue/noteValue, creates DataPoint
```

One update loop, no published properties, internal state only.

### 5. No SwiftUI Observation Chain

**Current:**
```
GraphViewModel → @Published dataPoints
                 ↓
MIDIGraphView → @ObservedObject viewModel
                 ↓
GraphLayerView → @ObservedObject viewModel
                 ↓
GraphContainerView → weak var viewModel
```

Every level observes/references the ViewModel. SwiftUI involved in the chain.

**Proposed:**
```
GraphLayerView → Simple value-type parameters
                 ↓
GraphContainerView → Owns all state
```

No observation chain. SwiftUI only provides configuration, not data.

---

## Potential Issues and Solutions

### Issue 1: AsyncStream and Thread Safety

**Problem:**
AsyncStream callbacks might happen on different threads. If we're updating `ccValue` from AsyncStream and reading it from CVDisplayLink callback, we have a race condition.

```swift
// AsyncStream callback (could be any thread)
for await ccData in midiService.ccStream(from: source) {
    self.ccValue = ccData.value  // ⚠️ Write
}

// CVDisplayLink callback (separate thread)
DispatchQueue.main.async {
    let cc = self.ccValue  // ⚠️ Read
}
```

**Solution 1: Actor Isolation**
```swift
@MainActor
class GraphContainerView: NSView {
    private var ccValue: UInt8 = 0
    
    // AsyncStream naturally runs on main actor
    for await ccData in midiService.ccStream(from: source) {
        self.ccValue = ccData.value  // ✅ Main actor
    }
    
    // CVDisplayLink marshals to main
    DispatchQueue.main.async {
        await self.updateFromDisplayLink()  // ✅ Main actor
    }
}
```

**Solution 2: Atomic Access**
```swift
private let queue = DispatchQueue(label: "com.graph.data")
private var _ccValue: UInt8 = 0
private var ccValue: UInt8 {
    get { queue.sync { _ccValue } }
    set { queue.async { self._ccValue = newValue } }
}
```

**Recommendation:** Use @MainActor. AsyncStream for MIDI already delivers on main actor, CVDisplayLink marshals to main. Clean and safe.

### Issue 2: MIDI Source Lifecycle

**Problem:**
Who owns the MIDIDevice source? What if it disconnects?

**Current Approach (ViewModel):**
```swift
// GraphViewModel manages source
init(configuration: MiniworksDeviceProfile) {
    NotificationCenter.default.publisher(for: .midiSourceConnected)
        .sink { self.start() }
}
```

**Proposed Approach (View):**
```swift
// Option A: Pass source every time it changes
struct GraphLayerView: NSViewRepresentable {
    var source: MIDIDevice?  // Optional
    
    func updateNSView(_ nsView: GraphContainerView, context: Context) {
        if let source = source {
            nsView.configure(source: source)
        } else {
            nsView.stopListening()
        }
    }
}

// Option B: View subscribes to notifications
class GraphContainerView: NSView {
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        NotificationCenter.default.publisher(for: .midiSourceConnected)
            .sink { [weak self] notification in
                self?.handleSourceConnected(notification)
            }
            .store(in: &cancellables)
    }
}
```

**Recommendation:** Option A. Keep view passive - it receives configuration from SwiftUI. SwiftUI layer handles source lifecycle notifications and passes current source to view.

### Issue 3: Configuration Changes

**Problem:**
User changes monitored CC number or note number. How does view handle this?

**Current:**
```swift
// ViewModel keeps tasks running, just filters different messages
for await ccData in midiService.ccStream(from: source) {
    guard ccData.cc == config.ccNumber else { continue }
    self.ccValue = ccData.value
}
```

**Proposed:**
```swift
// Option A: Restart tasks when config changes
func configure(source: MIDIDevice, ccNumber: CC, noteNumber: UInt8) {
    // Stop old tasks
    ccListenerTask?.cancel()
    noteListenerTask?.cancel()
    
    // Start new tasks with new filters
    ccListenerTask = Task {
        for await ccData in midiService.ccStream(from: source) {
            guard ccData.cc == ccNumber else { continue }
            self.ccValue = ccData.value
        }
    }
}

// Option B: Keep one task, update filter
private var currentCCNumber: CC = .breathControl

func configure(ccNumber: CC) {
    currentCCNumber = ccNumber
}

ccListenerTask = Task {
    for await ccData in midiService.ccStream(from: source) {
        guard ccData.cc == currentCCNumber else { continue }  // Check current
        self.ccValue = ccData.value
    }
}
```

**Recommendation:** Option B. Less task churn, cleaner. Just update the filter criteria.

### Issue 4: Memory Management

**Problem:**
Who owns what? Reference cycles?

**Current:**
```swift
GraphViewModel (strong)
    ↓ owns
Timer (strong)
    ↓ captures [weak self]
GraphViewModel ✓

GraphContainerView (strong)
    ↓ weak var
GraphViewModel (no retain cycle)
```

**Proposed:**
```swift
GraphContainerView (strong)
    ↓ owns
CVDisplayLink (C object, no ARC)
    ↓ callback context (unmanaged)
GraphContainerView ✓

GraphContainerView (strong)
    ↓ owns
Task (strong)
    ↓ captures [weak self]
GraphContainerView ✓

GraphLayerView (struct, no ownership)
    ↓ creates
GraphContainerView (handed to SwiftUI)
```

**Analysis:** No cycles. Tasks capture weak self, CVDisplayLink uses unmanaged pointer (like LFO), SwiftUI owns the view.

**Recommendation:** Same pattern as LFO. Proven to work.

### Issue 5: Data Point Creation Logic

**Problem:**
Currently, ViewModel's timer creates DataPoints. Where does this logic go?

**Current:**
```swift
// In GraphViewModel
timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
    let ccVal = CGFloat(self.ccValue)
    let currentNoteValue = self.noteValue
    
    var noteVal: CGFloat? = nil
    if currentNoteValue != self.lastNoteValue && currentNoteValue > 0 {
        noteVal = CGFloat(currentNoteValue)
        self.lastNoteValue = currentNoteValue
    }
    
    let newPoint = DataPoint(value: ccVal, hasNote: noteVal != nil, noteValue: noteVal)
    self.dataPoints.append(newPoint)
    
    if self.dataPoints.count > self.maxDataPoints {
        self.dataPoints.removeFirst(...)
    }
}
```

**Proposed:**
```swift
// In GraphContainerView
private func updateFromDisplayLink() {
    // Sample current values (set by AsyncStreams)
    let ccVal = CGFloat(self.ccValue)
    let currentNoteValue = self.noteValue
    
    // Detect note events
    var noteVal: CGFloat? = nil
    if currentNoteValue != self.lastNoteValue && currentNoteValue > 0 {
        noteVal = CGFloat(currentNoteValue)
        self.lastNoteValue = currentNoteValue
    }
    
    // Create and store data point
    let newPoint = DataPoint(value: ccVal, hasNote: noteVal != nil, noteValue: noteVal)
    dataPoints.append(newPoint)
    
    // Manage scrolling
    if dataPoints.count > maxDataPoints {
        dataPoints.removeFirst(dataPoints.count - maxDataPoints)
    }
    
    // Update display
    graphLayer.updateData(dataPoints)
}
```

**Analysis:** Exact same logic, just moved into the view. This is actually cleaner - the view owns both the data and the rendering.

**Recommendation:** Move this logic into view. It's presentation logic (how to sample and display data), not business logic.

### Issue 6: Testing and Debugging

**Problem:**
How do we test a self-contained view?

**Current:**
```swift
// Easy to test ViewModel in isolation
let viewModel = GraphViewModel(config: testConfig)
viewModel.start()
// Inject mock MIDI data
// Assert on viewModel.dataPoints
```

**Proposed:**
```swift
// Option A: Expose data for testing
class GraphContainerView: NSView {
    #if DEBUG
    var dataPointsForTesting: [DataPoint] { dataPoints }
    #endif
}

// Option B: Dependency injection
class GraphContainerView: NSView {
    init(midiService: MIDIService = .shared) {
        self.midiService = midiService
    }
}

// In tests
let mockService = MockMIDIService()
let view = GraphContainerView(midiService: mockService)
```

**Recommendation:** Option B if testing is important. Otherwise, focus on integration tests. Views are inherently harder to unit test than view models.

---

## What You Might Be Missing

### 1. The Power of Simplicity

The LFO view works because it's **stunningly simple**:
- Owns its state (phase, frequency)
- Updates its state (CVDisplayLink)
- Renders its state (CALayer)

No external dependencies. No observation chains. No weak references.

The graph can be equally simple:
- Owns its state (dataPoints, ccValue, noteValue)
- Updates its state (CVDisplayLink + AsyncStream)
- Renders its state (CALayer)

**Insight:** Sometimes the solution isn't clever architecture - it's eliminating architecture.

### 2. SwiftUI's Observation is the Problem, Not the Solution

Every time we use `@ObservedObject`, `@Published`, or `@StateObject`, we give SwiftUI control over our view's lifecycle. For a continuously-updating visualization, this is fighting against the framework.

**Current:** SwiftUI observes ViewModel → ViewModel changes 20x/second → SwiftUI thinks "this view might need updating"

**Proposed:** SwiftUI passes configuration → View runs independently → SwiftUI never thinks about it

**Insight:** For animations and real-time visualizations, SwiftUI observation is overhead, not benefit.

### 3. AppKit is a Peer to SwiftUI, Not a Subordinate

We often think: "SwiftUI view contains AppKit view"

But actually: "SwiftUI hosts AppKit view"

Once created, the AppKit view can run completely independently. SwiftUI just:
1. Creates it
2. Configures it
3. Destroys it when done

Everything else? AppKit's domain.

**Insight:** Let AppKit views be AppKit views. Don't make them SwiftUI puppets.

### 4. AsyncStream is Actually Thread-Safe

You might worry: "AsyncStream callbacks on different threads will cause race conditions"

But AsyncStream actually has continuation actor isolation:

```swift
AsyncStream<MIDIEvent> { continuation in
    // This closure can capture @MainActor context
}

// And consumption inherits that:
for await event in stream {
    // This runs on the same actor as the stream was created
}
```

**Insight:** If your MIDI service creates streams on the @MainActor, your for-await loops run on @MainActor. No special synchronization needed.

### 5. CVDisplayLink is Truly Independent

You might think: "CVDisplayLink callback happens on a thread, then I marshal to main - doesn't that defeat the purpose?"

Actually, no:

```
Separate Thread                Main Thread
    ↓
CVDisplayLink fires            [Idle]
    ↓
Callback                       [Idle]
    ↓
DispatchQueue.main.async       [Enqueues work]
    ↓
Returns                        [Still idle]
                              [When ready...]
                              Execute queued work
                              Update UI
```

The key: The **firing** isn't blocked by main thread. It fires independently, queues work, and returns. Main thread processes the queue when it can.

Compare to Timer:

```
Main Thread (only thread)
    ↓
[SwiftUI update in progress...]
    ↓
Timer wants to fire → BLOCKED
    ↓
[SwiftUI still updating...]
    ↓
Timer still blocked...
    ↓
[Finally done]
    ↓
Timer fires (late)
```

**Insight:** CVDisplayLink's separate thread means it never waits. Timer on main thread always waits.

### 6. The Real Cost of Weak References

```swift
weak var viewModel: GraphViewModel?
```

Every time you access this, the runtime:
1. Checks if the object still exists
2. Temporarily strengthens the reference
3. Returns it (or nil)

In a 60 Hz loop, that's 60 checks per second.

But also: the check can fail! If SwiftUI decides to recreate something upstream, viewModel becomes nil, and your graph stops.

**With internal state:**
```swift
private var dataPoints: [DataPoint] = []
```

No check. No nil possibility. Just direct access.

**Insight:** Weak references are runtime overhead AND fragility. Avoid when possible.

---

## Recommended Approach

### Phase 1: Minimize Changes (Proof of Concept)

1. **Move AsyncStream setup into GraphContainerView**
   - Keep everything else the same
   - Just test if direct MIDI → View works
   - Keep Timer for now

2. **Add logging**
   - Verify AsyncStream is delivering data
   - Verify view is receiving it
   - Verify no threading issues

3. **If working, proceed to Phase 2**

### Phase 2: Full Conversion

1. **Replace Timer with CVDisplayLink**
   - Copy LFO's CVDisplayLink setup exactly
   - Replace timer callback with CVDisplayLink callback
   - Test that update rate is correct

2. **Remove GraphViewModel dependency**
   - Make GraphContainerView own dataPoints array
   - Move sampling logic into view
   - Pass only configuration via NSViewRepresentable

3. **Simplify SwiftUI interface**
   - Remove @ObservedObject
   - Pass simple value types (source, channel, cc, note)
   - Let view handle everything else

### Phase 3: Cleanup and Optimization

1. **Remove GraphViewModel entirely**
   - If view is self-contained, ViewModel is unused
   - Or repurpose it for business logic only (not data holding)

2. **Add configuration UI**
   - Since view is self-contained, maybe add controls directly
   - Or keep configuration in SwiftUI, pass to view

3. **Performance tuning**
   - Verify CVDisplayLink is smooth
   - Check memory usage (layer pool, data points array)
   - Profile if needed

---

## Comparison: Timer vs CVDisplayLink

### Timer (Current)

**Pros:**
- Simple to understand
- Easy to debug
- Works on main thread (easy access to UI)

**Cons:**
- Tied to RunLoop
- Can be blocked by UI activity
- Even .common mode isn't guaranteed
- Main thread contention

### CVDisplayLink (Proposed)

**Pros:**
- Separate thread (never blocked)
- Display-synchronized (smooth animation)
- Proven pattern (LFO works)
- No RunLoop dependency

**Cons:**
- More complex setup
- Need to marshal to main thread
- C API (less Swift-y)
- Harder to debug

**Verdict:** For continuously updating visualization, CVDisplayLink's benefits outweigh complexity.

---

## Critical Questions to Answer

Before implementing, think about:

### 1. Who owns the MIDI source lifecycle?

**Option A:** SwiftUI layer
- Listens for source connected/disconnected
- Passes current source to view
- View is passive

**Option B:** View layer
- Subscribes to notifications itself
- Handles connection/disconnection
- SwiftUI just creates/destroys view

**Recommendation:** Option A. Separation of concerns. SwiftUI handles app state, view handles rendering.

### 2. What if user changes monitored CC/note while data is streaming?

**Option A:** Clear data, start fresh
```swift
func configure(ccNumber: CC) {
    dataPoints.removeAll()  // Clear old data
    self.ccNumber = ccNumber
}
```

**Option B:** Keep data, just update filter
```swift
func configure(ccNumber: CC) {
    // Old points stay (might be confusing visually)
    self.ccNumber = ccNumber
}
```

**Recommendation:** Option A. Clear data when configuration changes. Less confusing.

### 3. Should view expose its data for other purposes?

**Current:** ViewModel is @Published, so other views can observe it

**Proposed:** View owns data privately

**If you need data elsewhere:**
- Option A: Keep ViewModel for data, view for rendering only
- Option B: View publishes updates via Combine
- Option C: Callback/delegate pattern

**Recommendation:** Depends on use case. If graph is isolated, full self-contained is fine.

---

## Summary of Reasoning

### Why This Will Work

1. **Matches proven pattern** (LFO)
2. **Eliminates weak reference** (can't become nil)
3. **Eliminates external dependency** (owns data)
4. **Uses separate thread** (CVDisplayLink)
5. **Simpler state** (no SwiftUI observation)

### What Could Go Wrong

1. **Thread safety** (but @MainActor solves this)
2. **Source lifecycle** (but SwiftUI can manage this)
3. **Testing complexity** (but integration tests work)
4. **Configuration changes** (but explicit configure() method handles this)

### What You're Missing

Nothing fundamental! This is actually a **simplification**, not a complication. You're:
- Removing layers (ViewModel)
- Removing observation (@ObservedObject)
- Removing weak references
- Removing one timer (keeping CVDisplayLink)

The only new piece is AsyncStream in the view, but that's actually cleaner than going through ViewModel.

### Why I'm Confident

Because **LFO already proves it works**. The pattern is:
1. View owns state
2. External input updates state (display refresh for LFO, MIDI for graph)
3. CVDisplayLink samples state and renders

Your LFO works perfectly with this pattern. Graph will too.

---

## Final Recommendation

**Go for it.** The proposed architecture is:
- Simpler (fewer layers)
- More robust (no weak references)
- Better performing (CVDisplayLink)
- Proven (LFO pattern)

The risks are minimal and the benefits are substantial. Your instinct to mirror the LFO architecture is correct.

Start with Phase 1 (AsyncStream in view), verify it works, then proceed to CVDisplayLink. The path is clear and the destination is better than where you are now.
