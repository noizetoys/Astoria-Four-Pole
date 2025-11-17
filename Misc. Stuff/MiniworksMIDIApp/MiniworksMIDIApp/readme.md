# MiniWorksMIDI

A complete SwiftUI application for macOS and iOS that provides a CoreMIDI SysEx interface for the Waldorf MiniWorks 4-Pole hardware synthesizer, with extensive educational documentation for MIDI beginners.

## Features

### CoreMIDI Integration
- **Full SysEx Support**: Send and receive System Exclusive messages with automatic buffering and fragmentation handling
- **Checksum Verification**: Configurable checksum modes (`mask7` and `complement7`) with automatic validation
- **Program Dump Protocol**: Request and parse individual program dumps or complete All Dump messages
- **MIDI Monitoring**: Real-time log of all MIDI traffic with timestamps and direction indicators
- **CC Control**: Send MIDI Control Change messages for real-time parameter adjustment

### Program Editor
- **Rotary Knobs**: Hardware-style knobs with 270° rotation range (8:30 to 5:00 position)
- **ADSR Visualizations**: Live graphical envelope displays for both VCF and VCA with direct manipulation
- **Direct Envelope Editing**: Click and drag directly on the ADSR curve to adjust parameters intuitively
- **Modulation Routing**: Complete mod source selectors for all modulation destinations
- **Live Update Mode**: Real-time parameter transmission with intelligent debouncing (150ms)

### CC Mapping System
- **Parameter Mapping**: Map any synthesizer parameter to any MIDI CC number (0-127)
- **Learn Mode**: Click a parameter and move a controller knob to auto-assign
- **Default Mappings**: Pre-configured General MIDI CC assignments
- **Real-time Control**: Control the MiniWorks from external MIDI controllers or DAW automation
- **Visual Feedback**: See incoming CC values in real-time

### Preset Management
- **JSON Storage**: Save and load presets to `Documents/MiniWorksPresets` directory
- **SysEx Export**: Generate `.syx` All Dump files for hardware backup
- **Preset Library**: Dropdown selector with sorted preset list
- **Parameter Recall**: Full program state restoration

## Understanding MIDI (For Beginners)

### What is MIDI?

MIDI (Musical Instrument Digital Interface) is **not audio**. It's a language that music devices use to communicate. Think of it like sheet music for computers:

- **Sheet music** tells a musician WHAT to play, not the actual sound
- **MIDI** tells a synthesizer WHAT to do, not the actual audio

Example: When you press middle C on a MIDI keyboard:
- The keyboard sends: "Note On, C4, velocity 64"
- The synthesizer receives this and generates the actual sound
- No audio travels over MIDI cables!

### Why Use MIDI?

1. **Tiny file sizes**: A 3-minute song might be only 50KB as MIDI (vs 30MB as audio)
2. **Editable**: Change the tempo, pitch, or instruments after recording
3. **Universal**: Works with any MIDI-compatible device, regardless of manufacturer
4. **Precise**: Control every parameter of your synthesizer with exact values

### MIDI Message Types

#### 1. Channel Messages (Real-time Performance)

**Note On/Off**: Play and stop notes
```
Example: 90 3C 64 (Note On, channel 1, middle C, medium velocity)
```

**Control Change (CC)**: Adjust knobs and sliders
```
Example: B0 4A 40 (CC on channel 1, filter cutoff, value 64)
```

**Program Change**: Switch presets
```
Example: C0 05 (Select program 5 on channel 1)
```

#### 2. System Exclusive (SysEx)

SysEx messages transfer complete data dumps. Think of them as "letters" between devices:

```
F0                    ← "Dear synthesizer," (start of message)
3E                    ← "This is Waldorf speaking" (manufacturer ID)
04                    ← "To the MiniWorks" (device ID)  
00                    ← "Here's a program dump" (command)
<program number>      ← "For slot 5" 
<parameter data...>   ← "With these settings..."
<checksum>            ← "Signature for verification"
F7                    ← "Sincerely, Computer" (end of message)
```

### Understanding Checksums

A **checksum** is like a seal on an envelope that proves the contents haven't been tampered with.

**How it works:**
1. **Sender** adds all the data bytes together and calculates a special number (checksum)
2. **Sender** adds the checksum to the end of the message
3. **Receiver** does the same calculation on the received data
4. **Receiver** compares: if checksums match, data is probably correct!

**Example:**
```
Data: [10, 20, 30, 40]
Sum: 10 + 20 + 30 + 40 = 100
Checksum: 100 & 0x7F = 100 (keep lower 7 bits)
Message: [10, 20, 30, 40, 100]

If receiver gets [10, 20, 99, 40, 100], the checksum won't match!
```

**Why two modes?**
- **mask7**: Simple, fast (just keep lower 7 bits)
- **complement7**: Better error detection (zero-sum property)

Different hardware versions might use different algorithms. If you get checksum errors, try switching modes!

### SysEx vs. CC: When to Use Which?

| Feature | SysEx | Control Change (CC) |
|---------|-------|---------------------|
| **Speed** | Slow (40+ bytes) | Fast (3 bytes) |
| **Use** | Save/load entire programs | Real-time knob tweaking |
| **Compatibility** | Device-specific format | Universal (all MIDI devices) |
| **Recording** | Not recordable in most DAWs | Fully recordable |
| **Best for** | Backups, preset transfer | Live performance, automation |

**Rule of thumb:**
- Use **SysEx** to save/load complete patches
- Use **CC** to control parameters in real-time during performance

## Project Structure

```
MiniWorksMIDI/
├── MiniWorksMIDIApp.swift      # App entry point
├── ContentView.swift            # Main container view
├── Utils.swift                  # Checksum and utility functions
├── ModSource.swift              # Modulation source enum
├── Debouncer.swift              # Parameter change debouncer
├── PresetStore.swift            # Preset storage manager
├── ProgramModel.swift           # Synthesizer program model
├── KnobView.swift               # Rotary knob control
├── ADSRView.swift               # Interactive ADSR envelope editor
├── MIDIManager.swift            # CoreMIDI client with extensive docs
├── ProgramEditorView.swift     # Main editor interface
├── MIDIView.swift               # MIDI setup and log view
└── CCMappingView.swift          # CC mapping interface
```

## SysEx Protocol (Waldorf MiniWorks)

### Message Formats

**Program Dump Request:**
```
F0 3E 04 01 <program#> F7
│  │  │  │   │
│  │  │  │   └─ Program number (0-127)
│  │  │  └───── Command: 0x01 = "Please send me this program"
│  │  └──────── Device ID: 0x04 = MiniWorks
│  └─────────── Manufacturer: 0x3E = Waldorf
└────────────── SysEx start
```

**Program Dump Response:**
```
F0 3E 04 00 <program#> <param1> <param2> ... <paramN> <checksum> F7
│  │  │  │   │          └─────────────────────────────┘ │
│  │  │  │   │                     │                      │
│  │  │  │   │                 Parameters             Checksum
│  │  │  │   └─ Program slot
│  │  │  └───── Command: 0x00 = "Here's a program"
│  │  └──────── Device ID
│  └─────────── Manufacturer ID
└────────────── SysEx start
```

**All Dump Request:**
```
F0 3E 04 02 F7
         │
         └─ Command: 0x02 = "Send me ALL programs"
```

**All Dump Response:**
```
Multiple Program Dumps concatenated (128 programs)
```

### Checksum Algorithms

**Mask 7-bit (`mask7`):**
```swift
// Add all parameter bytes, keep lower 7 bits
checksum = (sum of all bytes) & 0x7F

Example:
Data: [64, 100, 127]
Sum: 291
Checksum: 291 & 0x7F = 35
```

**Complement 7-bit (`complement7`):**
```swift
// Two's complement (negate), keep lower 7 bits
checksum = (-(sum of all bytes)) & 0x7F

Example:
Data: [64, 100, 127]
Sum: 291
Checksum: (-291) & 0x7F = 93

// Verification (zero-sum):
(64 + 100 + 127 + 93) & 0x7F = 0 ✓
```

## Usage Guide

### Initial Setup

1. **Launch MiniWorksMIDI**
2. **Navigate to MIDI Setup tab**
3. **Select your MiniWorks** as both Source and Destination
4. **Choose checksum mode** (try `mask7` first, switch to `complement7` if errors occur)
5. **Click Connect**

### Editing Programs

**Method 1: Rotary Knobs**
1. Navigate to **Program Editor** tab
2. Click and drag vertically on any knob
3. Up = increase, Down = decrease
4. Enable **Live Update** for instant transmission

**Method 2: Direct ADSR Manipulation**
1. Click directly on the envelope curve
2. Drag horizontally to adjust time parameters (Attack, Decay, Release)
3. Drag vertically to adjust sustain level
4. Watch the knobs update in real-time!

**Method 3: MIDI Controller (CC)**
1. Navigate to **CC Mapping** tab
2. Enable **Learn Mode**
3. Click a parameter name
4. Move a knob on your MIDI controller
5. Mapping is automatically created!

### Saving Presets

1. Adjust parameters to create your sound
2. Click **Save**
3. Enter a preset name
4. Preset is saved to `Documents/MiniWorksPresets`

### Loading Presets

1. Click the preset dropdown
2. Select a preset from the list
3. All parameters update instantly

### Backing Up to Hardware

1. Click **Export**
2. Choose a filename (`.syx` extension)
3. File contains all 128 programs
4. Use SysEx software or DAW to load back to synthesizer

### Requesting Programs from Hardware

**Single Program:**
1. Click **Request Program Dump**
2. Synthesizer sends current program
3. Editor updates with received parameters

**All Programs:**
1. Click **Request All Dump**
2. Synthesizer sends all 128 programs (takes ~10 seconds)
3. Watch MIDI log for progress

## CoreMIDI Architecture Explained

```
┌─────────────────────────────────────────────────────────┐
│                    Your Computer                        │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │              MiniWorksMIDI App                     │ │
│  │  ┌──────────────┐         ┌──────────────┐       │ │
│  │  │ Input Port   │         │ Output Port  │       │ │
│  │  │ (Receives)   │         │ (Sends)      │       │ │
│  │  └───────┬──────┘         └──────┬───────┘       │ │
│  │          │                       │                │ │
│  └──────────┼───────────────────────┼────────────────┘ │
│             │                       │                  │
│  ┌──────────▼──────┐     ┌──────────▼──────┐         │
│  │  Source         │     │  Destination    │         │
│  │  Endpoint       │     │  Endpoint       │         │
│  └──────────┬──────┘     └──────┬──────────┘         │
│             │                   │                     │
└─────────────┼───────────────────┼─────────────────────┘
              │                   │
         (MIDI Cable)         (MIDI Cable)
              │                   │
┌─────────────▼───────────────────▼─────────────────────┐
│              Hardware Synthesizer                      │
│         (Waldorf MiniWorks 4-Pole)                    │
└────────────────────────────────────────────────────────┘
```

**Message Flow:**

**Sending (App → Hardware):**
1. User adjusts knob
2. App creates MIDI message
3. Output Port sends to Destination Endpoint
4. Hardware receives and updates parameter

**Receiving (Hardware → App):**
1. Hardware sends MIDI message
2. Source Endpoint receives
3. Input Port delivers to app
4. App processes and updates UI

## Troubleshooting

### No MIDI Devices Appear

**Possible causes:**
- Synthesizer is powered off
- MIDI interface not connected
- Drivers not installed

**Solutions:**
1. Check power and cables
2. Open **Audio MIDI Setup** (macOS) to verify device recognition
3. Click **Refresh** in MiniWorksMIDI

### Checksum Errors

**Symptoms:**
- "Checksum verification failed" in log
- Red error messages
- Parameters don't update

**Solutions:**
1. Try switching checksum mode (`mask7` ↔ `complement7`)
2. Check MIDI cables for damage
3. Reduce cable length if possible
4. Check for electrical interference sources
5. Consult your MiniWorks manual for correct checksum algorithm

### Live Update Lag

**This is intentional!**
- The 150ms debounce prevents MIDI flooding
- Dragging a knob generates hundreds of values per second
- Without debouncing, MIDI buffer would overflow

**Solutions:**
- Disable **Live Update** for instant transmission
- Use **Send to Hardware** button for immediate updates
- Adjust debounce time in `Debouncer.swift` if needed

### Parameters Not Updating

**Check:**
1. Correct destination selected?
2. Connection status shows "Connected"?
3. MIDI log shows successful transmission (green arrow up)?
4. Hardware in correct receive mode?

**Debug:**
- Watch MIDI log for sent messages
- Try **Request Program Dump** to verify two-way communication
- Test with a single parameter (e.g., volume)

### CC Not Working

**Common issues:**
1. No CC mapping assigned
2. Wrong MIDI channel (hardware expects channel 1 but sends on 2)
3. Hardware doesn't support CC control for that parameter

**Solutions:**
1. Check CC Mapping tab for assigned parameters
2. Verify MIDI channel matches hardware
3. Consult hardware manual for CC implementation

## Educational Resources

### Want to Learn More?

The code contains extensive comments explaining:
- How MIDI messages are structured
- Why checksums are necessary
- How SysEx fragmentation works
- CoreMIDI architecture and packet handling
- The difference between SysEx and CC

**Recommended files for learning:**
- `MIDIManager.swift` - Complete MIDI protocol explanation
- `Utils.swift` - Checksum algorithms with examples
- `CCMappingView.swift` - CC vs. SysEx comparison

### Experiment!

Try these to understand MIDI better:

1. **Watch the log** while adjusting parameters
2. **Enable Learn Mode** and map a parameter
3. **Request a program dump** and observe the hex data
4. **Export a .syx file** and examine it in a hex editor
5. **Switch checksum modes** and see how it affects verification

### Key Concepts to Remember

1. **MIDI is instructions, not audio**
2. **SysEx for complete programs, CC for real-time control**
3. **Checksums detect transmission errors**
4. **Fragmentation allows large messages to be split**
5. **Debouncing prevents MIDI flooding**

## Requirements

- **macOS**: 13.0+ (Ventura)
- **iOS**: 16.0+
- **Xcode**: 15.0+
- **Swift**: 5.9+

## Building

1. Open the project in Xcode
2. Select your target device (Mac, iPhone, or iPad)
3. Build and run (⌘R)

The project requires no external dependencies and uses only system frameworks:
- SwiftUI
- CoreMIDI
- Foundation

## MIDI Hardware Connection

### macOS
Connect your MiniWorks synthesizer via:
- USB MIDI interface
- Built-in MIDI (if available)
- Network MIDI session

### iOS
Connect via:
- Lightning to USB Camera Adapter + USB MIDI interface
- Network MIDI session

## Advanced Topics

### Custom Checksum Algorithms

If your hardware uses a different checksum algorithm, modify `calculateChecksum` in `Utils.swift`:

```swift
func calculateChecksum(_ data: [UInt8], mode: ChecksumMode) -> UInt8 {
    let sum = data.reduce(0) { $0 &+ Int($1) }
    
    switch mode {
    case .custom:
        // Your algorithm here
        return UInt8(yourCalculation & 0x7F)
    }
}
```

### Adjusting Debounce Time

In `Debouncer.swift`, change the delay parameter:

```swift
init(delay: TimeInterval = 0.15) {  // 150ms default
    self.delay = delay
}
```

Shorter = more responsive but more MIDI traffic
Longer = less responsive but more efficient

### Adding New Parameters

1. Add to `ProgramModel.swift`
2. Add to `CCMapper.Parameter` enum
3. Add UI controls in `ProgramEditorView.swift`
4. Update SysEx encoding/decoding

## License

This is a demonstration project showing CoreMIDI SysEx implementation patterns. Adapt freely for your own synthesizer control applications.

---

**Built for synthesizer enthusiasts who want to understand MIDI from the ground up!**
