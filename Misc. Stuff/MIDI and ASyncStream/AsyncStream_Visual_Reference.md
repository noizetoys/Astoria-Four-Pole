# AsyncStream Visual Reference Guide
## Quick Reference for Teachers & Students

---

## The Big Picture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        ASYNCSTREAM FLOW                             │
└─────────────────────────────────────────────────────────────────────┘

Producer (Callback/Event)              Consumer (UI/Processing)
─────────────────────────              ────────────────────────
        │                                      │
        │  1. Create Stream                    │
        └──────────────►┌─────────────┐        │
                        │ AsyncStream  │        │
        ┌──────────────►│   (Buffer)   │────────┘
        │ 2. yield()    └─────────────┘ 3. for await
        │                     │
        │  yield(1)           │ [1]
        │  yield(2)           │ [1,2]
        │  yield(3)           │ [1,2,3] → await gets 1
        │                     │ [2,3] → await gets 2
        │                     │ [3] → await gets 3
        │                     │
        └ finish()            └ (stream ends)
```

---

## The Four "Aha!" Moments

### 1️⃣ yield() Doesn't Block!

```
❌ Common Misconception:
   yield(value) → waits for consumer to read it

✅ Reality:
   yield(value) → adds to buffer, returns immediately
   
Timeline:
─────────────────────────────────────────
Producer                    Consumer
─────────                   ────────
yield(1)  [instant]         
yield(2)  [instant]         
yield(3)  [instant]         
                            for await... (starts reading)
                            receives 1
                            receives 2
                            receives 3
```

### 2️⃣ Must Store Continuation for Later Use

```
❌ Wrong - Continuation dies when closure ends:

AsyncStream { continuation in
    continuation.yield(1)  ✅
    // Closure ends
}
// Can't yield here! ❌

✅ Right - Store it to yield later:

var stored: Continuation?

AsyncStream { continuation in
    stored = continuation  // Save it!
}

// Later, from anywhere:
stored?.yield(1)  ✅
```

### 3️⃣ Always Clean Up on Termination

```
❌ Memory Leak Pattern:

private var continuation: Continuation?

func stream() -> AsyncStream<Int> {
    AsyncStream { continuation in
        self.continuation = continuation
        // No cleanup! Leaks memory
    }
}

✅ Proper Cleanup:

func stream() -> AsyncStream<Int> {
    AsyncStream { continuation in
        self.continuation = continuation
        
        continuation.onTermination = { _ in
            Task {
                await self.cleanup()
            }
        }
    }
}

private func cleanup() {
    continuation = nil
}
```

### 4️⃣ One Stream = One Consumer

```
❌ Won't Work:
let stream = manager.sysexStream()

Task { 
    for await data in stream { ... }  // Gets data
}
Task { 
    for await data in stream { ... }  // Gets nothing!
}

✅ Works:
Task { 
    for await data in manager.sysexStream() { ... }  // New stream
}
Task { 
    for await data in manager.sysexStream() { ... }  // New stream
}
```

---

## Buffer Policies Visualized

### Unbounded (⚠️ Dangerous!)
```
Producer: ──1─2─3─4─5─6─7─8─9──→ (fast)
                ↓
Buffer:    [1,2,3,4,5,6,7,8,9,...]  (grows forever!)
                ↓
Consumer:  ───1────2────3───→ (slow)

⚠️ Risk: Out of memory!
```

### bufferingOldest(3) - Keep Newest
```
Producer: ──1─2─3─4─5─6─7─8─9──→
                ↓
Buffer:    [1,2,3]  (full!)
           [2,3,4]  (dropped 1, added 4)
           [3,4,5]  (dropped 2, added 5)
                ↓
Consumer:  ───3────4────5───→

✅ Use for: Real-time data where latest matters
✅ MIDI: SysEx (latest patch data)
```

### bufferingNewest(3) - Keep Oldest
```
Producer: ──1─2─3─4─5─6─7─8─9──→
                ↓
Buffer:    [1,2,3]  (full!)
           [1,2,3]  (dropped 4, kept old)
           [1,2,3]  (dropped 5, kept old)
                ↓
Consumer:  ───1────2────3───→

✅ Use for: Sequential data where order matters
✅ MIDI: Notes (can't drop note-offs!)
```

---

## MIDI 1.0 Packet Flow

```
┌────────────────────────────────────────────────────────────┐
│                    Hardware → Software                     │
└────────────────────────────────────────────────────────────┘

Synthesizer                                              Your App
───────────                                              ────────
    │
    │ sends: [0x90, 0x3C, 0x64]  (Note On, Middle C, velocity 100)
    ↓
┌─────────────┐
│   CoreMIDI  │
└─────────────┘
    │
    │ MIDIPacketList
    │   timestamp: 12345678
    │   length: 3
    │   data: [0x90, 0x3C, 0x64]
    ↓
┌───────────────────────────┐
│  MIDIInputPortCallback    │  (runs on MIDI thread)
└───────────────────────────┘
    │
    │ Task { await manager.handlePackets(...) }
    ↓
┌───────────────────────────┐
│  MIDIManager (Actor)      │  (actor-isolated)
│                           │
│  parseBytes([0x90,0x3C,0x64])
│    ↓
│  status: 0x90 (Note On)
│  channel: 0
│  note: 0x3C (60)
│  velocity: 0x64 (100)
│    ↓
│  noteContinuation?.yield((true, 0, 60, 100))
└───────────────────────────┘
    │
    │ AsyncStream yields
    ↓
┌───────────────────────────┐
│  for await (isOn, ch,     │
│    note, vel) in          │
│    noteStream() {         │
│      updateUI(note)       │
│  }                        │
└───────────────────────────┘
```

---

## SysEx Assembly (Multi-Packet)

```
Packet 1:  [0xF0, 0x3E, 0x04, ...]  (Start of SysEx)
    ↓
Buffer:    [0xF0, 0x3E, 0x04, ...]
    
Packet 2:  [..., ..., ..., ...]     (Continuation)
    ↓
Buffer:    [0xF0, 0x3E, 0x04, ..., ..., ..., ...]

Packet 3:  [..., ..., 0xF7]         (End of SysEx)
    ↓
Buffer:    [0xF0, 0x3E, 0x04, ..., ..., ..., ..., 0xF7]
    ↓
Yield complete SysEx to stream!
```

---

## Actor Isolation Safety

```
❌ DANGEROUS - Race Condition:

class Manager {
    private var continuation: Continuation?
    
    func publish(_ value: Int) {
        continuation?.yield(value)  // ⚠️ NOT thread-safe!
    }
}

// Called from multiple threads → crash!


✅ SAFE - Actor Isolation:

actor Manager {
    private var continuation: Continuation?
    
    func publish(_ value: Int) {
        continuation?.yield(value)  // ✅ Actor-isolated, safe!
    }
}

// Actor ensures serial access → no crash!
```

---

## Termination Flow

```
┌────────────────────────────────────────────────────────┐
│              Normal Termination                        │
└────────────────────────────────────────────────────────┘

Producer Side:                   Consumer Side:
─────────────                   ─────────────

continuation.finish()           for await value in stream {
      ↓                              ...
      │                          }
      │ marks stream as ended    ↓
      │                          loop detects end
      ↓                          ↓
onTermination fires              loop exits
      ↓
cleanup continuation
```

```
┌────────────────────────────────────────────────────────┐
│          Consumer Cancellation                         │
└────────────────────────────────────────────────────────┘

Producer Side:                   Consumer Side:
─────────────                   ─────────────

(yielding data...)              task.cancel()
                                      ↓
                                cancellation propagates
                                      ↓
onTermination fires             for await loop stops
      ↓                               ↓
cleanup continuation            task exits
```

---

## Memory Management Patterns

### ✅ Pattern 1: Weak Self in Closures
```swift
func stream() -> AsyncStream<Int> {
    AsyncStream { continuation in
        continuation.onTermination = { [weak self] _ in
            self?.continuation = nil  // Won't create retain cycle
        }
    }
}
```

### ✅ Pattern 2: Active Flag
```swift
actor Publisher {
    private var continuation: Continuation?
    private var isActive = false
    
    func stream() -> AsyncStream<Int> {
        AsyncStream { continuation in
            self.continuation = continuation
            self.isActive = true
        }
    }
    
    func publish(_ value: Int) {
        guard isActive else { return }  // Don't yield if inactive
        continuation?.yield(value)
    }
    
    func stop() {
        isActive = false
        continuation?.finish()
        continuation = nil
    }
}
```

### ✅ Pattern 3: Automatic Cleanup
```swift
func stream() -> AsyncStream<Int> {
    AsyncStream { continuation in
        self.continuation = continuation
        
        // Cleanup happens automatically when:
        continuation.onTermination = { @Sendable _ in
            Task {
                await self.cleanup()  // 1. Consumer stops
            }                         // 2. Stream finishes
        }                             // 3. Task is cancelled
    }
}
```

---

## Common Mistakes Debugging Guide

### 🐛 Stream Never Receives Data

**Symptoms:**
- `for await` loop never executes
- No values printed

**Check:**
```
□ Is continuation stored?
    print("Continuation: \(continuation == nil ? "NIL" : "OK")")

□ Is yield() called?
    print("Yielding: \(value)")
    continuation?.yield(value)

□ Did consumer start BEFORE producer?
    // Start consumer first:
    Task { for await value in stream() { ... } }
    // Then start producing:
    await publisher.publish(123)

□ Is it yielding on correct actor?
    // Must be actor-isolated:
    actor Publisher {
        func publish(_ value: Int) {  // ✅ actor-isolated
            continuation?.yield(value)
        }
    }
```

### 🐛 Memory Leak

**Symptoms:**
- Memory grows over time
- Instruments shows growing object count

**Check:**
```
□ Is finish() called?
    continuation.finish()  // ← Add this!

□ Is onTermination implemented?
    continuation.onTermination = { _ in
        Task { await self.cleanup() }  // ← Add this!
    }

□ Strong reference cycle?
    // Use [weak self]:
    continuation.onTermination = { [weak self] _ in
        self?.continuation = nil  // ← Add [weak self]
    }

□ Unbounded buffer?
    // Change to bounded:
    AsyncStream(bufferingPolicy: .bufferingOldest(10)) { ... }
```

### 🐛 Missing Data

**Symptoms:**
- Some values not received
- Gaps in sequence

**Check:**
```
□ Buffer too small?
    // Increase buffer:
    .bufferingOldest(50)  // ← Bigger

□ Consumer too slow?
    for await value in stream {
        // Don't do heavy work here!
        Task.detached {
            await processHeavy(value)  // ← Move to background
        }
    }

□ Wrong buffer policy?
    // For MIDI notes (can't drop):
    .bufferingNewest(50)  // ← Keep oldest
```

---

## Quick Reference Card

```
╔════════════════════════════════════════════════════════════╗
║               ASYNCSTREAM QUICK REFERENCE                  ║
╠════════════════════════════════════════════════════════════╣
║                                                            ║
║  CREATE                                                    ║
║  ──────                                                    ║
║  AsyncStream { continuation in                            ║
║      self.cont = continuation                             ║
║      continuation.onTermination = { _ in cleanup() }      ║
║  }                                                         ║
║                                                            ║
║  PRODUCE                                                   ║
║  ────────                                                  ║
║  continuation?.yield(value)  // Add value                 ║
║  continuation?.finish()      // End stream                ║
║                                                            ║
║  CONSUME                                                   ║
║  ────────                                                  ║
║  for await value in stream {                              ║
║      process(value)                                       ║
║  }                                                         ║
║                                                            ║
║  BUFFER POLICIES                                           ║
║  ────────────────                                          ║
║  .unbounded              → Grows forever (⚠️)             ║
║  .bufferingOldest(N)     → Keep newest N                  ║
║  .bufferingNewest(N)     → Keep oldest N                  ║
║                                                            ║
║  MEMORY SAFETY                                             ║
║  ──────────────                                            ║
║  ✅ Always use [weak self] in closures                    ║
║  ✅ Always implement onTermination                        ║
║  ✅ Always call finish() when done                        ║
║  ✅ Always use actor isolation                            ║
║                                                            ║
║  MIDI RECOMMENDATIONS                                      ║
║  ─────────────────────                                     ║
║  SysEx:  .bufferingOldest(5)   → Latest patch            ║
║  CC:     .bufferingNewest(20)  → All moves               ║
║  Notes:  .bufferingNewest(50)  → Can't drop              ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
```

---

## Decision Tree: When to Use What

```
┌─────────────────────────────────────────────────┐
│  Do you need to turn callbacks into async?      │
└─────────────┬───────────────────────────────────┘
              │
              ├─ Yes → Use AsyncStream
              │
              └─ No → Use async/await directly

┌─────────────────────────────────────────────────┐
│  Is the data produced from outside the closure? │
└─────────────┬───────────────────────────────────┘
              │
              ├─ Yes → Store continuation
              │         (MIDI callbacks, timers, etc.)
              │
              └─ No → Yield directly in closure
                      (sequences, generators)

┌─────────────────────────────────────────────────┐
│  Do you need multiple consumers?                │
└─────────────┬───────────────────────────────────┘
              │
              ├─ Yes → Create new stream per consumer
              │         (Call manager.stream() multiple times)
              │
              └─ No → Single stream is fine

┌─────────────────────────────────────────────────┐
│  Is producer faster than consumer?              │
└─────────────┬───────────────────────────────────┘
              │
              ├─ Yes → Choose buffer policy:
              │         • Latest data matters → .bufferingOldest(N)
              │         • All data matters → .bufferingNewest(N)
              │         • Memory available → .unbounded (risky!)
              │
              └─ No → Default buffering is fine

┌─────────────────────────────────────────────────┐
│  Does this need to be thread-safe?              │
└─────────────┬───────────────────────────────────┘
              │
              ├─ Yes → Wrap in actor
              │         (MIDI Manager, Publishers)
              │
              └─ No → Class/struct is fine
                      (Pure generators)
```

---

## Teaching Tips

### For Live Coding Sessions

1. **Start with println debugging:**
   ```swift
   AsyncStream { continuation in
       print("🎬 Stream created")
       continuation.yield(1)
       print("✅ Yielded 1")
       continuation.finish()
       print("🏁 Stream finished")
   }
   ```

2. **Show the mistake, then fix:**
   - First show code WITHOUT onTermination
   - Run Instruments to show leak
   - Then add onTermination and show it fixed

3. **Use visual metaphors:**
   - AsyncStream = Conveyor belt
   - yield() = Put item on belt
   - for await = Take item off belt
   - Buffer = Items on belt between producer and consumer

4. **Build complexity gradually:**
   - Week 1: Simple counter
   - Week 2: Event publisher
   - Week 3: Multiple streams
   - Week 4: Full MIDI system

### For Code Reviews

**Questions to ask:**
- [ ] Is the buffer policy appropriate?
- [ ] Is onTermination implemented?
- [ ] Are there any strong reference cycles?
- [ ] Is the continuation actor-isolated?
- [ ] Is finish() called in all exit paths?

---

## Further Reading

**Apple Documentation:**
- AsyncStream Reference
- Swift Concurrency Roadmap
- CoreMIDI Programming Guide

**Related Concepts:**
- AsyncThrowingStream (for error handling)
- AsyncSequence protocol
- Task cancellation
- Actor isolation

---

## License & Attribution

This guide is designed for educational purposes.
Feel free to use in classroom settings, workshops, or self-study.

Last Updated: 2024
Swift Version: 5.9+
MIDI Protocol: MIDI 1.0
