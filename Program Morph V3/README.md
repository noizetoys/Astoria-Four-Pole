# MiniWorks Program Morph System

A comprehensive Swift/SwiftUI solution for smoothly morphing between two MIDI synthesizer programs by interpolating parameter values and sending CC messages over time.

## Overview

The Program Morph system allows you to create smooth transitions between two different synthesizer patches. It automatically interpolates all numeric parameters and sends CC messages at a configurable rate, perfect for live performance, sound design exploration, or creating evolving soundscapes.

## Features

### Core Functionality
- ✨ **Automatic Morphing**: Timer-based interpolation with configurable duration (0.5-10 seconds)
- 🎛️ **Manual Control**: Direct position control with real-time CC sending
- 📊 **Parameter Visualization**: See which parameters change and by how much
- 🔄 **Bidirectional**: Morph from A to B, B to A, or swap programs instantly
- ⚡ **Configurable Rate**: Update rate from 10-60 Hz for smooth transitions
- 🎵 **Smart Parameter Handling**: Only morphs numeric parameters, skips mod sources and switches

### UI Components
- **MorphControlView**: Simple, clean interface for basic morphing
- **AdvancedMorphView**: Full-featured UI with parameter visualization
- **Custom Slider**: Gradient slider with smooth drag interaction
- **Parameter Rows**: Visual comparison of parameter changes

## Architecture

```
ProgramMorph (Core Model)
├─ Source Program
├─ Destination Program
├─ Morph Position (0.0 - 1.0)
├─ Timer Management
└─ CC Notification System

UI Layer
├─ MorphControlView (Basic)
└─ AdvancedMorphView (Advanced)

Integration
└─ NotificationCenter for CC messages
```

## Installation

1. Add all files to your Xcode project:
   - `ProgramMorph.swift` (core model)
   - `MorphControlView.swift` (basic UI)
   - `AdvancedMorphView.swift` (advanced UI)
   - `MorphUsageExamples.swift` (examples)

2. Ensure your `MiniWorksProgram` class has the `allParameters` computed property (included in the implementation)

3. Connect to your MIDI system by observing the `.programParameterUpdated` notification

## Quick Start

### Basic Usage

```swift
// Create two programs
let source = MiniWorksProgram()
source.programName = "Smooth Pad"
source.cutoff.setValue(40)

let destination = MiniWorksProgram()
destination.programName = "Bright Lead"
destination.cutoff.setValue(120)

// Create morph controller
let morph = ProgramMorph(source: source, destination: destination)

// Use in SwiftUI
MorphControlView(morph: morph)
```

### Programmatic Control

```swift
// Start automatic morph to destination (2 second duration by default)
morph.startMorph()

// Stop morphing
morph.stopMorph()

// Set specific position manually
morph.setMorphPosition(0.5) // 50% between source and destination

// Configure duration and rate
morph.morphDuration = 4.0  // 4 seconds
morph.updateRate = 30.0     // 30 Hz

// Jump to source or destination
morph.resetToSource()
morph.jumpToDestination()

// Swap programs (also inverts position)
morph.swapPrograms()
```

### Integration with MIDI

Listen for parameter updates in your MIDI manager:

```swift
class MIDIManager {
    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleParameterUpdate),
            name: .programParameterUpdated,
            object: nil
        )
    }
    
    @objc func handleParameterUpdate(_ notification: Notification) {
        guard let type = notification.userInfo?[SysExConstant.parameterType] as? MiniWorksParameter,
              let value = notification.userInfo?[SysExConstant.parameterValue] as? UInt8 else {
            return
        }
        
        // Send MIDI CC message
        sendCC(cc: type.ccValue, value: value, channel: deviceChannel)
    }
}
```

## How It Works

### Interpolation

The system interpolates between parameter values using the formula:
```
currentValue = sourceValue + (destValue - sourceValue) * morphPosition
```

With an ease-in-out curve applied for smooth acceleration/deceleration:
```swift
// Ease-in-out cubic
func easeInOutCubic(_ t: Double) -> Double {
    if t < 0.5 {
        return 4 * t * t * t
    } else {
        let f = (2 * t - 2)
        return 1 + f * f * f / 2
    }
}
```

### Timer-Based Updates

When automatic morphing is active:
1. Timer fires at configured rate (default 30 Hz)
2. Elapsed time is calculated
3. Progress is computed and eased
4. Morph position is updated
5. All parameters are interpolated
6. CC notifications are sent
7. Process repeats until complete

### Parameter Selection

Only specific parameters are morphed:
- ✅ All envelope parameters (ADSR)
- ✅ Cutoff, Resonance, Volume, Panning
- ✅ LFO Speed and modulation amounts
- ✅ Gate Time
- ❌ Modulation sources (discrete selections)
- ❌ Trigger source/mode (discrete selections)
- ❌ LFO Shape (discrete selection)

## UI Components

### MorphControlView

Simple interface with:
- Program labels (source/destination)
- Swap button
- Position slider with visual feedback
- Control buttons (Reset, Morph/Stop, Jump)
- Settings (duration, update rate, CC toggle)

### AdvancedMorphView

Full-featured interface with:
- All features from basic view
- Morph curve selection (linear, ease-in, ease-out, ease-in-out)
- Parameter visualization showing:
  - Parameter name
  - Source value (blue marker)
  - Destination value (purple marker)
  - Current morphed value (green dot)
  - Visual bar showing the transition
- Show/hide details toggle

## Performance Considerations

### Update Rate

- **10-20 Hz**: Lower CPU usage, slightly choppy
- **30 Hz**: Recommended balance (default)
- **40-60 Hz**: Smoothest but higher CPU usage

### Parameter Count

With 29 parameters:
- 30 Hz = 870 parameter calculations/second
- Each update sends ~20-25 CC messages (only changed numeric parameters)

### Timer Accuracy

Using `Timer.scheduledTimer` provides:
- ~±2ms accuracy on modern Macs
- Adequate for MIDI CC sending
- Main thread execution (appropriate for UI updates)

## Advanced Examples

### Ping-Pong Morph

```swift
func pingPongMorph() {
    morph.startMorph(to: 1.0)
    
    DispatchQueue.main.asyncAfter(deadline: .now() + morph.morphDuration + 0.5) {
        self.morph.startMorph(to: 0.0)
    }
}
```

### Preset System

```swift
struct MorphPreset {
    let name: String
    let sourceProgram: MiniWorksProgram
    let destinationProgram: MiniWorksProgram
    let duration: Double
}

// Create interesting morphs
let filterSweep = MorphPreset(
    name: "Filter Sweep",
    sourceProgram: closedFilterProgram,
    destinationProgram: openFilterProgram,
    duration: 4.0
)
```

### Performance X/Y Pad

```swift
// Use drag gesture for real-time control
.gesture(
    DragGesture(minimumDistance: 0)
        .onChanged { value in
            let position = value.location.x / geometry.size.width
            morph.setMorphPosition(position)
        }
)
```

## Technical Details

### Thread Safety

- `@Observable` macro provides thread-safe access
- `@MainActor` used for notification posting
- Timer runs on main thread for UI updates

### Memory Management

- Weak self references in timer closures
- Proper timer invalidation
- No retain cycles

### Error Handling

- Guards against mismatched parameter counts
- Validates parameter types match
- Clamps interpolated values to 0-127 range

## Customization

### Custom Easing Functions

Add to `ProgramMorph`:

```swift
func easeLinear(_ t: Double) -> Double {
    return t
}

func easeInQuad(_ t: Double) -> Double {
    return t * t
}

func easeOutQuad(_ t: Double) -> Double {
    return t * (2 - t)
}
```

### Filter Specific Parameters

```swift
extension ProgramMorph {
    var morphableParameters: [ProgramParameter] {
        // Return only parameters you want to morph
        // Customize based on your needs
    }
}
```

### Custom UI

Build your own interface using the `ProgramMorph` model:

```swift
struct CustomMorphView: View {
    @State var morph: ProgramMorph
    
    var body: some View {
        VStack {
            Text("Position: \(morph.morphPosition)")
            
            Button("Morph") {
                morph.startMorph()
            }
        }
    }
}
```

## Troubleshooting

### CC Messages Not Sending

1. Check `morph.sendCCMessages` is `true`
2. Verify NotificationCenter observer is registered
3. Ensure MIDI connection is active

### Jerky Morphing

1. Increase `updateRate` (try 40-60 Hz)
2. Check for main thread blocking
3. Verify timer is running

### Parameters Not Changing

1. Verify source and destination programs are different
2. Check parameter types match
3. Ensure parameter is in `allParameters` array

### High CPU Usage

1. Decrease `updateRate` to 20-30 Hz
2. Reduce morph duration
3. Only morph changed parameters

## Future Enhancements

Possible additions:
- [ ] Multi-point morphing (A → B → C)
- [ ] Curve editing for custom easing
- [ ] Automation recording/playback
- [ ] MIDI CC input for position control
- [ ] Morph presets with save/load
- [ ] LFO-based automatic morphing
- [ ] Randomization features
- [ ] Undo/redo support

## Credits

Created for the Astoria Filter Editor / MiniWorks MIDI editor project.

## License

Include your license information here.
