# The Missing Piece: How MIDI Pipeline Actually Works

## The Question You're Asking

**"I see continuations being stored, but WHERE and WHEN do they actually get triggered to run?"**

This is THE critical question that the documentation glossed over! Let me show you the complete picture.

---

## The Complete Flow (What Was Missing)

```
┌─────────────────────────────────────────────────────────────────┐
│  THE MISSING LINK: CoreMIDI Callback Registration              │
└─────────────────────────────────────────────────────────────────┘

1. App starts → MIDIManager.init() called
       ↓
2. setupMIDI() creates input port WITH CALLBACK
       ↓
3. CoreMIDI registers callback function
       ↓
4. App creates streams (stores continuations)
       ↓
5. Hardware sends MIDI → CoreMIDI → Calls YOUR callback
       ↓
6. Callback receives packets → Actor method → yield()
```

---

## Part 1: Registration (This Happens ONCE at Startup)

### The Critical Line You Were Missing

In `ComprehensiveMIDIManager.swift`, look at `setupMIDI()`:

```swift
private func setupMIDI() {
    var client: MIDIClientRef = 0
    var status = MIDIClientCreateWithBlock("MIDIManager" as CFString, &client) { _ in }
    
    self.client = client
    
    // ⭐ THIS IS THE CRITICAL LINE ⭐
    var inPort: MIDIPortRef = 0
    status = MIDIInputPortCreateWithBlock(
        client,
        "MIDIManager Input" as CFString,
        &inPort
    ) { [weak self] packetList, _ in
        // ⚡ THIS CLOSURE IS THE CALLBACK! ⚡
        // CoreMIDI will call this from its own thread
        // whenever MIDI data arrives
        
        Task {
            await self?.handleIncomingPackets(packetList)
        }
    }
    
    self.inputPort = inPort
}
```

**What's happening:**
1. `MIDIInputPortCreateWithBlock` registers a **callback closure** with CoreMIDI
2. This closure is stored by the CoreMIDI system (not by your code)
3. CoreMIDI calls this closure from its own thread whenever MIDI arrives
4. The closure wraps the call in a `Task` to marshal it to the actor

---

## Part 2: Connection (This Happens When Device Selected)

```swift
public func connect(source: MIDIDevice, destination: MIDIDevice) throws {
    // ⭐ THIS LINE TELLS CoreMIDI TO START SENDING DATA ⭐
    let status = MIDIPortConnectSource(inputPort, source.endpoint, nil)
    guard status == noErr else {
        throw MIDIError.connectionFailed(status)
    }
    
    // Store connection info
    let connection = DeviceConnection(
        source: source,
        destination: destination,
        sysexContinuation: nil,
        ccContinuation: nil,
        noteContinuation: nil
    )
    
    connections[source.id] = connection
}
```

**What's happening:**
- `MIDIPortConnectSource` tells CoreMIDI: "Send MIDI from this device to my callback"
- Now when hardware sends MIDI, CoreMIDI routes it to your registered callback

---

## Part 3: Stream Creation (This Happens When UI Subscribes)

```swift
func sysexStream(from device: MIDIDevice) -> AsyncStream<[UInt8]> {
    AsyncStream(bufferingPolicy: .bufferingOldest(5)) { continuation in
        // This closure runs ONCE when stream is created
        
        // Store the continuation
        if var connection = connections[device.id] {
            connection.sysexContinuation = continuation  // ⭐ STORED HERE
            connections[device.id] = connection
        }
        
        continuation.onTermination = { @Sendable _ in
            Task {
                await self.removeSysExContinuation(for: device.id)
            }
        }
    }
}
```

**What's happening:**
- UI calls this to get a stream
- Continuation is created and stored in the connection
- Now the callback can use this continuation to yield data

---

## Part 4: The Trigger (This Happens Continuously)

### The Complete Chain Reaction

```
Hardware Keyboard
    │
    │ (sends MIDI bytes over USB/cable)
    ↓
CoreMIDI System (OS Level)
    │
    │ (receives bytes, packages into MIDIPacketList)
    ↓
YOUR CALLBACK ⚡ (registered in setupMIDI)
    │
    │ { [weak self] packetList, _ in
    │     Task {
    │         await self?.handleIncomingPackets(packetList)
    │     }
    │ }
    ↓
Task (marshals to actor)
    │
    ↓
handleIncomingPackets() [actor method]
    │
    │ private func handleIncomingPackets(_ packetList: UnsafePointer<MIDIPacketList>) {
    │     var packet = packetList.pointee.packet
    │     
    │     for _ in 0..<packetList.pointee.numPackets {
    │         let bytes = ... extract bytes from packet ...
    │         parseAndYield(bytes)  // ← Calls this
    │         packet = MIDIPacketNext(&packet).pointee
    │     }
    │ }
    ↓
parseAndYield() [actor method]
    │
    │ private func parseAndYield(_ bytes: [UInt8]) {
    │     // Parse MIDI message type
    │     if byte == 0xF0 {
    │         // ... assemble SysEx ...
    │         yieldSysEx(sysexBuffer)  // ← Calls this
    │     }
    │     else if status == 0xB0 {
    │         yieldCC(channel, cc, value)  // ← Or this
    │     }
    │     // etc.
    │ }
    ↓
yieldSysEx() / yieldCC() / yieldNote()
    │
    │ private func yieldSysEx(_ data: [UInt8]) {
    │     for (_, connection) in connections {
    │         connection.sysexContinuation?.yield(data)  // ⚡ FINALLY!
    │     }
    │ }
    ↓
AsyncStream buffer
    │
    │ [data queued here]
    ↓
for await loop in UI
    │
    │ Task {
    │     for await sysex in await midi.sysexStream(from: device) {
    │         print("Received: \(sysex)")  // ← DATA ARRIVES HERE!
    │     }
    │ }
```

---

## The Timeline (When Things Happen)

```
T=0s    App Launch
        └─ MIDIManager.init()
           └─ setupMIDI()
              └─ MIDIInputPortCreateWithBlock(callback) ← CALLBACK REGISTERED
              
T=1s    User selects MIDI device in UI
        └─ connect(source, destination)
           └─ MIDIPortConnectSource() ← START RECEIVING FROM DEVICE
           
T=2s    User opens SysEx monitor view
        └─ Task { for await sysex in midi.sysexStream() { ... } }
           └─ sysexStream() called
              └─ Continuation created and stored
              
T=3s    User presses key on hardware keyboard
        ↓
        Hardware sends: [0x90, 0x3C, 0x64]
        ↓
        CoreMIDI receives bytes
        ↓
        ⚡ CoreMIDI CALLS YOUR CALLBACK ⚡
        └─ { packetList in
              Task { await handleIncomingPackets(packetList) }
           }
           ↓
           Actor processes packets
           ↓
           parseAndYield([0x90, 0x3C, 0x64])
           ↓
           yieldNote(isOn: true, channel: 0, note: 60, velocity: 100)
           ↓
           connection.noteContinuation?.yield((true, 0, 60, 100))
           ↓
           AsyncStream buffer receives value
           ↓
           for await loop in UI gets value
           └─ UI updates: "Note On: C4"

T=3.5s  User presses another key → SAME FLOW AGAIN
```

---

## The Key Insight You Were Missing

### CoreMIDI is Event-Driven

CoreMIDI operates like a **push notification system**:

1. **You register** a callback (like subscribing to push notifications)
2. **CoreMIDI watches** the hardware (runs in background)
3. **When data arrives**, CoreMIDI **calls your callback** (sends you a push)
4. **Your callback** marshals to actor and yields to stream

**You don't poll for MIDI data. CoreMIDI pushes it to you.**

---

## Common Misconception

### ❌ What People Think Happens:
```swift
// Somewhere in the code...
while true {
    let midiData = checkForMIDI()  // ← This doesn't exist!
    if let data = midiData {
        yield(data)
    }
}
```

### ✅ What Actually Happens:
```swift
// During setup:
MIDIInputPortCreateWithBlock { packetList in
    // CoreMIDI calls THIS when data arrives
    handleIncomingPackets(packetList)
}

// Later, asynchronously:
// *Hardware sends data*
// *CoreMIDI sees it*
// *CoreMIDI calls your callback*
// *Callback yields to stream*
```

---

## Why the Task Wrapper?

```swift
MIDIInputPortCreateWithBlock { [weak self] packetList, _ in
    Task {  // ← Why do we need this?
        await self?.handleIncomingPackets(packetList)
    }
}
```

**Because:**
1. CoreMIDI callback runs on **CoreMIDI's thread** (not main thread)
2. `handleIncomingPackets()` is an **actor method** (must run on actor)
3. `Task {}` **marshals** the call from CoreMIDI thread → Actor

Without the `Task`, you'd get: **"Actor-isolated instance method cannot be called from non-isolated context"**

---

## Complete Working Example (Step by Step)

```swift
import CoreMIDI

actor MIDIManager {
    private var client: MIDIClientRef = 0
    private var inputPort: MIDIPortRef = 0
    private var connections: [MIDIUniqueID: Connection] = [:]
    
    // STEP 1: Initialize (happens once at app start)
    init() {
        setupMIDI()
    }
    
    // STEP 2: Register callback with CoreMIDI
    private func setupMIDI() {
        var client: MIDIClientRef = 0
        MIDIClientCreateWithBlock("MyApp" as CFString, &client) { _ in }
        self.client = client
        
        var inPort: MIDIPortRef = 0
        
        // ⭐ THE MAGIC LINE ⭐
        // This tells CoreMIDI: "Call this closure whenever MIDI arrives"
        MIDIInputPortCreateWithBlock(
            client,
            "Input" as CFString,
            &inPort
        ) { [weak self] packetList, _ in
            // ⚡ THIS RUNS WHEN HARDWARE SENDS MIDI ⚡
            // (Called by CoreMIDI from its own thread)
            
            print("🎹 CoreMIDI callback fired!")
            
            Task {
                // Marshal to actor
                await self?.handleIncomingPackets(packetList)
            }
        }
        
        self.inputPort = inPort
        print("✅ MIDI callback registered")
    }
    
    // STEP 3: Connect to device (tells CoreMIDI which device to monitor)
    func connect(to device: MIDIDevice) {
        let status = MIDIPortConnectSource(inputPort, device.endpoint, nil)
        
        let connection = Connection(
            device: device,
            continuation: nil
        )
        connections[device.id] = connection
        
        print("✅ Connected to \(device.name)")
        print("   CoreMIDI will now route this device's data to our callback")
    }
    
    // STEP 4: Create stream (stores continuation for yielding)
    func midiStream(from device: MIDIDevice) -> AsyncStream<[UInt8]> {
        print("📺 Stream created, storing continuation")
        
        return AsyncStream { continuation in
            // Store continuation
            if var conn = connections[device.id] {
                conn.continuation = continuation
                connections[device.id] = conn
                print("   ✅ Continuation stored")
            }
            
            continuation.onTermination = { _ in
                print("   🛑 Stream terminated")
            }
        }
    }
    
    // STEP 5: Handle incoming packets (called FROM callback)
    private func handleIncomingPackets(_ packetList: UnsafePointer<MIDIPacketList>) {
        print("  → handleIncomingPackets called (on actor)")
        
        var packet = packetList.pointee.packet
        for _ in 0..<packetList.pointee.numPackets {
            let bytes = withUnsafeBytes(of: &packet.data) { pointer in
                Array(pointer.prefix(Int(packet.length)))
            }
            
            print("     Packet bytes: \(bytes)")
            yieldToStreams(bytes)
            
            packet = MIDIPacketNext(&packet).pointee
        }
    }
    
    // STEP 6: Yield to streams (finally!)
    private func yieldToStreams(_ bytes: [UInt8]) {
        print("     ⚡ Yielding to streams...")
        
        for (_, connection) in connections {
            connection.continuation?.yield(bytes)
            print("        ✅ Yielded!")
        }
    }
    
    private struct Connection {
        let device: MIDIDevice
        var continuation: AsyncStream<[UInt8]>.Continuation?
    }
}

// STEP 7: Use it!
func example() async {
    let midi = MIDIManager()
    
    // Get devices
    let source = MIDIDevice(endpoint: MIDIGetSource(0), type: .source)!
    
    // Connect
    await midi.connect(to: source)
    
    // Create stream
    let stream = await midi.midiStream(from: source)
    
    // Listen
    Task {
        print("🎧 Listening for MIDI...")
        for await bytes in stream {
            print("🎵 RECEIVED IN UI: \(bytes)")
        }
    }
    
    // Now play something on the keyboard...
    // CoreMIDI will call the callback
    // Which will yield to the stream
    // Which will print here!
}
```

---

## What Makes This Confusing

### Three Different "Triggers"

1. **Callback Registration** (setup time)
   - `MIDIInputPortCreateWithBlock` - registers with CoreMIDI
   - Happens once during init

2. **Device Connection** (user action)
   - `MIDIPortConnectSource` - tells CoreMIDI which device to monitor
   - Happens when user selects device

3. **Data Arrival** (hardware event)
   - **CoreMIDI calls your callback** - the actual trigger!
   - Happens continuously when hardware sends MIDI

The third one is what actually makes data flow, but it's **implicit** - you don't call it, CoreMIDI does!

---

## Debugging: How to See It Working

Add prints to see the flow:

```swift
private func setupMIDI() {
    MIDIInputPortCreateWithBlock(...) { packetList, _ in
        print("🔔 CALLBACK FIRED!")  // ← See when CoreMIDI calls you
        Task {
            await self?.handleIncomingPackets(packetList)
        }
    }
}

private func handleIncomingPackets(_ packetList: ...) {
    print("  📦 Processing packets on actor")  // ← See actor processing
    // ...
}

private func yieldToStreams(_ bytes: [UInt8]) {
    print("    ⚡ Yielding: \(bytes)")  // ← See the yield
    continuation?.yield(bytes)
}

// In UI:
Task {
    for await bytes in stream {
        print("      🎵 UI received: \(bytes)")  // ← See UI getting data
    }
}
```

Play a key and you'll see:
```
🔔 CALLBACK FIRED!
  📦 Processing packets on actor
    ⚡ Yielding: [144, 60, 100]
      🎵 UI received: [144, 60, 100]
```

---

## Summary: The Complete Picture

```
┌─────────────────────────────────────────────────────────────┐
│ SETUP (Once)                                                │
├─────────────────────────────────────────────────────────────┤
│ 1. MIDIManager.init()                                       │
│ 2. setupMIDI()                                              │
│ 3. MIDIInputPortCreateWithBlock { callback }  ← REGISTER   │
│ 4. MIDIPortConnectSource(device)              ← CONNECT    │
│ 5. midiStream(from: device)                   ← CREATE     │
│ 6. Store continuation                         ← STORE      │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ RUNTIME (Continuous)                                        │
├─────────────────────────────────────────────────────────────┤
│ 1. Hardware sends MIDI bytes                                │
│ 2. CoreMIDI receives bytes                                  │
│ 3. CoreMIDI CALLS YOUR CALLBACK      ← THE TRIGGER!        │
│ 4. Callback wraps in Task                                   │
│ 5. Task marshals to actor                                   │
│ 6. Actor processes packets                                  │
│ 7. Actor yields to stream                                   │
│ 8. Stream buffer holds data                                 │
│ 9. for await loop receives data                             │
│ 10. UI updates                                              │
└─────────────────────────────────────────────────────────────┘
```

**The missing piece:** CoreMIDI is event-driven. You register a callback, and **CoreMIDI calls it** when data arrives. You don't call it yourself!

---

## Why This Was Confusing

The original documentation showed:
- ✅ How to create streams
- ✅ How to store continuations
- ✅ How to yield
- ❌ **WHO calls the callback that starts the chain**

Answer: **CoreMIDI does!** When hardware sends data, CoreMIDI's background thread calls your registered callback, which kicks off the entire chain.
