# AsyncStream and Continuation: Complete Reference Guide
## Understanding Reactive MIDI Streams in Swift

## Table of Contents
1. [Overview](#overview)
2. [The Problem We're Solving](#the-problem)
3. [AsyncStream Fundamentals](#asyncstream-fundamentals)
4. [Continuation Deep Dive](#continuation-deep-dive)
5. [MIDI Manager Implementation](#midi-manager-implementation)
6. [Complete Examples](#complete-examples)
7. [Common Patterns](#common-patterns)
8. [Debugging and Troubleshooting](#debugging)

---

## Overview

### What is AsyncStream?

`AsyncStream` is Swift's way of creating asynchronous sequences - streams of values that arrive over time. Think of it like a river of data:

```
Time →
┌─────┬─────┬─────┬─────┬─────┬─────┐
│ 🎵  │ 🎵  │ 🎵  │ 🎵  │ 🎵  │ 🎵  │  MIDI messages flowing over time
└─────┴─────┴─────┴─────┴─────┴─────┘
```

### Why Do We Need It?

Traditional callback-based APIs are messy:

```swift
// ❌ OLD WAY: Callback Hell
midiInput.onMessage = { message in
    // What thread am I on?
    // How do I cancel this?
    // How do I handle errors?
}
```

AsyncStream gives us:

```swift
// ✅ NEW WAY: Clean Async/Await
for await message in midiStream {
    // Clear, sequential code
    // Easy to cancel (just break)
    // Thread-safe by default
}
```

---

## The Problem

### MIDI Messages Arrive Unpredictably

```
Device sends MIDI → CoreMIDI callback → How do we get this to Swift code?

Time: 0ms     50ms    100ms   150ms   200ms   250ms
      │       │       │       │       │       │
      Note    CC      SysEx   CC      Note    SysEx
      On      #16     start   #17     Off     end
```

**Challenges:**
1. Messages arrive on background threads (CoreMIDI callbacks)
2. We need to buffer messages if consumer is slow
3. We need to handle backpressure (too many messages)
4. We need to allow cancellation
5. We need thread safety

**AsyncStream solves all of these!**

---

## AsyncStream Fundamentals

### Basic Concept

An `AsyncStream` has two sides:

```
┌─────────────────┐                    ┌─────────────────┐
│   PRODUCER      │                    │    CONSUMER     │
│                 │                    │                 │
│  Continuation   │ ─────────────────→ │   AsyncStream   │
│  .yield(value)  │   Stream of Data   │   for await     │
│                 │                    │                 │
└─────────────────┘                    └─────────────────┘
```

### Creating an AsyncStream

```swift
let stream = AsyncStream<Int> { continuation in
    // This closure runs ONCE when the stream is created
    // The continuation is your "control panel" for the stream
    
    // Producer code: send values
    continuation.yield(1)
    continuation.yield(2)
    continuation.yield(3)
    
    // When done
    continuation.finish()
}

// Consumer code: receive values
for await value in stream {
    print(value)  // Prints: 1, 2, 3
}
```

### Key Properties

1. **Asynchronous**: Values arrive over time
2. **Sequential**: Values are delivered in order
3. **Backpressured**: Automatically buffers if consumer is slow
4. **Cancellable**: Breaking the loop cancels the stream
5. **Thread-safe**: Can yield from any thread

---

## Continuation Deep Dive

### What is a Continuation?

A `Continuation` is your handle for controlling a stream. It's like a remote control:

```swift
AsyncStream<String>.Continuation

Methods:
- yield(value)      // Send a value to the stream
- finish()          // Close the stream (no more values)
- onTermination     // Get notified when stream ends
```

### The Continuation Lifecycle

```
┌──────────────────────────────────────────────────────┐
│ Stream Creation                                       │
│ let stream = AsyncStream<Int> { continuation in      │
│     // Continuation is ALIVE                          │
│ }                                                     │
└────────────────┬─────────────────────────────────────┘
                 │
                 ↓
┌──────────────────────────────────────────────────────┐
│ Active Phase                                          │
│ continuation.yield(1)  // ✅ Works                    │
│ continuation.yield(2)  // ✅ Works                    │
│ continuation.yield(3)  // ✅ Works                    │
└────────────────┬─────────────────────────────────────┘
                 │
                 ↓
┌──────────────────────────────────────────────────────┐
│ Termination (one of these happens)                   │
│ - continuation.finish()   // Explicit close          │
│ - Consumer breaks loop    // Cancellation            │
│ - Consumer deallocated    // Cleanup                 │
└────────────────┬─────────────────────────────────────┘
                 │
                 ↓
┌──────────────────────────────────────────────────────┐
│ After Termination                                     │
│ continuation.yield(4)  // ❌ Silently ignored         │
└──────────────────────────────────────────────────────┘
```

### Storing Continuations

**Problem**: The continuation only exists inside the closure. How do we yield values later?

**Solution**: Store it!

```swift
class StreamManager {
    // Store continuation so we can yield values from anywhere
    private var continuation: AsyncStream<Int>.Continuation?
    
    func createStream() -> AsyncStream<Int> {
        AsyncStream { continuation in
            // Save continuation for later use
            self.continuation = continuation
            
            // Set up cleanup
            continuation.onTermination = { @Sendable _ in
                self.continuation = nil
            }
        }
    }
    
    func sendValue(_ value: Int) {
        // Yield from anywhere in your code!
        continuation?.yield(value)
    }
}
```

---

## MIDI Manager Implementation

### High-Level Architecture

```
CoreMIDI Callback (Background Thread)
         ↓
    [MIDI Bytes]
         ↓
    MIDIManager (Actor)
         ↓
  Process & Route to correct stream
         ↓
  Continuation.yield(data)
         ↓
  AsyncStream (Consumer's thread)
         ↓
    UI Code (MainActor)
```

### Step-by-Step: Creating a SysEx Stream

#### Step 1: Define the Storage

```swift
actor MIDIManager {
    // We need to store continuations because:
    // 1. CoreMIDI callbacks happen later (not during stream creation)
    // 2. We need to route data to the correct stream
    // 3. Multiple devices may be connected simultaneously
    
    private struct DeviceConnection {
        let source: MIDIDevice
        let destination: MIDIDevice
        
        // Store continuation for each stream type
        var sysexContinuation: AsyncStream<[UInt8]>.Continuation?
        var ccContinuation: AsyncStream<(UInt8, UInt8, UInt8)>.Continuation?
        var noteContinuation: AsyncStream<(Bool, UInt8, UInt8, UInt8)>.Continuation?
    }
    
    // One connection per device
    private var connections: [MIDIUniqueID: DeviceConnection] = [:]
}
```

#### Step 2: Create the Stream

```swift
public func sysexStream(from source: MIDIDevice) -> AsyncStream<[UInt8]> {
    // AsyncStream initializer with continuation
    AsyncStream { continuation in
        // This closure runs ONCE when someone starts consuming the stream
        
        // CRITICAL: We're inside an actor, but continuation might be used
        // from different contexts, so we need to store it carefully
        
        // Get the connection for this device
        guard var connection = connections[source.id] else {
            // No connection? Finish immediately
            continuation.finish()
            return
        }
        
        // Store the continuation
        connection.sysexContinuation = continuation
        connections[source.id] = connection
        
        // Set up cleanup when stream ends
        continuation.onTermination = { @Sendable termination in
            // @Sendable means this closure might run on any thread
            // We need to use Task to get back to the actor
            Task {
                await MIDIManager.shared.removeSysExContinuation(for: source.id)
            }
        }
        
        // Note: We do NOT call finish() here!
        // The stream stays open until:
        // 1. Consumer breaks the for loop
        // 2. We explicitly call continuation.finish()
        // 3. Consumer is deallocated
    }
}
```

**Why this pattern?**

```
User calls: for await data in await midi.sysexStream(from: device)
                                    ↓
                          sysexStream() is called
                                    ↓
                          AsyncStream { } closure runs
                                    ↓
                          Continuation is stored
                                    ↓
                          Stream is returned to user
                                    ↓
                          User's for loop starts waiting
                                    ↓
    (Stream is now active and waiting for data)
```

#### Step 3: Yielding Data to the Stream

```swift
// This gets called by CoreMIDI when data arrives
private func handleIncomingEvents(_ eventList: UnsafePointer<MIDIEventList>) {
    // Process events and extract SysEx data
    let sysexData: [UInt8] = processEvents(eventList)
    
    // Send to all active streams
    notifySysEx(sysexData)
}

private func notifySysEx(_ data: [UInt8]) {
    // Iterate through all connections
    for (deviceID, connection) in connections {
        // If this device has an active SysEx stream, send data to it
        if let continuation = connection.sysexContinuation {
            // YIELD: This sends data to the consumer
            continuation.yield(data)
            
            // The consumer's "for await" loop will now receive this data
        }
    }
}
```

**Data Flow:**

```
CoreMIDI callback
    ↓
handleIncomingEvents()
    ↓
Extract SysEx bytes: [0xF0, 0x3E, ..., 0xF7]
    ↓
notifySysEx([bytes])
    ↓
continuation.yield([bytes])  ← This is where the magic happens!
    ↓
Consumer's "for await" receives the bytes
    ↓
User's code processes the data
```

#### Step 4: Cleanup

```swift
private func removeSysExContinuation(for deviceID: MIDIUniqueID) {
    // Clear the continuation when stream ends
    connections[deviceID]?.sysexContinuation = nil
    
    // Note: We don't call finish() here because:
    // - If we're here, the stream already ended
    // - Calling finish() on a finished stream does nothing
    // - But setting to nil prevents us from trying to yield to a dead stream
}
```

---

## Complete Examples

### Example 1: Simple Counter Stream

```swift
// Create a stream that counts to 10
func counterStream() -> AsyncStream<Int> {
    AsyncStream { continuation in
        // Spawn a task to do the counting
        Task {
            for i in 1...10 {
                continuation.yield(i)
                try? await Task.sleep(for: .seconds(1))
            }
            continuation.finish()
        }
    }
}

// Use it
Task {
    for await number in counterStream() {
        print(number)  // Prints 1, 2, 3, ..., 10 (one per second)
    }
    print("Done!")
}
```

**Timeline:**

```
Time: 0s    1s    2s    3s    4s    5s    ...
      │     │     │     │     │     │
      1     2     3     4     5     6     ...
```

### Example 2: Event Publisher

```swift
class EventPublisher {
    private var continuation: AsyncStream<String>.Continuation?
    
    lazy var eventStream: AsyncStream<String> = {
        AsyncStream { continuation in
            self.continuation = continuation
            
            continuation.onTermination = { @Sendable _ in
                self.continuation = nil
            }
        }
    }()
    
    func publish(_ event: String) {
        continuation?.yield(event)
    }
    
    func close() {
        continuation?.finish()
        continuation = nil
    }
}

// Usage
let publisher = EventPublisher()

Task {
    for await event in publisher.eventStream {
        print("Received: \(event)")
    }
}

publisher.publish("Hello")    // Prints: Received: Hello
publisher.publish("World")    // Prints: Received: World
publisher.close()             // Stream ends, for loop exits
```

### Example 3: Multiple Consumers

```swift
// ⚠️ IMPORTANT: Each stream can only have ONE consumer!

let stream = AsyncStream<Int> { continuation in
    continuation.yield(1)
    continuation.yield(2)
    continuation.finish()
}

// ✅ This works
Task {
    for await value in stream {
        print("Consumer 1: \(value)")
    }
}

// ❌ This will NOT work - stream is already consumed!
Task {
    for await value in stream {
        print("Consumer 2: \(value)")  // Never prints!
    }
}

// ✅ Solution: Create multiple streams
func createStream() -> AsyncStream<Int> {
    AsyncStream { continuation in
        continuation.yield(1)
        continuation.yield(2)
        continuation.finish()
    }
}

Task {
    for await value in createStream() {
        print("Consumer 1: \(value)")
    }
}

Task {
    for await value in createStream() {
        print("Consumer 2: \(value)")
    }
}
```

---

## Common Patterns

### Pattern 1: Buffering Strategy

```swift
// Default: Buffers unlimited messages (can cause memory issues!)
AsyncStream<Int> { continuation in
    for i in 1...1000000 {
        continuation.yield(i)  // All buffered in memory!
    }
}

// Better: Limit buffer size
AsyncStream<Int>(bufferingPolicy: .bufferingNewest(10)) { continuation in
    for i in 1...1000000 {
        continuation.yield(i)  // Only keeps newest 10
    }
}
```

**Buffer Policies:**

- `.unbounded` - Store all values (default, dangerous!)
- `.bufferingOldest(n)` - Keep first n values, drop new ones
- `.bufferingNewest(n)` - Keep last n values, drop old ones

### Pattern 2: Multiple Stream Types

```swift
actor DataManager {
    // Different stream types for different data
    private var intContinuation: AsyncStream<Int>.Continuation?
    private var stringContinuation: AsyncStream<String>.Continuation?
    
    func intStream() -> AsyncStream<Int> {
        AsyncStream { continuation in
            self.intContinuation = continuation
        }
    }
    
    func stringStream() -> AsyncStream<String> {
        AsyncStream { continuation in
            self.stringContinuation = continuation
        }
    }
    
    func sendInt(_ value: Int) {
        intContinuation?.yield(value)
    }
    
    func sendString(_ value: String) {
        stringContinuation?.yield(value)
    }
}
```

### Pattern 3: Filtering and Transformation

```swift
// Create a stream
let rawStream = AsyncStream<Int> { continuation in
    for i in 1...10 {
        continuation.yield(i)
    }
    continuation.finish()
}

// Filter even numbers
Task {
    for await value in rawStream where value % 2 == 0 {
        print(value)  // Prints: 2, 4, 6, 8, 10
    }
}

// Or use compactMap
extension AsyncStream {
    func compactMap<T>(_ transform: (Element) -> T?) -> AsyncStream<T> {
        AsyncStream<T> { continuation in
            Task {
                for await element in self {
                    if let transformed = transform(element) {
                        continuation.yield(transformed)
                    }
                }
                continuation.finish()
            }
        }
    }
}
```

### Pattern 4: Timeout

```swift
// Stream with timeout
extension AsyncStream {
    func timeout(after duration: Duration) -> AsyncStream<Element> {
        AsyncStream { continuation in
            let timeoutTask = Task {
                try? await Task.sleep(for: duration)
                continuation.finish()
            }
            
            Task {
                for await element in self {
                    continuation.yield(element)
                }
                timeoutTask.cancel()
                continuation.finish()
            }
        }
    }
}

// Usage
for await value in stream.timeout(after: .seconds(5)) {
    print(value)  // Stops after 5 seconds even if stream continues
}
```

---

## MIDI Manager Complete Example

### The Full Picture

```swift
actor MIDIManager {
    // MARK: - Storage
    
    private struct DeviceConnection {
        let source: MIDIDevice
        let destination: MIDIDevice
        var sysexContinuation: AsyncStream<[UInt8]>.Continuation?
    }
    
    private var connections: [MIDIUniqueID: DeviceConnection] = [:]
    private var sysexBuffer: [UInt8] = []  // For multi-packet SysEx
    
    // MARK: - Stream Creation
    
    func sysexStream(from source: MIDIDevice) -> AsyncStream<[UInt8]> {
        AsyncStream(bufferingPolicy: .bufferingNewest(10)) { continuation in
            // 1. Store the continuation
            guard var connection = connections[source.id] else {
                continuation.finish()
                return
            }
            
            connection.sysexContinuation = continuation
            connections[source.id] = connection
            
            // 2. Set up cleanup
            continuation.onTermination = { @Sendable _ in
                Task {
                    await MIDIManager.shared.removeSysExContinuation(for: source.id)
                }
            }
        }
    }
    
    // MARK: - Data Reception
    
    private func handleIncomingEvents(_ eventList: UnsafePointer<MIDIEventList>) {
        // Process UMP packets
        let packets = extractPackets(from: eventList)
        
        for packet in packets {
            if packet.isSysEx {
                processSysExPacket(packet)
            }
        }
    }
    
    private func processSysExPacket(_ packet: UMPPacket) {
        switch packet.status {
        case .start:
            sysexBuffer = [0xF0] + packet.data
            
        case .continue:
            sysexBuffer += packet.data
            
        case .end:
            sysexBuffer += packet.data + [0xF7]
            let completeSysEx = sysexBuffer
            sysexBuffer = []
            
            // YIELD to all active streams
            notifySysEx(completeSysEx)
            
        case .complete:
            let completeSysEx = [0xF0] + packet.data + [0xF7]
            notifySysEx(completeSysEx)
        }
    }
    
    private func notifySysEx(_ data: [UInt8]) {
        for (_, connection) in connections {
            // This is where the consumer receives data!
            connection.sysexContinuation?.yield(data)
        }
    }
    
    // MARK: - Cleanup
    
    private func removeSysExContinuation(for deviceID: MIDIUniqueID) {
        connections[deviceID]?.sysexContinuation = nil
    }
}

// MARK: - Consumer Usage

Task {
    let midi = MIDIManager.shared
    
    // Get the stream
    let stream = await midi.sysexStream(from: waldorf)
    
    // Consume the stream
    for await sysexData in stream {
        print("Received \(sysexData.count) bytes")
        
        // Process the data
        let patch = try? Waldorf4PolePatch(sysEx: sysexData)
        
        // Update UI
        await MainActor.run {
            updateUI(with: patch)
        }
    }
    
    print("Stream ended")
}
```

---

## Debugging and Troubleshooting

### Common Issues

#### Issue 1: Stream Never Receives Data

```swift
// ❌ Problem: Continuation not stored
func sysexStream() -> AsyncStream<[UInt8]> {
    AsyncStream { continuation in
        // Continuation only exists here!
        // As soon as this closure returns, continuation is gone
    }
}

func sendData() {
    // ❌ How do we access continuation here?
}

// ✅ Solution: Store it!
private var continuation: AsyncStream<[UInt8]>.Continuation?

func sysexStream() -> AsyncStream<[UInt8]> {
    AsyncStream { continuation in
        self.continuation = continuation  // Save it!
    }
}

func sendData(_ data: [UInt8]) {
    continuation?.yield(data)  // Now we can use it!
}
```

#### Issue 2: Memory Leak

```swift
// ❌ Problem: Retain cycle
class Manager {
    var continuation: AsyncStream<Int>.Continuation?
    
    func createStream() -> AsyncStream<Int> {
        AsyncStream { continuation in
            self.continuation = continuation
            
            // ❌ This creates a retain cycle!
            continuation.onTermination = { _ in
                self.continuation = nil  // self is captured strongly
            }
        }
    }
}

// ✅ Solution: Use @Sendable and Task
func createStream() -> AsyncStream<Int> {
    AsyncStream { continuation in
        self.continuation = continuation
        
        // ✅ Break the cycle with @Sendable
        continuation.onTermination = { @Sendable _ in
            Task {
                await self.removeContinuation()
            }
        }
    }
}
```

#### Issue 3: Yielding After Termination

```swift
// ❌ Problem: Yielding to finished stream
var continuation: AsyncStream<Int>.Continuation?

// Consumer breaks loop
for await value in stream {
    if value == 5 {
        break  // Stream terminates here
    }
}

// ❌ This silently does nothing!
continuation?.yield(10)

// ✅ Solution: Check if continuation is still valid
continuation.onTermination = { @Sendable _ in
    Task {
        await self.invalidateContinuation()
    }
}

func invalidateContinuation() {
    continuation = nil  // Clear it
}
```

#### Issue 4: Missing Data

```swift
// ❌ Problem: Buffer overflow
let stream = AsyncStream<Int> { continuation in  // Default: unlimited buffer
    for i in 1...1000000 {
        continuation.yield(i)  // If consumer is slow, this buffers EVERYTHING
    }
}

// ✅ Solution: Set buffering policy
let stream = AsyncStream<Int>(bufferingPolicy: .bufferingNewest(100)) { continuation in
    for i in 1...1000000 {
        continuation.yield(i)  // Only keeps newest 100 values
    }
}
```

### Debugging Techniques

```swift
// Add logging
AsyncStream<[UInt8]> { continuation in
    print("✅ Stream created")
    
    self.continuation = continuation
    
    continuation.onTermination = { @Sendable reason in
        print("❌ Stream terminated: \(reason)")
    }
}

// Log yields
func notifySysEx(_ data: [UInt8]) {
    print("📤 Yielding \(data.count) bytes to \(connections.count) connections")
    
    for (deviceID, connection) in connections {
        if let cont = connection.sysexContinuation {
            print("  → Yielding to device \(deviceID)")
            cont.yield(data)
        } else {
            print("  ⚠️  No continuation for device \(deviceID)")
        }
    }
}

// Log consumption
Task {
    print("👂 Starting to listen")
    
    for await data in stream {
        print("📥 Received \(data.count) bytes")
    }
    
    print("🔇 Stopped listening")
}
```

---

## Summary

### Key Concepts

1. **AsyncStream** = A sequence of values over time
2. **Continuation** = Your control for sending values
3. **yield()** = Send a value to consumers
4. **finish()** = Close the stream
5. **onTermination** = Get notified when stream ends

### Best Practices

✅ Store continuations in a safe place (actor/class property)  
✅ Set buffering policy to prevent memory issues  
✅ Use `@Sendable` in onTermination callbacks  
✅ Clear continuations when streams end  
✅ Add logging during development  
✅ One stream = one consumer  

### Common Pitfalls

❌ Not storing the continuation  
❌ Forgetting to handle termination  
❌ Creating retain cycles  
❌ Using unlimited buffers  
❌ Trying to yield after finish()  
❌ Sharing one stream between multiple consumers  

---

## Further Reading

- Apple's AsyncStream Documentation
- Swift Concurrency: Behind the Scenes (WWDC)
- Structured Concurrency in Swift
- Actor Isolation and Sendable

## Practice Exercises

1. Create a timer stream that yields every second
2. Build a temperature sensor simulator with AsyncStream
3. Implement a chat message stream with filtering
4. Create a download progress stream
5. Build a MIDI note recorder using multiple streams

---

**This guide is complete and can be used as a classroom reference!**
