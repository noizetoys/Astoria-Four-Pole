# Display Link Platform Differences - Quick Reference

## iOS vs macOS Display Links

### iOS: CADisplayLink
```swift
#if os(iOS)
// Simple, object-oriented API
let displayLink = CADisplayLink(target: self, selector: #selector(callback))
displayLink.add(to: .main, forMode: .common)

// To stop:
displayLink.invalidate()
#endif
```

**Characteristics:**
- Easy to use
- Target/selector pattern
- Runs on main thread
- Add to specific run loop mode
- Pauses automatically when view off-screen

### macOS: CVDisplayLink
```swift
#elseif os(macOS)
// C-based Core Video API
var link: CVDisplayLink?
CVDisplayLinkCreateWithActiveCGDisplays(&link)

// Set callback (fires on background thread!)
CVDisplayLinkSetOutputCallback(link!, { (link, now, output, flagsIn, flagsOut, context) -> CVReturn in
    let view = Unmanaged<MyView>.fromOpaque(context!).takeUnretainedValue()
    
    // CRITICAL: Must dispatch to main thread
    DispatchQueue.main.async {
        view.update()
    }
    
    return kCVReturnSuccess
}, Unmanaged.passUnretained(self).toOpaque())

CVDisplayLinkStart(link!)

// To stop:
CVDisplayLinkStop(link!)
#endif
```

**Characteristics:**
- C-based API (more complex)
- Function pointer callback
- **Runs on background thread** (must dispatch to main)
- Per-display synchronization
- More manual lifecycle management

## Key Differences Summary

| Feature | iOS (CADisplayLink) | macOS (CVDisplayLink) |
|---------|--------------------|-----------------------|
| API Style | Objective-C | C |
| Thread | Main thread | Background thread ⚠️ |
| Setup | Simple (2 lines) | Complex (5+ lines) |
| Callback | Selector | Function pointer |
| Cleanup | `.invalidate()` | `CVDisplayLinkStop()` |
| Auto-pause | Yes | No |
| Display-specific | No | Yes (can choose display) |

## Common Pitfalls

### ❌ Don't: Update UI directly on macOS callback

```swift
CVDisplayLinkSetOutputCallback(link, { (...) -> CVReturn in
    view.layer?.position = newPosition  // CRASH! Not on main thread
    return kCVReturnSuccess
}, ...)
```

### ✅ Do: Dispatch to main thread

```swift
CVDisplayLinkSetOutputCallback(link, { (...) -> CVReturn in
    DispatchQueue.main.async {
        view.layer?.position = newPosition  // Safe
    }
    return kCVReturnSuccess
}, ...)
```

### ❌ Don't: Forget to stop CVDisplayLink

```swift
deinit {
    // Missing: CVDisplayLinkStop(displayLink!)
    // Will continue firing callbacks even after view is deallocated!
}
```

### ✅ Do: Always stop in deinit

```swift
deinit {
    #if os(macOS)
    if let displayLink = displayLink {
        CVDisplayLinkStop(displayLink)
    }
    #endif
}
```

## Why Use CVDisplayLink on macOS?

### Benefits:
1. **Screen-synchronized**: No tearing, perfect 60/120 Hz
2. **Per-display**: Can sync to specific monitor
3. **Efficient**: Hardware-level timing
4. **ProMotion support**: Automatically uses 120 Hz on compatible Macs

### Alternatives:
- `Timer` - Not synchronized, variable frame rate
- `DispatchQueue` - Better than Timer, but still not synchronized
- `CVDisplayLink` - Best option for smooth animation

## Unified Wrapper Pattern

Here's how to create a clean abstraction:

```swift
class DisplayLinkWrapper {
    #if os(iOS)
    private var displayLink: CADisplayLink?
    #elseif os(macOS)
    private var displayLink: CVDisplayLink?
    #endif
    
    private let callback: () -> Void
    
    init(callback: @escaping () -> Void) {
        self.callback = callback
    }
    
    func start() {
        #if os(iOS)
        displayLink = CADisplayLink(target: self, selector: #selector(fire))
        displayLink?.add(to: .main, forMode: .common)
        #elseif os(macOS)
        var link: CVDisplayLink?
        CVDisplayLinkCreateWithActiveCGDisplays(&link)
        displayLink = link
        
        if let displayLink = displayLink {
            CVDisplayLinkSetOutputCallback(displayLink, { (_, _, _, _, _, context) -> CVReturn in
                let wrapper = Unmanaged<DisplayLinkWrapper>.fromOpaque(context!).takeUnretainedValue()
                DispatchQueue.main.async {
                    wrapper.callback()
                }
                return kCVReturnSuccess
            }, Unmanaged.passUnretained(self).toOpaque())
            
            CVDisplayLinkStart(displayLink)
        }
        #endif
    }
    
    func stop() {
        #if os(iOS)
        displayLink?.invalidate()
        displayLink = nil
        #elseif os(macOS)
        if let displayLink = displayLink {
            CVDisplayLinkStop(displayLink)
        }
        displayLink = nil
        #endif
    }
    
    #if os(iOS)
    @objc private func fire() {
        callback()
    }
    #endif
    
    deinit {
        stop()
    }
}

// Usage (same on both platforms):
let link = DisplayLinkWrapper {
    // Update animation
}
link.start()
```

## Performance Characteristics

### Frame Timing

Both provide excellent frame timing:

```
iOS (CADisplayLink):
Frame 1: 16.67ms ✓
Frame 2: 16.67ms ✓
Frame 3: 16.67ms ✓
Average: 60.0 FPS

macOS (CVDisplayLink):
Frame 1: 16.66ms ✓
Frame 2: 16.67ms ✓
Frame 3: 16.66ms ✓
Average: 60.0 FPS
```

### CPU Usage

With proper implementation, both are equally efficient:

| Implementation | CPU Usage |
|---------------|-----------|
| Timer.scheduledTimer | 15-20% |
| CADisplayLink (iOS) | 3-5% |
| CVDisplayLink (macOS) | 3-5% |

The dispatch overhead on macOS is negligible (< 0.1%).

## Advanced: Multi-Display Support (macOS Only)

CVDisplayLink can sync to specific displays:

```swift
// Get the display for the window
let displayID = NSScreen.main?.displayID ?? 0

// Create display link for that specific display
var link: CVDisplayLink?
CVDisplayLinkCreateWithCGDisplay(displayID, &link)

// This is useful when:
// - App spans multiple monitors
// - Different refresh rates (60Hz + 120Hz)
// - User drags window between displays
```

## Testing

### Verify Synchronization

```swift
var lastTime: CFTimeInterval = 0
var frameCount = 0

func callback() {
    let currentTime = CACurrentMediaTime()
    let delta = currentTime - lastTime
    
    print("Frame \(frameCount): \(delta * 1000)ms")
    
    lastTime = currentTime
    frameCount += 1
}

// Good output:
// Frame 1: 16.67ms
// Frame 2: 16.67ms
// Frame 3: 16.67ms

// Bad output (Timer):
// Frame 1: 17.23ms
// Frame 2: 15.89ms
// Frame 3: 18.45ms
```

## Conclusion

Use the wrapper pattern shown above to hide platform differences and get the benefits of display-synchronized animation on both iOS and macOS.

Key takeaways:
- ✅ Both provide 60+ FPS synchronized animation
- ⚠️ macOS requires dispatching to main thread
- ✅ Wrapper pattern makes code portable
- ✅ Both are highly performant (3-5% CPU)
