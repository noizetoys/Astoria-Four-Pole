// AsyncStream Mastery: From Basics to Production MIDI
// A Complete Teaching Guide with Progressive Examples
//
// PERFECT FOR:
// ✅ Teaching Swift Concurrency
// ✅ Understanding AsyncStream mechanics
// ✅ Building real-world MIDI applications
// ✅ Classroom instruction (9 hours of material)
//
// STRUCTURE:
// Level 1: Basics (Simple examples, foundational concepts)
// Level 2: Intermediate (Event publishers, continuations)
// Level 3: Advanced (Buffer policies, memory management)
// Level 4: Production (Complete MIDI 1.0 implementation)

import Foundation
import CoreMIDI

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - LEVEL 1: BASICS
// ═══════════════════════════════════════════════════════════════════════════

/*
 ┌─────────────────────────────────────────────────────────────────┐
 │                    WHAT IS ASYNCSTREAM?                         │
 └─────────────────────────────────────────────────────────────────┘
 
 AsyncStream is a way to turn callback-based APIs into async/await sequences.
 
 Think of it as a pipe:
 
    ┌────────────┐         ┌──────────────┐         ┌──────────┐
    │  Producer  │ ─yield→ │  AsyncStream │ ─await→ │ Consumer │
    │ (push data)│         │   (buffer)   │         │ (pulls)  │
    └────────────┘         └──────────────┘         └──────────┘
 
 KEY CONCEPTS:
 1. Producer uses yield() to add values
 2. Consumer uses for await to receive values
 3. Stream can buffer values if consumer is slow
 4. Stream ends when continuation.finish() is called
 */

// ─────────────────────────────────────────────────────────────────
// Example 1.1: The Simplest AsyncStream - Counter
// ─────────────────────────────────────────────────────────────────

func createSimpleCounter() -> AsyncStream<Int> {
    AsyncStream { continuation in
        // This code runs ONCE when the stream is created
        print("🎬 Stream started!")
        
        // Yield some values
        continuation.yield(1)
        continuation.yield(2)
        continuation.yield(3)
        
        // End the stream
        continuation.finish()
        print("🏁 Stream finished!")
    }
}

// Usage:
func exampleSimpleCounter() async {
    for await number in createSimpleCounter() {
        print("Received: \(number)")
    }
    // Output:
    // 🎬 Stream started!
    // Received: 1
    // Received: 2
    // Received: 3
    // 🏁 Stream finished!
}

/*
 💡 AHA MOMENT #1: Understanding yield()
 
 yield() does NOT block! It adds the value to a queue and returns immediately.
 The consumer receives it when ready.
 
 Timeline:
 
 Producer Side:                Consumer Side:
 ─────────────                ─────────────
 yield(1) ───────────────────→ for await...
 yield(2) ───────────────────→ print(1)
 yield(3) ───────────────────→ print(2)
 finish() ───────────────────→ print(3)
                               loop ends
 */

// ─────────────────────────────────────────────────────────────────
// Example 1.2: Timer Stream (with delay)
// ─────────────────────────────────────────────────────────────────

func createTimerStream(interval: TimeInterval, count: Int) -> AsyncStream<Date> {
    AsyncStream { continuation in
        Task {
            for i in 0..<count {
                // Yield current date
                continuation.yield(Date())
                
                // Wait before next yield
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
            continuation.finish()
        }
    }
}

// Usage:
func exampleTimer() async {
    print("⏱️ Timer starting...")
    for await timestamp in createTimerStream(interval: 1.0, count: 3) {
        print("Tick at \(timestamp)")
    }
    print("⏱️ Timer done!")
}

/*
 ❓ DISCUSSION QUESTION 1:
 Why can't we just use callbacks for this?
 
 ANSWER:
 ✅ AsyncStream provides backpressure - consumer controls pace
 ✅ Cancellation is automatic when task is cancelled
 ✅ Sequential processing without callback hell
 ✅ Integrates with async/await syntax naturally
 */

// ─────────────────────────────────────────────────────────────────
// Example 1.3: ❌ Common Mistake - Trying to yield outside closure
// ─────────────────────────────────────────────────────────────────

// ❌ WRONG: Continuation only exists in the closure!
func badCounterExample() -> AsyncStream<Int> {
    AsyncStream { continuation in
        continuation.yield(1)
        // Continuation will be destroyed when this closure ends
    }
    // ⚠️ Can't access continuation here!
}

// ✅ CORRECT: Must yield inside the closure OR store continuation
func goodCounterExample() -> AsyncStream<Int> {
    AsyncStream { continuation in
        // All yields must happen here or...
        continuation.yield(1)
        continuation.finish()
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - LEVEL 2: INTERMEDIATE - Storing Continuations
// ═══════════════════════════════════════════════════════════════════════════

/*
 ┌─────────────────────────────────────────────────────────────────┐
 │              WHY STORE CONTINUATIONS?                           │
 └─────────────────────────────────────────────────────────────────┘
 
 The continuation only exists inside the AsyncStream closure.
 To yield values from OUTSIDE (like from callbacks), you MUST store it!
 
    ┌──────────────────────────────────────────────────────────────┐
    │ AsyncStream { continuation in                                │
    │     self.storedContinuation = continuation  ← STORE IT       │
    │ }                                                             │
    └──────────────────────────────────────────────────────────────┘
                            ↓
    ┌──────────────────────────────────────────────────────────────┐
    │ func onMIDIData(_ data: [UInt8]) {                           │
    │     storedContinuation?.yield(data)  ← USE IT LATER          │
    │ }                                                             │
    └──────────────────────────────────────────────────────────────┘
 */

// 💡 AHA MOMENT #2: Why store continuations?
/*
 The continuation closure runs ONCE when stream is created.
 MIDI data arrives LATER from CoreMIDI callbacks.
 Solution: Store the continuation so we can yield later!
 
 Flow:
 1. Stream created → continuation closure runs
 2. Store continuation in a property
 3. MIDI callback fires → use stored continuation to yield
 */

// ─────────────────────────────────────────────────────────────────
// Example 2.1: Event Publisher Pattern
// ─────────────────────────────────────────────────────────────────

actor SimpleEventPublisher {
    // Store continuation so we can yield from anywhere
    private var continuation: AsyncStream<String>.Continuation?
    
    // Create stream and store its continuation
    func eventStream() -> AsyncStream<String> {
        AsyncStream { continuation in
            self.continuation = continuation
            
            // Handle cleanup when consumer stops listening
            continuation.onTermination = { @Sendable _ in
                Task {
                    await self.clearContinuation()
                }
            }
        }
    }
    
    // Publish event (called from anywhere, anytime)
    func publish(_ event: String) {
        continuation?.yield(event)
    }
    
    // Stop publishing
    func stopPublishing() {
        continuation?.finish()
        continuation = nil
    }
    
    private func clearContinuation() {
        continuation = nil
    }
}

// Usage:
func exampleEventPublisher() async {
    let publisher = SimpleEventPublisher()
    
    // Start listening
    Task {
        for await event in await publisher.eventStream() {
            print("📢 Event: \(event)")
        }
        print("📢 Event stream ended")
    }
    
    // Publish events from main flow
    await publisher.publish("Hello")
    try? await Task.sleep(nanoseconds: 100_000_000)
    await publisher.publish("World")
    try? await Task.sleep(nanoseconds: 100_000_000)
    await publisher.stopPublishing()
}

// ─────────────────────────────────────────────────────────────────
// Example 2.2: Multiple Stream Types (like MIDI Manager)
// ─────────────────────────────────────────────────────────────────

actor MultiStreamPublisher {
    // Store different continuations for different data types
    private var sysexContinuation: AsyncStream<[UInt8]>.Continuation?
    private var ccContinuation: AsyncStream<(UInt8, UInt8, UInt8)>.Continuation?
    private var noteContinuation: AsyncStream<(Bool, UInt8, UInt8)>.Continuation?
    
    // SysEx stream
    func sysexStream() -> AsyncStream<[UInt8]> {
        AsyncStream { continuation in
            self.sysexContinuation = continuation
            continuation.onTermination = { @Sendable _ in
                Task { await self.clearSysExContinuation() }
            }
        }
    }
    
    // CC stream
    func ccStream() -> AsyncStream<(channel: UInt8, cc: UInt8, value: UInt8)> {
        AsyncStream { continuation in
            self.ccContinuation = continuation
            continuation.onTermination = { @Sendable _ in
                Task { await self.clearCCContinuation() }
            }
        }
    }
    
    // Note stream
    func noteStream() -> AsyncStream<(isOn: Bool, note: UInt8, velocity: UInt8)> {
        AsyncStream { continuation in
            self.noteContinuation = continuation
            continuation.onTermination = { @Sendable _ in
                Task { await self.clearNoteContinuation() }
            }
        }
    }
    
    // Called from MIDI processing
    func handleSysEx(_ data: [UInt8]) {
        sysexContinuation?.yield(data)
    }
    
    func handleCC(channel: UInt8, cc: UInt8, value: UInt8) {
        ccContinuation?.yield((channel, cc, value))
    }
    
    func handleNote(isOn: Bool, note: UInt8, velocity: UInt8) {
        noteContinuation?.yield((isOn, note, velocity))
    }
    
    // Cleanup
    private func clearSysExContinuation() { sysexContinuation = nil }
    private func clearCCContinuation() { ccContinuation = nil }
    private func clearNoteContinuation() { noteContinuation = nil }
}

// Usage:
func exampleMultiStream() async {
    let publisher = MultiStreamPublisher()
    
    // Listen to SysEx
    Task {
        for await data in await publisher.sysexStream() {
            print("🎹 SysEx: \(data.count) bytes")
        }
    }
    
    // Listen to CCs
    Task {
        for await (channel, cc, value) in await publisher.ccStream() {
            print("🎛️ CC\(cc) = \(value) on ch\(channel)")
        }
    }
    
    // Simulate MIDI data
    await publisher.handleSysEx([0xF0, 0x3E, 0x04, 0xF7])
    await publisher.handleCC(channel: 0, cc: 16, value: 64)
}

/*
 ❓ DISCUSSION QUESTION 2:
 When should we use multiple streams vs one stream?
 
 ANSWER:
 ✅ Multiple streams = Different consumers for different data types
 ✅ Single stream = All data goes through same processing pipeline
 
 MIDI Example:
 - SysEx needs special decoding → separate stream
 - CCs update UI controls → separate stream
 - Notes trigger sound → separate stream
 
 Each stream can be consumed independently!
 */

// ─────────────────────────────────────────────────────────────────
// Example 2.3: ❌ Common Mistakes with Stored Continuations
// ─────────────────────────────────────────────────────────────────

// ❌ MISTAKE 1: Not clearing continuation on termination
actor BadPublisher1 {
    private var continuation: AsyncStream<Int>.Continuation?
    
    func stream() -> AsyncStream<Int> {
        AsyncStream { continuation in
            self.continuation = continuation
            // ⚠️ Missing onTermination handler!
        }
    }
    
    func publish(_ value: Int) {
        // ⚠️ This will keep yielding even after consumer stops!
        continuation?.yield(value)
    }
}

// ✅ CORRECT: Always clear on termination
actor GoodPublisher1 {
    private var continuation: AsyncStream<Int>.Continuation?
    
    func stream() -> AsyncStream<Int> {
        AsyncStream { continuation in
            self.continuation = continuation
            continuation.onTermination = { @Sendable _ in
                Task {
                    await self.clearContinuation()
                }
            }
        }
    }
    
    func publish(_ value: Int) {
        continuation?.yield(value)
    }
    
    private func clearContinuation() {
        continuation = nil
    }
}

// ❌ MISTAKE 2: Yielding from wrong actor context
actor BadPublisher2 {
    private var continuation: AsyncStream<Int>.Continuation?
    
    func stream() -> AsyncStream<Int> {
        AsyncStream { continuation in
            self.continuation = continuation
        }
    }
    
    // ⚠️ This is not actor-isolated!
    nonisolated func publish(_ value: Int) {
        // ⚠️ Race condition! Accessing actor property from outside!
        continuation?.yield(value)  // CRASH RISK
    }
}

// ✅ CORRECT: Keep everything actor-isolated
actor GoodPublisher2 {
    private var continuation: AsyncStream<Int>.Continuation?
    
    func stream() -> AsyncStream<Int> {
        AsyncStream { continuation in
            self.continuation = continuation
        }
    }
    
    // ✅ Actor-isolated, thread-safe
    func publish(_ value: Int) {
        continuation?.yield(value)
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - LEVEL 3: ADVANCED - Buffer Policies & Memory
// ═══════════════════════════════════════════════════════════════════════════

/*
 ┌─────────────────────────────────────────────────────────────────┐
 │              WHAT IF CONSUMER IS SLOW?                          │
 └─────────────────────────────────────────────────────────────────┘
 
 When producer yields faster than consumer consumes:
 
    Producer: yield(1), yield(2), yield(3), yield(4)...
                 ↓        ↓        ↓        ↓
              ┌─────────────────────────────┐
              │    Buffer (what happens?)   │
              └─────────────────────────────┘
                             ↓
    Consumer:         await, await, await...
 
 Buffer Policies:
 1. .unbounded - Keep all values (⚠️ memory risk!)
 2. .bufferingOldest(N) - Keep newest N, drop oldest
 3. .bufferingNewest(N) - Keep oldest N, drop newest
 */

// 💡 AHA MOMENT #3: Backpressure handling
/*
 AsyncStream provides automatic backpressure:
 - Buffer fills up → yield() blocks until space available
 - Consumer is slow → producer naturally slows down
 - Consumer is fast → buffer stays empty
 
 This prevents memory exhaustion from fast producers!
 */

// ─────────────────────────────────────────────────────────────────
// Example 3.1: Buffer Policy Comparison
// ─────────────────────────────────────────────────────────────────

// Policy 1: Unbounded (dangerous for MIDI!)
func unboundedStream() -> AsyncStream<Int> {
    AsyncStream(bufferingPolicy: .unbounded) { continuation in
        // ⚠️ If consumer is slow, this could fill memory!
        for i in 0..<1_000_000 {
            continuation.yield(i)
        }
        continuation.finish()
    }
}

// Policy 2: Buffer oldest (good for real-time data)
func bufferedOldestStream() -> AsyncStream<Int> {
    AsyncStream(bufferingPolicy: .bufferingOldest(10)) { continuation in
        // ✅ Keeps newest 10, drops oldest when full
        for i in 0..<100 {
            continuation.yield(i)
        }
        continuation.finish()
    }
}

// Policy 3: Buffer newest (good for cumulative data)
func bufferedNewestStream() -> AsyncStream<Int> {
    AsyncStream(bufferingPolicy: .bufferingNewest(10)) { continuation in
        // ✅ Keeps oldest 10, drops newest when full
        for i in 0..<100 {
            continuation.yield(i)
        }
        continuation.finish()
    }
}

/*
 ❓ DISCUSSION QUESTION 3:
 What buffer policy should MIDI use?
 
 ANSWER:
 ✅ SysEx: .bufferingOldest(5) - Latest patch data matters most
 ✅ CCs: .bufferingNewest(20) - All controller moves important
 ✅ Notes: .bufferingNewest(50) - Can't drop note-offs!
 
 Real-time MIDI needs bounded buffers to prevent memory issues!
 */

// ─────────────────────────────────────────────────────────────────
// Example 3.2: Memory Management Patterns
// ─────────────────────────────────────────────────────────────────

actor ProperMemoryManagement {
    private var continuation: AsyncStream<Data>.Continuation?
    private var isActive = false
    
    func dataStream() -> AsyncStream<Data> {
        AsyncStream(bufferingPolicy: .bufferingOldest(10)) { continuation in
            self.continuation = continuation
            self.isActive = true
            
            continuation.onTermination = { @Sendable [weak self] _ in
                Task {
                    await self?.cleanup()
                }
            }
        }
    }
    
    func receiveData(_ data: Data) {
        guard isActive else { return }
        continuation?.yield(data)
    }
    
    func stop() {
        isActive = false
        continuation?.finish()
        continuation = nil
    }
    
    private func cleanup() {
        isActive = false
        continuation = nil
        print("🧹 Cleaned up continuation")
    }
}

// ─────────────────────────────────────────────────────────────────
// Example 3.3: ❌ Memory Leak Patterns
// ─────────────────────────────────────────────────────────────────

// ❌ LEAK 1: Never finishing the stream
actor LeakyPublisher1 {
    private var continuation: AsyncStream<Int>.Continuation?
    
    func stream() -> AsyncStream<Int> {
        AsyncStream { continuation in
            self.continuation = continuation
            // ⚠️ Stream never finishes!
            // Consumer keeps waiting forever
        }
    }
}

// ✅ FIX: Always provide a way to finish
actor NonLeakyPublisher1 {
    private var continuation: AsyncStream<Int>.Continuation?
    
    func stream() -> AsyncStream<Int> {
        AsyncStream { continuation in
            self.continuation = continuation
        }
    }
    
    func stop() {
        continuation?.finish()
        continuation = nil
    }
}

// ❌ LEAK 2: Strong reference cycles
class LeakyPublisher2 {
    private var continuation: AsyncStream<Int>.Continuation?
    
    func stream() -> AsyncStream<Int> {
        AsyncStream { continuation in
            // ⚠️ Strong reference to self!
            continuation.onTermination = { _ in
                self.continuation = nil  // Captures self strongly
            }
            self.continuation = continuation
        }
    }
}

// ✅ FIX: Use weak self
class NonLeakyPublisher2 {
    private var continuation: AsyncStream<Int>.Continuation?
    
    func stream() -> AsyncStream<Int> {
        AsyncStream { continuation in
            // ✅ Weak reference breaks cycle
            continuation.onTermination = { [weak self] _ in
                self?.continuation = nil
            }
            self.continuation = continuation
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - LEVEL 4: PRODUCTION - Complete MIDI 1.0 Implementation
// ═══════════════════════════════════════════════════════════════════════════

/*
 ┌─────────────────────────────────────────────────────────────────┐
 │           COMPLETE MIDI MANAGER WITH ASYNCSTREAM                │
 └─────────────────────────────────────────────────────────────────┘
 
 This is the REAL production implementation showing:
 ✅ Multiple stream types (SysEx, CC, Notes)
 ✅ Proper buffer policies
 ✅ Actor isolation
 ✅ Memory management
 ✅ Error handling
 ✅ MIDI 1.0 packet parsing
 
 Architecture:
 
    CoreMIDI → MIDIPacketList → Parse Bytes → Yield to Streams
                                     ↓
                        ┌────────────┼────────────┐
                        ↓            ↓            ↓
                   SysEx Stream  CC Stream  Note Stream
                        ↓            ↓            ↓
                   UI Updates   Controllers  Sound Engine
 */

// 💡 AHA MOMENT #4: One stream, one consumer
/*
 CRITICAL: Each AsyncStream can only be consumed ONCE!
 
 ❌ This won't work:
 let stream = manager.sysexStream()
 Task { for await data in stream { ... } }  // Consumer 1
 Task { for await data in stream { ... } }  // Consumer 2 gets nothing!
 
 ✅ Solution: Create multiple streams if you need multiple consumers
 Task { for await data in manager.sysexStream() { ... } }  // New stream
 Task { for await data in manager.sysexStream() { ... } }  // New stream
 */

// ─────────────────────────────────────────────────────────────────
// Step 1: Connection State Management
// ─────────────────────────────────────────────────────────────────

private struct MIDIConnection {
    let sourceDevice: MIDIDevice  // Where we receive from
    let destDevice: MIDIDevice    // Where we send to
    
    // Store one continuation per device for each stream type
    var sysexContinuation: AsyncStream<[UInt8]>.Continuation?
    var ccContinuation: AsyncStream<(UInt8, UInt8, UInt8)>.Continuation?
    var noteContinuation: AsyncStream<(Bool, UInt8, UInt8, UInt8)>.Continuation?
}

// ─────────────────────────────────────────────────────────────────
// Step 2: The Complete MIDI Manager Actor
// ─────────────────────────────────────────────────────────────────

actor CompleteMIDIManager {
    
    // MIDI subsystem
    private var client: MIDIClientRef = 0
    private var inputPort: MIDIPortRef = 0
    private var outputPort: MIDIPortRef = 0
    
    // Track active connections
    private var connections: [MIDIUniqueID: MIDIConnection] = [:]
    
    // SysEx assembly buffer
    private var sysexBuffer: [UInt8] = []
    
    // MARK: - Initialization
    
    init() {
        setupMIDI()
    }
    
    private func setupMIDI() {
        var client: MIDIClientRef = 0
        var status = MIDIClientCreateWithBlock("TeachingMIDI" as CFString, &client) { _ in }
        guard status == noErr else { return }
        self.client = client
        
        // Create MIDI 1.0 input port
        var inPort: MIDIPortRef = 0
        status = MIDIInputPortCreateWithBlock(
            client,
            "Input" as CFString,
            &inPort
        ) { [weak self] packetList, _ in
            // ⚠️ This callback happens on MIDI thread!
            // Must marshal to actor for safety
            Task {
                await self?.handleIncomingPackets(packetList)
            }
        }
        guard status == noErr else { return }
        self.inputPort = inPort
        
        var outPort: MIDIPortRef = 0
        status = MIDIOutputPortCreate(client, "Output" as CFString, &outPort)
        guard status == noErr else { return }
        self.outputPort = outPort
    }
    
    // MARK: - Step 3: Creating Streams
    
    /// Create SysEx stream for a device
    /// BUFFER POLICY: Keep newest 5 SysEx messages (discard old patches)
    func sysexStream(from device: MIDIDevice) -> AsyncStream<[UInt8]> {
        AsyncStream(bufferingPolicy: .bufferingOldest(5)) { continuation in
            // Store continuation for this device
            if var connection = connections[device.id] {
                connection.sysexContinuation = continuation
                connections[device.id] = connection
            }
            
            // Handle cleanup when consumer stops
            continuation.onTermination = { @Sendable [weak self] _ in
                Task {
                    await self?.removeSysExContinuation(for: device.id)
                }
            }
        }
    }
    
    /// Create CC stream for a device
    /// BUFFER POLICY: Keep newest 20 CC messages (all moves important)
    func ccStream(from device: MIDIDevice) -> AsyncStream<(channel: UInt8, cc: UInt8, value: UInt8)> {
        AsyncStream(bufferingPolicy: .bufferingNewest(20)) { continuation in
            if var connection = connections[device.id] {
                connection.ccContinuation = continuation
                connections[device.id] = connection
            }
            
            continuation.onTermination = { @Sendable [weak self] _ in
                Task {
                    await self?.removeCCContinuation(for: device.id)
                }
            }
        }
    }
    
    /// Create note stream for a device
    /// BUFFER POLICY: Keep newest 50 note events (can't drop note-offs!)
    func noteStream(from device: MIDIDevice) -> AsyncStream<(isNoteOn: Bool, channel: UInt8, note: UInt8, velocity: UInt8)> {
        AsyncStream(bufferingPolicy: .bufferingNewest(50)) { continuation in
            if var connection = connections[device.id] {
                connection.noteContinuation = continuation
                connections[device.id] = connection
            }
            
            continuation.onTermination = { @Sendable [weak self] _ in
                Task {
                    await self?.removeNoteContinuation(for: device.id)
                }
            }
        }
    }
    
    // MARK: - Step 4: Receiving MIDI Data (Yielding to Streams)
    
    /// Called from CoreMIDI callback (MIDI thread)
    private func handleIncomingPackets(_ packetList: UnsafePointer<MIDIPacketList>) {
        var packet = packetList.pointee.packet
        
        for _ in 0..<packetList.pointee.numPackets {
            // Extract bytes from packet
            let bytes = withUnsafeBytes(of: &packet.data) { pointer in
                Array(pointer.prefix(Int(packet.length)))
            }
            
            // Parse and yield to appropriate streams
            parseAndYield(bytes)
            
            // Next packet
            packet = MIDIPacketNext(&packet).pointee
        }
    }
    
    /// Parse MIDI 1.0 bytes and yield to streams
    private func parseAndYield(_ bytes: [UInt8]) {
        var i = 0
        
        while i < bytes.count {
            let byte = bytes[i]
            
            // ──────────────────────────────────────────
            // SysEx Handling
            // ──────────────────────────────────────────
            if byte == 0xF0 {
                // Start of SysEx
                sysexBuffer = [0xF0]
                i += 1
                
                // Collect until 0xF7
                while i < bytes.count {
                    let dataByte = bytes[i]
                    sysexBuffer.append(dataByte)
                    i += 1
                    
                    if dataByte == 0xF7 {
                        // Complete! Yield to SysEx stream
                        yieldSysEx(sysexBuffer)
                        sysexBuffer = []
                        break
                    }
                }
                continue
            }
            
            // Continue SysEx from previous packet
            if !sysexBuffer.isEmpty {
                sysexBuffer.append(byte)
                i += 1
                
                if byte == 0xF7 {
                    yieldSysEx(sysexBuffer)
                    sysexBuffer = []
                }
                continue
            }
            
            // ──────────────────────────────────────────
            // Channel Voice Messages
            // ──────────────────────────────────────────
            if byte & 0x80 != 0 {
                let messageType = byte & 0xF0
                let channel = byte & 0x0F
                
                switch messageType {
                case 0x80:  // Note Off
                    if i + 2 < bytes.count {
                        let note = bytes[i + 1]
                        let velocity = bytes[i + 2]
                        yieldNote(isOn: false, channel: channel, note: note, velocity: velocity)
                        i += 3
                    } else {
                        i += 1
                    }
                    
                case 0x90:  // Note On
                    if i + 2 < bytes.count {
                        let note = bytes[i + 1]
                        let velocity = bytes[i + 2]
                        yieldNote(isOn: velocity > 0, channel: channel, note: note, velocity: velocity)
                        i += 3
                    } else {
                        i += 1
                    }
                    
                case 0xB0:  // Control Change
                    if i + 2 < bytes.count {
                        let cc = bytes[i + 1]
                        let value = bytes[i + 2]
                        yieldCC(channel: channel, cc: cc, value: value)
                        i += 3
                    } else {
                        i += 1
                    }
                    
                default:
                    i += 1
                }
            } else {
                i += 1
            }
        }
    }
    
    // MARK: - Step 5: Yielding to Streams
    
    /// Yield SysEx to all connected devices' streams
    private func yieldSysEx(_ data: [UInt8]) {
        for (_, connection) in connections {
            connection.sysexContinuation?.yield(data)
        }
    }
    
    /// Yield CC to all connected devices' streams
    private func yieldCC(channel: UInt8, cc: UInt8, value: UInt8) {
        for (_, connection) in connections {
            connection.ccContinuation?.yield((channel, cc, value))
        }
    }
    
    /// Yield note to all connected devices' streams
    private func yieldNote(isOn: Bool, channel: UInt8, note: UInt8, velocity: UInt8) {
        for (_, connection) in connections {
            connection.noteContinuation?.yield((isOn, channel, note, velocity))
        }
    }
    
    // MARK: - Step 6: Cleanup (Memory Management)
    
    private func removeSysExContinuation(for deviceID: MIDIUniqueID) {
        connections[deviceID]?.sysexContinuation = nil
    }
    
    private func removeCCContinuation(for deviceID: MIDIUniqueID) {
        connections[deviceID]?.ccContinuation = nil
    }
    
    private func removeNoteContinuation(for deviceID: MIDIUniqueID) {
        connections[deviceID]?.noteContinuation = nil
    }
    
    // MARK: - Connection Management
    
    func connect(source: MIDIDevice, destination: MIDIDevice) {
        MIDIPortConnectSource(inputPort, source.endpoint, nil)
        
        let connection = MIDIConnection(
            sourceDevice: source,
            destDevice: destination,
            sysexContinuation: nil,
            ccContinuation: nil,
            noteContinuation: nil
        )
        
        connections[source.id] = connection
    }
    
    func disconnect(from device: MIDIDevice) {
        // Finish all streams for this device
        if let connection = connections[device.id] {
            connection.sysexContinuation?.finish()
            connection.ccContinuation?.finish()
            connection.noteContinuation?.finish()
        }
        
        MIDIPortDisconnectSource(inputPort, device.endpoint)
        connections.removeValue(forKey: device.id)
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - COMPLETE USAGE EXAMPLE
// ═══════════════════════════════════════════════════════════════════════════

func completeExample() async {
    let midi = CompleteMIDIManager()
    
    // Assuming we have a device...
    let device = MIDIDevice(
        endpoint: MIDIGetSource(0),
        type: .source
    )!
    
    // ──────────────────────────────────────────────────────────────
    // Listen to SysEx (for patch dumps)
    // ──────────────────────────────────────────────────────────────
    Task {
        for await sysexData in await midi.sysexStream(from: device) {
            print("🎹 Received SysEx: \(sysexData.count) bytes")
            
            // Decode patch data here
            // let patch = try? codec.decode(sysexData)
        }
    }
    
    // ──────────────────────────────────────────────────────────────
    // Listen to CCs (for real-time control)
    // ──────────────────────────────────────────────────────────────
    Task {
        for await (channel, cc, value) in await midi.ccStream(from: device) {
            print("🎛️ CC\(cc) = \(value) on channel \(channel)")
            
            // Update UI sliders here
            // await updateUI(cc: cc, value: value)
        }
    }
    
    // ──────────────────────────────────────────────────────────────
    // Listen to Notes (for visual keyboard)
    // ──────────────────────────────────────────────────────────────
    Task {
        for await (isOn, channel, note, velocity) in await midi.noteStream(from: device) {
            if isOn {
                print("🎹 Note On: \(note) velocity \(velocity)")
            } else {
                print("🎹 Note Off: \(note)")
            }
            
            // Update keyboard display
            // await keyboard.update(note: note, isOn: isOn)
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - DEBUGGING GUIDE
// ═══════════════════════════════════════════════════════════════════════════

/*
 ┌─────────────────────────────────────────────────────────────────┐
 │                    COMMON PROBLEMS & SOLUTIONS                  │
 └─────────────────────────────────────────────────────────────────┘
 
 ❌ PROBLEM 1: Stream never receives data
 ─────────────────────────────────────────────────────────────────
 
 Symptoms:
 - for await loop never prints anything
 - App seems "stuck"
 
 Checklist:
 □ Is continuation being stored correctly?
 □ Is yield() being called?
 □ Is yield happening on correct actor?
 □ Did consumer start listening BEFORE producer started?
 
 Fix:
 ✅ Add debug prints in yield() calls
 ✅ Verify continuation is not nil
 ✅ Check actor isolation
 
 
 ❌ PROBLEM 2: Memory leak
 ─────────────────────────────────────────────────────────────────
 
 Symptoms:
 - Memory usage grows over time
 - Streams never deallocate
 
 Checklist:
 □ Is continuation.finish() ever called?
 □ Is onTermination handler clearing continuation?
 □ Are there retain cycles (use weak self)?
 □ Is buffer policy unbounded?
 
 Fix:
 ✅ Always implement onTermination
 ✅ Use [weak self] in closures
 ✅ Call finish() when done
 ✅ Use bounded buffer policies
 
 
 ❌ PROBLEM 3: Missing data
 ─────────────────────────────────────────────────────────────────
 
 Symptoms:
 - Some values not received
 - Data seems skipped
 
 Checklist:
 □ Is buffer too small?
 □ Is consumer too slow?
 □ Wrong buffer policy?
 
 Fix:
 ✅ Increase buffer size
 ✅ Use .bufferingNewest for important data
 ✅ Process data faster in consumer
 
 
 ❌ PROBLEM 4: Yielding after termination
 ─────────────────────────────────────────────────────────────────
 
 Symptoms:
 - Warning: "Yielding to finished stream"
 - Mysterious nil continuation
 
 Checklist:
 □ Is continuation cleared on termination?
 □ Is there a race between finish() and yield()?
 □ Are you checking if continuation exists?
 
 Fix:
 ✅ Always use continuation?.yield() (optional chaining)
 ✅ Clear continuation in onTermination
 ✅ Add isActive flag if needed
 
 
 ❌ PROBLEM 5: Stream consumes only once
 ─────────────────────────────────────────────────────────────────
 
 Symptoms:
 - Second for await loop gets nothing
 - Only first consumer works
 
 Explanation:
 This is BY DESIGN! Each AsyncStream is single-use.
 
 Fix:
 ✅ Create new stream for each consumer
 ✅ Call manager.sysexStream() again
 ✅ Don't try to share streams
 */

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - BEST PRACTICES CHECKLIST
// ═══════════════════════════════════════════════════════════════════════════

/*
 ✅ AsyncStream Best Practices
 ─────────────────────────────────────────────────────────────────
 
 CREATION:
 ✅ Choose appropriate buffer policy
 ✅ Store continuation if yielding later
 ✅ Implement onTermination handler
 ✅ Use actor isolation for thread safety
 
 YIELDING:
 ✅ Use optional chaining: continuation?.yield()
 ✅ Yield from correct actor context
 ✅ Don't yield after finish()
 ✅ Handle backpressure gracefully
 
 CONSUMPTION:
 ✅ Create new stream for each consumer
 ✅ Handle cancellation properly
 ✅ Process values efficiently
 ✅ Don't block in for await loop
 
 CLEANUP:
 ✅ Call finish() when done
 ✅ Clear continuation in onTermination
 ✅ Use [weak self] to avoid cycles
 ✅ Test for memory leaks
 
 MIDI-SPECIFIC:
 ✅ Use bounded buffers for real-time data
 ✅ Separate streams for different message types
 ✅ Handle multi-packet SysEx correctly
 ✅ Yield on actor to avoid races
 */

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - TEACHING NOTES
// ═══════════════════════════════════════════════════════════════════════════

/*
 📚 SUGGESTED LESSON PLAN (9 Hours Total)
 ═══════════════════════════════════════════════════════════════════════════
 
 WEEK 1: Fundamentals (2 hours)
 ─────────────────────────────────────────────────────────────────
 • What is AsyncStream?
 • Simple counter example (Example 1.1)
 • Understanding yield() (Aha Moment #1)
 • Timer stream exercise (Example 1.2)
 
 LAB: Build a timer stream that yields current time every second
 
 
 WEEK 2: Continuations (2 hours)
 ─────────────────────────────────────────────────────────────────
 • Why store continuations? (Aha Moment #2)
 • Event publisher pattern (Example 2.1)
 • Multiple stream types (Example 2.2)
 • Common mistakes (Example 2.3)
 
 LAB: Build a temperature sensor with AsyncStream
 
 
 WEEK 3: MIDI Application (3 hours)
 ─────────────────────────────────────────────────────────────────
 • MIDI Manager architecture
 • Step-by-step implementation (Level 4)
 • Parsing MIDI 1.0 packets
 • Multiple stream types for MIDI
 
 LAB: Build simple MIDI receiver that prints messages
 
 
 WEEK 4: Advanced Topics (2 hours)
 ─────────────────────────────────────────────────────────────────
 • Buffer policies (Example 3.1)
 • Memory management (Example 3.2)
 • Debugging techniques
 • Best practices checklist
 
 LAB: Build complete MIDI app with UI
 
 
 📝 DISCUSSION QUESTIONS
 ═══════════════════════════════════════════════════════════════════════════
 
 1. Why can't we just use callbacks?
    → AsyncStream provides backpressure, cancellation, and sequential processing
 
 2. What happens if consumer is slower than producer?
    → Buffer fills up based on policy (drop old, drop new, or grow unbounded)
 
 3. How do we handle termination gracefully?
    → Always implement onTermination to clean up continuation
 
 4. When should we use multiple streams vs one stream?
    → Multiple streams when different consumers need different data types
 
 5. What are the trade-offs of different buffer policies?
    → Unbounded = memory risk, Bounded = data loss risk, choose based on use case
 
 6. Why is each stream consumed only once?
    → By design - AsyncStream is a sequence, consumed linearly
 
 7. How does actor isolation help with AsyncStream?
    → Prevents race conditions when storing/accessing continuations
 
 8. What's the difference between finish() and onTermination?
    → finish() = producer ends stream, onTermination = consumer cleanup
 */
