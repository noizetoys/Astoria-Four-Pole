# AsyncStream Hands-On Labs
## Progressive Exercises with Solutions

---

## 🎯 Lab 1: Your First AsyncStream (30 minutes)
**Learning Goal:** Understand basic AsyncStream creation and consumption

### Exercise 1.1: Number Generator
Create an AsyncStream that yields numbers 1 through 10.

**Starter Code:**
```swift
func numberGenerator() -> AsyncStream<Int> {
    // TODO: Create AsyncStream that yields 1...10
}

// Usage:
Task {
    for await number in numberGenerator() {
        print(number)
    }
}
```

**Expected Output:**
```
1
2
3
4
5
6
7
8
9
10
```

<details>
<summary>💡 Hint</summary>

Use a for loop inside the AsyncStream closure to yield values.

</details>

<details>
<summary>✅ Solution</summary>

```swift
func numberGenerator() -> AsyncStream<Int> {
    AsyncStream { continuation in
        for i in 1...10 {
            continuation.yield(i)
        }
        continuation.finish()
    }
}
```

</details>

---

### Exercise 1.2: Countdown Timer
Create a countdown timer that yields remaining seconds.

**Requirements:**
- Start from 10
- Yield each second
- End at 0

**Starter Code:**
```swift
func countdown(from seconds: Int) -> AsyncStream<Int> {
    // TODO: Implement countdown
}

// Usage:
Task {
    for await remaining in countdown(from: 10) {
        print("T-minus: \(remaining)")
    }
    print("🚀 Liftoff!")
}
```

<details>
<summary>✅ Solution</summary>

```swift
func countdown(from seconds: Int) -> AsyncStream<Int> {
    AsyncStream { continuation in
        Task {
            for i in (0...seconds).reversed() {
                continuation.yield(i)
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
            continuation.finish()
        }
    }
}
```

</details>

---

### Exercise 1.3: Fibonacci Sequence
Generate Fibonacci numbers up to a limit.

**Requirements:**
- Start with 0, 1
- Each next number is sum of previous two
- Stop when value exceeds limit

**Starter Code:**
```swift
func fibonacci(upTo limit: Int) -> AsyncStream<Int> {
    // TODO: Generate Fibonacci sequence
}

// Usage:
Task {
    for await num in fibonacci(upTo: 100) {
        print(num)
    }
}
```

**Expected Output:**
```
0
1
1
2
3
5
8
13
21
34
55
89
```

<details>
<summary>✅ Solution</summary>

```swift
func fibonacci(upTo limit: Int) -> AsyncStream<Int> {
    AsyncStream { continuation in
        var a = 0, b = 1
        
        while a <= limit {
            continuation.yield(a)
            let next = a + b
            a = b
            b = next
        }
        
        continuation.finish()
    }
}
```

</details>

---

## 🎯 Lab 2: Event Publisher (45 minutes)
**Learning Goal:** Store continuations for later use

### Exercise 2.1: Button Click Stream
Create a simple button click event publisher.

**Requirements:**
- Store continuation for later use
- Publish click events when button is pressed
- Handle termination properly

**Starter Code:**
```swift
actor ButtonPublisher {
    // TODO: Add continuation storage
    
    func clickStream() -> AsyncStream<Date> {
        // TODO: Create stream and store continuation
    }
    
    func buttonPressed() {
        // TODO: Yield click timestamp
    }
    
    func stop() {
        // TODO: Finish stream
    }
}

// Usage:
Task {
    let button = ButtonPublisher()
    
    Task {
        for await timestamp in await button.clickStream() {
            print("Clicked at: \(timestamp)")
        }
    }
    
    await button.buttonPressed()
    try? await Task.sleep(nanoseconds: 500_000_000)
    await button.buttonPressed()
    try? await Task.sleep(nanoseconds: 500_000_000)
    await button.stop()
}
```

<details>
<summary>✅ Solution</summary>

```swift
actor ButtonPublisher {
    private var continuation: AsyncStream<Date>.Continuation?
    
    func clickStream() -> AsyncStream<Date> {
        AsyncStream { continuation in
            self.continuation = continuation
            
            continuation.onTermination = { @Sendable _ in
                Task {
                    await self.clearContinuation()
                }
            }
        }
    }
    
    func buttonPressed() {
        continuation?.yield(Date())
    }
    
    func stop() {
        continuation?.finish()
        continuation = nil
    }
    
    private func clearContinuation() {
        continuation = nil
    }
}
```

</details>

---

### Exercise 2.2: Multi-Event Publisher
Create a publisher that can emit different event types.

**Requirements:**
- Support "login", "logout", and "error" events
- Each event should have a timestamp
- Maintain separate streams for each event type

**Starter Code:**
```swift
struct AppEvent {
    let type: String
    let timestamp: Date
}

actor EventPublisher {
    // TODO: Store continuations for different event types
    
    func loginStream() -> AsyncStream<Date> {
        // TODO: Create login event stream
    }
    
    func logoutStream() -> AsyncStream<Date> {
        // TODO: Create logout event stream
    }
    
    func errorStream() -> AsyncStream<String> {
        // TODO: Create error event stream
    }
    
    func publishLogin() {
        // TODO
    }
    
    func publishLogout() {
        // TODO
    }
    
    func publishError(_ message: String) {
        // TODO
    }
}
```

<details>
<summary>✅ Solution</summary>

```swift
actor EventPublisher {
    private var loginContinuation: AsyncStream<Date>.Continuation?
    private var logoutContinuation: AsyncStream<Date>.Continuation?
    private var errorContinuation: AsyncStream<String>.Continuation?
    
    func loginStream() -> AsyncStream<Date> {
        AsyncStream { continuation in
            self.loginContinuation = continuation
            continuation.onTermination = { @Sendable _ in
                Task { await self.clearLoginContinuation() }
            }
        }
    }
    
    func logoutStream() -> AsyncStream<Date> {
        AsyncStream { continuation in
            self.logoutContinuation = continuation
            continuation.onTermination = { @Sendable _ in
                Task { await self.clearLogoutContinuation() }
            }
        }
    }
    
    func errorStream() -> AsyncStream<String> {
        AsyncStream { continuation in
            self.errorContinuation = continuation
            continuation.onTermination = { @Sendable _ in
                Task { await self.clearErrorContinuation() }
            }
        }
    }
    
    func publishLogin() {
        loginContinuation?.yield(Date())
    }
    
    func publishLogout() {
        logoutContinuation?.yield(Date())
    }
    
    func publishError(_ message: String) {
        errorContinuation?.yield(message)
    }
    
    private func clearLoginContinuation() { loginContinuation = nil }
    private func clearLogoutContinuation() { logoutContinuation = nil }
    private func clearErrorContinuation() { errorContinuation = nil }
}
```

</details>

---

## 🎯 Lab 3: Buffer Policies (30 minutes)
**Learning Goal:** Understand backpressure and buffer management

### Exercise 3.1: Fast Producer, Slow Consumer
Demonstrate the effect of different buffer policies.

**Scenario:**
- Producer yields 100 numbers instantly
- Consumer processes 1 per second
- Try each buffer policy and observe results

**Starter Code:**
```swift
func testBufferPolicy(_ policy: BufferPolicy) async {
    print("Testing: \(policy)")
    
    let stream = AsyncStream(bufferingPolicy: policy) { continuation in
        for i in 1...100 {
            continuation.yield(i)
            print("Yielded: \(i)")
        }
        continuation.finish()
    }
    
    var received: [Int] = []
    for await value in stream {
        received.append(value)
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
    }
    
    print("Received \(received.count) values")
    print("First 5: \(received.prefix(5))")
    print("Last 5: \(received.suffix(5))")
    print()
}

// TODO: Test each policy
// .unbounded
// .bufferingOldest(10)
// .bufferingNewest(10)
```

**Questions to Answer:**
1. Which policy keeps the most recent values?
2. Which policy keeps the oldest values?
3. Which policy could cause memory issues?

<details>
<summary>✅ Solution & Analysis</summary>

```swift
Task {
    // Test unbounded
    await testBufferPolicy(.unbounded)
    // Result: All 100 values received (memory risk!)
    
    // Test bufferingOldest
    await testBufferPolicy(.bufferingOldest(10))
    // Result: Receives oldest ~10, then newest values
    
    // Test bufferingNewest
    await testBufferPolicy(.bufferingNewest(10))
    // Result: Receives newest ~10 values
}

// Answers:
// 1. .bufferingOldest keeps most recent (drops old)
// 2. .bufferingNewest keeps oldest (drops new)
// 3. .unbounded could exhaust memory
```

</details>

---

## 🎯 Lab 4: Simple MIDI Receiver (60 minutes)
**Learning Goal:** Build a real-world MIDI application

### Exercise 4.1: Note Monitor
Build a simple app that monitors MIDI notes.

**Requirements:**
- Detect Note On and Note Off messages
- Display note name and velocity
- Track which notes are currently held

**Starter Code:**
```swift
actor SimpleMIDIMonitor {
    private var noteStates: [UInt8: Bool] = [:]
    
    // TODO: Add continuation storage
    
    func noteStream() -> AsyncStream<(isOn: Bool, note: UInt8, velocity: UInt8)> {
        // TODO: Create note stream
    }
    
    func receiveMIDI(_ bytes: [UInt8]) {
        // TODO: Parse bytes and yield to stream
        // Format: [status, note, velocity]
        // Status: 0x90 = Note On, 0x80 = Note Off
    }
    
    func activeNotes() -> [UInt8] {
        noteStates.filter { $0.value }.map { $0.key }
    }
}

// Helper: Convert note number to name
func noteName(_ note: UInt8) -> String {
    let names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    let octave = Int(note / 12) - 1
    let name = names[Int(note % 12)]
    return "\(name)\(octave)"
}

// Usage:
Task {
    let monitor = SimpleMIDIMonitor()
    
    Task {
        for await (isOn, note, velocity) in await monitor.noteStream() {
            if isOn {
                print("🎹 \(noteName(note)) ON (velocity: \(velocity))")
            } else {
                print("🎹 \(noteName(note)) OFF")
            }
            
            let active = await monitor.activeNotes()
            print("   Currently held: \(active.map(noteName))")
        }
    }
    
    // Simulate MIDI input
    await monitor.receiveMIDI([0x90, 60, 100])  // C4 on
    try? await Task.sleep(nanoseconds: 500_000_000)
    await monitor.receiveMIDI([0x90, 64, 100])  // E4 on
    try? await Task.sleep(nanoseconds: 500_000_000)
    await monitor.receiveMIDI([0x80, 60, 0])    // C4 off
    try? await Task.sleep(nanoseconds: 500_000_000)
    await monitor.receiveMIDI([0x80, 64, 0])    // E4 off
}
```

<details>
<summary>✅ Solution</summary>

```swift
actor SimpleMIDIMonitor {
    private var noteStates: [UInt8: Bool] = [:]
    private var continuation: AsyncStream<(Bool, UInt8, UInt8)>.Continuation?
    
    func noteStream() -> AsyncStream<(isOn: Bool, note: UInt8, velocity: UInt8)> {
        AsyncStream(bufferingPolicy: .bufferingNewest(50)) { continuation in
            self.continuation = continuation
            continuation.onTermination = { @Sendable _ in
                Task { await self.clearContinuation() }
            }
        }
    }
    
    func receiveMIDI(_ bytes: [UInt8]) {
        guard bytes.count >= 3 else { return }
        
        let status = bytes[0] & 0xF0
        let note = bytes[1]
        let velocity = bytes[2]
        
        switch status {
        case 0x90:  // Note On
            let isOn = velocity > 0
            noteStates[note] = isOn
            continuation?.yield((isOn, note, velocity))
            
        case 0x80:  // Note Off
            noteStates[note] = false
            continuation?.yield((false, note, 0))
            
        default:
            break
        }
    }
    
    func activeNotes() -> [UInt8] {
        noteStates.filter { $0.value }.map { $0.key }.sorted()
    }
    
    private func clearContinuation() {
        continuation = nil
    }
}
```

</details>

---

### Exercise 4.2: CC Monitor with Smoothing
Build a Control Change monitor with value smoothing.

**Requirements:**
- Monitor CC messages
- Display CC number and value
- Implement simple smoothing (average last 3 values)

**Starter Code:**
```swift
actor CCMonitor {
    private var ccHistory: [UInt8: [UInt8]] = [:]
    
    // TODO: Add continuation storage
    
    func ccStream() -> AsyncStream<(cc: UInt8, value: UInt8, smoothed: UInt8)> {
        // TODO: Create CC stream with smoothing
    }
    
    func receiveMIDI(_ bytes: [UInt8]) {
        // TODO: Parse CC messages and apply smoothing
        // Format: [0xB0, cc, value]
    }
    
    private func smoothValue(cc: UInt8, newValue: UInt8) -> UInt8 {
        // TODO: Average last 3 values
        var history = ccHistory[cc, default: []]
        history.append(newValue)
        if history.count > 3 {
            history.removeFirst()
        }
        ccHistory[cc] = history
        
        let sum = history.reduce(0, +)
        return UInt8(sum / UInt8(history.count))
    }
}
```

<details>
<summary>✅ Solution</summary>

```swift
actor CCMonitor {
    private var ccHistory: [UInt8: [UInt8]] = [:]
    private var continuation: AsyncStream<(UInt8, UInt8, UInt8)>.Continuation?
    
    func ccStream() -> AsyncStream<(cc: UInt8, value: UInt8, smoothed: UInt8)> {
        AsyncStream(bufferingPolicy: .bufferingNewest(20)) { continuation in
            self.continuation = continuation
            continuation.onTermination = { @Sendable _ in
                Task { await self.clearContinuation() }
            }
        }
    }
    
    func receiveMIDI(_ bytes: [UInt8]) {
        guard bytes.count >= 3 else { return }
        guard bytes[0] & 0xF0 == 0xB0 else { return }  // CC message
        
        let cc = bytes[1]
        let value = bytes[2]
        let smoothed = smoothValue(cc: cc, newValue: value)
        
        continuation?.yield((cc, value, smoothed))
    }
    
    private func smoothValue(cc: UInt8, newValue: UInt8) -> UInt8 {
        var history = ccHistory[cc, default: []]
        history.append(newValue)
        if history.count > 3 {
            history.removeFirst()
        }
        ccHistory[cc] = history
        
        let sum = history.reduce(0, +)
        return UInt8(sum / UInt8(history.count))
    }
    
    private func clearContinuation() {
        continuation = nil
    }
}
```

</details>

---

## 🎯 Lab 5: Complete MIDI Application (90 minutes)
**Learning Goal:** Build production-ready MIDI manager

### Final Project: Full MIDI Manager
Combine everything into a complete MIDI manager with:
- Multiple stream types (Notes, CCs, SysEx)
- Proper buffer policies
- Memory management
- Error handling

**Specification:**

```swift
actor ProductionMIDIManager {
    // Requirements:
    // 1. Three separate streams: notes, ccs, sysex
    // 2. Buffer policies:
    //    - Notes: .bufferingNewest(50)
    //    - CCs: .bufferingNewest(20)
    //    - SysEx: .bufferingOldest(5)
    // 3. SysEx assembly across multiple packets
    // 4. Proper cleanup on termination
    // 5. Actor-safe access
    
    func noteStream() -> AsyncStream<(isOn: Bool, channel: UInt8, note: UInt8, velocity: UInt8)> {
        // TODO
    }
    
    func ccStream() -> AsyncStream<(channel: UInt8, cc: UInt8, value: UInt8)> {
        // TODO
    }
    
    func sysexStream() -> AsyncStream<[UInt8]> {
        // TODO
    }
    
    func receiveMIDIPacket(_ bytes: [UInt8]) {
        // TODO: Parse and route to appropriate streams
    }
}
```

**Test Cases:**

```swift
Task {
    let manager = ProductionMIDIManager()
    
    // Start listeners
    Task {
        for await (isOn, ch, note, vel) in await manager.noteStream() {
            print("Note: \(note) \(isOn ? "ON" : "OFF")")
        }
    }
    
    Task {
        for await (ch, cc, val) in await manager.ccStream() {
            print("CC\(cc): \(val)")
        }
    }
    
    Task {
        for await sysex in await manager.sysexStream() {
            print("SysEx: \(sysex.count) bytes")
        }
    }
    
    // Test note
    await manager.receiveMIDIPacket([0x90, 60, 100])
    
    // Test CC
    await manager.receiveMIDIPacket([0xB0, 16, 64])
    
    // Test SysEx (multi-packet)
    await manager.receiveMIDIPacket([0xF0, 0x3E, 0x04])
    await manager.receiveMIDIPacket([0x01, 0x00, 0x1F])
    await manager.receiveMIDIPacket([0x40, 0x7F, 0xF7])
}
```

<details>
<summary>✅ Full Solution</summary>

```swift
actor ProductionMIDIManager {
    private var noteContinuation: AsyncStream<(Bool, UInt8, UInt8, UInt8)>.Continuation?
    private var ccContinuation: AsyncStream<(UInt8, UInt8, UInt8)>.Continuation?
    private var sysexContinuation: AsyncStream<[UInt8]>.Continuation?
    private var sysexBuffer: [UInt8] = []
    
    func noteStream() -> AsyncStream<(isOn: Bool, channel: UInt8, note: UInt8, velocity: UInt8)> {
        AsyncStream(bufferingPolicy: .bufferingNewest(50)) { continuation in
            self.noteContinuation = continuation
            continuation.onTermination = { @Sendable _ in
                Task { await self.clearNoteContinuation() }
            }
        }
    }
    
    func ccStream() -> AsyncStream<(channel: UInt8, cc: UInt8, value: UInt8)> {
        AsyncStream(bufferingPolicy: .bufferingNewest(20)) { continuation in
            self.ccContinuation = continuation
            continuation.onTermination = { @Sendable _ in
                Task { await self.clearCCContinuation() }
            }
        }
    }
    
    func sysexStream() -> AsyncStream<[UInt8]> {
        AsyncStream(bufferingPolicy: .bufferingOldest(5)) { continuation in
            self.sysexContinuation = continuation
            continuation.onTermination = { @Sendable _ in
                Task { await self.clearSysExContinuation() }
            }
        }
    }
    
    func receiveMIDIPacket(_ bytes: [UInt8]) {
        var i = 0
        
        while i < bytes.count {
            let byte = bytes[i]
            
            // SysEx handling
            if byte == 0xF0 {
                sysexBuffer = [0xF0]
                i += 1
                
                while i < bytes.count {
                    let dataByte = bytes[i]
                    sysexBuffer.append(dataByte)
                    i += 1
                    
                    if dataByte == 0xF7 {
                        sysexContinuation?.yield(sysexBuffer)
                        sysexBuffer = []
                        break
                    }
                }
                continue
            }
            
            // Continue SysEx
            if !sysexBuffer.isEmpty {
                sysexBuffer.append(byte)
                i += 1
                
                if byte == 0xF7 {
                    sysexContinuation?.yield(sysexBuffer)
                    sysexBuffer = []
                }
                continue
            }
            
            // Channel voice messages
            if byte & 0x80 != 0 {
                let messageType = byte & 0xF0
                let channel = byte & 0x0F
                
                switch messageType {
                case 0x80:  // Note Off
                    if i + 2 < bytes.count {
                        let note = bytes[i + 1]
                        let velocity = bytes[i + 2]
                        noteContinuation?.yield((false, channel, note, velocity))
                        i += 3
                    } else {
                        i += 1
                    }
                    
                case 0x90:  // Note On
                    if i + 2 < bytes.count {
                        let note = bytes[i + 1]
                        let velocity = bytes[i + 2]
                        noteContinuation?.yield((velocity > 0, channel, note, velocity))
                        i += 3
                    } else {
                        i += 1
                    }
                    
                case 0xB0:  // Control Change
                    if i + 2 < bytes.count {
                        let cc = bytes[i + 1]
                        let value = bytes[i + 2]
                        ccContinuation?.yield((channel, cc, value))
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
    
    private func clearNoteContinuation() { noteContinuation = nil }
    private func clearCCContinuation() { ccContinuation = nil }
    private func clearSysExContinuation() { sysexContinuation = nil }
}
```

</details>

---

## 🏆 Challenge Projects

### Challenge 1: Throughput Tester
Build a tool that measures AsyncStream throughput under different conditions.

**Deliverables:**
- Test different buffer policies
- Measure data loss under pressure
- Generate performance report

### Challenge 2: MIDI Logger
Build a complete MIDI message logger with:
- Timestamp display
- Message type filtering
- Export to file
- Real-time statistics

### Challenge 3: Virtual MIDI Keyboard
Build a virtual MIDI keyboard that:
- Displays pressed keys visually
- Shows velocity as color intensity
- Tracks sustain pedal
- Displays active CCs

---

## 📊 Self-Assessment Checklist

After completing all labs, you should be able to:

**Level 1: Basics**
- [ ] Create simple AsyncStreams
- [ ] Use yield() to produce values
- [ ] Consume streams with for await
- [ ] Understand when streams end

**Level 2: Intermediate**
- [ ] Store continuations for later use
- [ ] Create multiple stream types
- [ ] Implement onTermination handlers
- [ ] Handle async operations in streams

**Level 3: Advanced**
- [ ] Choose appropriate buffer policies
- [ ] Prevent memory leaks
- [ ] Handle backpressure
- [ ] Use actor isolation correctly

**Level 4: Production**
- [ ] Build complete MIDI manager
- [ ] Parse MIDI 1.0 messages
- [ ] Handle multi-packet SysEx
- [ ] Debug stream issues

---

## 💡 Tips for Success

1. **Start Small:** Master each level before moving to the next
2. **Debug with Prints:** Add print statements to understand flow
3. **Test Edge Cases:** What happens when buffer is full?
4. **Read Error Messages:** Swift provides helpful hints
5. **Use Instruments:** Profile memory usage
6. **Ask Questions:** No question is too basic

---

## 📚 Additional Resources

**For More Practice:**
- AsyncSequence protocol
- Combine framework (similar concepts)
- Reactive programming patterns
- Real-time systems design

**Tools:**
- Xcode Instruments (memory profiling)
- MIDI Monitor app (test MIDI input)
- Virtual MIDI cables (test without hardware)

---

## ✅ Lab Completion Certificate

```
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║          ASYNCSTREAM MASTERY LABS COMPLETED                ║
║                                                            ║
║  Student: _____________________                           ║
║  Date: _____________________                              ║
║                                                            ║
║  Skills Mastered:                                          ║
║  ✅ AsyncStream creation and consumption                  ║
║  ✅ Continuation management                               ║
║  ✅ Buffer policies and backpressure                      ║
║  ✅ Real-world MIDI applications                          ║
║                                                            ║
║  Instructor: _____________________                        ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
```
