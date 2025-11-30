# Program Morphing: Complete Implementation Guide

## Quick Reference: Which Implementation to Use?

| Implementation | Best For | Key Features |
|----------------|----------|--------------|
| **ProgramMorph** | Simple projects, learning | Basic morphing, no optimization |
| **ProgramMorphOptimized** | Performance-critical apps | Skips unchanged params, 60% fewer messages |
| **ProgramMorphFiltered** | Production apps (RECOMMENDED) | Full control, groups, discrete handling |

---

## Implementation Comparison

### 1. ProgramMorph (Basic)

**Files**: `ProgramMorph.swift`, `MorphControlView.swift`

**What it does**:
- ✅ Basic timer-based morphing
- ✅ Interpolates all continuous parameters
- ✅ Excludes discrete parameters (mod sources, triggers)
- ✅ Simple, easy to understand
- ❌ Processes all 29 parameters every update
- ❌ Sends CCs even for unchanged parameters
- ❌ No parameter grouping
- ❌ No discrete parameter strategy options

**When to use**:
- Learning how morphing works
- Simple single-parameter morphs
- Prototyping
- When simplicity > efficiency

**Code**:
```swift
let morph = ProgramMorph(source: pad, destination: lead)
morph.startMorph()
```

---

### 2. ProgramMorphOptimized (Performance)

**Files**: `ProgramMorphOptimized.swift`

**What it does**:
- ✅ All features of ProgramMorph
- ✅ Pre-calculates which parameters differ
- ✅ Only processes changed parameters
- ✅ Caches last-sent values
- ✅ Optional value change threshold
- ✅ Detailed statistics
- ✅ 60-90% reduction in messages for typical morphs
- ❌ No parameter grouping
- ❌ No discrete parameter strategies

**When to use**:
- Performance matters
- Many simultaneous morphs
- Reducing MIDI bandwidth
- Want optimization statistics
- Most parameters don't change between patches

**Code**:
```swift
let morph = ProgramMorphOptimized(source: pad, destination: lead)
morph.startMorph()

// Check efficiency
print(morph.statistics.description)
// Shows: 12/29 parameters changing, 58% optimization
```

---

### 3. ProgramMorphFiltered (Production - RECOMMENDED)

**Files**: `ProgramMorphFiltered.swift`, `MorphParameterControl.swift`, `MorphFilterControlView.swift`

**What it does**:
- ✅ All features of ProgramMorphOptimized
- ✅ Parameter groups (VCF, VCA, filters, etc.)
- ✅ Individual parameter enable/disable
- ✅ Five discrete parameter strategies
- ✅ Quick presets (envelopes-only, filters-only, etc.)
- ✅ Optional inclusion of discrete parameters
- ✅ Comprehensive UI for user control
- ✅ Advanced configuration options

**When to use**:
- Production applications (RECOMMENDED)
- User needs control over what morphs
- Want to morph specific groups
- Need discrete parameter handling
- Professional music applications

**Code**:
```swift
// Quick preset
let config = MorphFilterConfig.filtersOnly
let morph = ProgramMorphFiltered(source: pad, destination: lead, config: config)

// Custom configuration
let config = MorphFilterConfig()
config.enabledGroups = [.vcfEnvelope, .filters]
config.modulationSourceStrategy = .snapAtHalf
let morph = ProgramMorphFiltered(source: pad, destination: lead, config: config)

// With UI
MorphFilterControlView(morph: morph)
```

---

## Feature Matrix

| Feature | Basic | Optimized | Filtered |
|---------|-------|-----------|----------|
| **Core Morphing** |
| Timer-based updates | ✅ | ✅ | ✅ |
| Continuous param interpolation | ✅ | ✅ | ✅ |
| Ease-in-out curves | ✅ | ✅ | ✅ |
| Configurable duration | ✅ | ✅ | ✅ |
| Configurable update rate | ✅ | ✅ | ✅ |
| Start/stop control | ✅ | ✅ | ✅ |
| Manual position control | ✅ | ✅ | ✅ |
| Swap programs | ✅ | ✅ | ✅ |
| **Optimization** |
| Skip unchanged parameters | ❌ | ✅ | ✅ |
| Cache last sent values | ❌ | ✅ | ✅ |
| Value change threshold | ❌ | ✅ | ❌* |
| Statistics | ❌ | ✅ | ✅ |
| **Parameter Control** |
| Discrete param exclusion | ✅ | ✅ | ✅ |
| Parameter grouping | ❌ | ❌ | ✅ |
| Individual param control | ❌ | ❌ | ✅ |
| Group presets | ❌ | ❌ | ✅ |
| **Discrete Handling** |
| Ignore strategy | ✅ | ✅ | ✅ |
| Snap at 50% | ❌ | ❌ | ✅ |
| Snap at threshold | ❌ | ❌ | ✅ |
| Use source/dest | ❌ | ❌ | ✅ |
| Optional discrete inclusion | ❌ | ❌ | ✅ |
| **UI** |
| Basic control view | ✅ | ❌ | ✅ |
| Advanced control view | ✅ | ❌ | ❌ |
| Filter configuration UI | ❌ | ❌ | ✅ |
| Statistics display | ❌ | ❌ | ✅ |

*Could be added easily if needed

---

## Discrete Parameter Handling

### The Problem

These parameters don't interpolate:
- **Modulation sources**: .off, .lfo, .envelope, etc.
- **LFO shape**: .sine, .triangle, .square, etc.
- **Trigger source**: .audio, .midi, .all
- **Trigger mode**: .single, .multi

What does "50% between sine and square wave" mean? 🤔

### The Solution: Five Strategies

**1. Ignore (DEFAULT)**
```swift
// Don't change discrete parameters
// Source value stays throughout morph
strategy: .ignore
```

**2. Snap at 50%**
```swift
// Switch from source to dest at midpoint
0-49%: source value
50-100%: dest value
strategy: .snapAtHalf
```

**3. Snap at Threshold**
```swift
// Switch at custom position
0-74%: source value
75-100%: dest value
strategy: .snapAtThreshold
threshold: 0.75
```

**4. Use Source**
```swift
// Always keep source value
strategy: .useSource
```

**5. Use Destination**
```swift
// Jump to dest immediately
strategy: .useDestination
```

### Default Behavior

All implementations **exclude discrete parameters by default**:
- ✅ Modulation sources: EXCLUDED
- ✅ LFO shape: EXCLUDED
- ✅ Trigger source: EXCLUDED
- ✅ Trigger mode: EXCLUDED

Only `ProgramMorphFiltered` allows you to optionally include them with strategies.

---

## Parameter Groups

### Available Groups

```swift
.vcfEnvelope     // Filter ADSR + cutoff amount
.vcaEnvelope     // Amplitude ADSR + volume amount
.vcfModulation   // Cutoff & resonance mod amounts
.vcaModulation   // Volume & panning mod amounts
.lfo             // LFO speed & speed mod amount
.filters         // Cutoff & resonance
.output          // Volume & panning
.timing          // Gate time
```

### Quick Presets

```swift
MorphFilterConfig.allParameters      // Everything
MorphFilterConfig.envelopesOnly      // VCF + VCA envelopes
MorphFilterConfig.filtersOnly        // Filters + VCF mod
MorphFilterConfig.vcfOnly            // All VCF-related
MorphFilterConfig.vcaOnly            // All VCA-related
MorphFilterConfig.modulationOnly     // All mod amounts + LFO
```

### Usage Examples

```swift
// Envelope morph only
let config = MorphFilterConfig.envelopesOnly
let morph = ProgramMorphFiltered(source: p1, destination: p2, config: config)

// Custom combination
let config = MorphFilterConfig()
config.enabledGroups = [.filters, .vcfModulation]
config.disabledParameters.insert(.resonance)  // Exclude resonance specifically
```

---

## Performance Comparison

### Simple Filter Sweep (3 parameters change)

| Implementation | Messages/Update | Messages/Sec (30Hz) | Bandwidth | CPU |
|----------------|-----------------|---------------------|-----------|-----|
| Basic | 29 | 870 | 2,610 bytes/sec | High |
| Optimized | 3 | 90 | 270 bytes/sec | Low |
| Filtered | 3 | 90 | 270 bytes/sec | Low |

**Savings**: 90% fewer messages

### Envelope Morph (10 parameters change)

| Implementation | Messages/Update | Messages/Sec (30Hz) | Bandwidth | CPU |
|----------------|-----------------|---------------------|-----------|-----|
| Basic | 29 | 870 | 2,610 bytes/sec | High |
| Optimized | 10 | 300 | 900 bytes/sec | Medium |
| Filtered | 10 | 300 | 900 bytes/sec | Medium |

**Savings**: 65% fewer messages

### Complete Patch (All 29 parameters change)

| Implementation | Messages/Update | Messages/Sec (30Hz) | Bandwidth | CPU |
|----------------|-----------------|---------------------|-----------|-----|
| Basic | 29 | 870 | 2,610 bytes/sec | High |
| Optimized | 29 | 870 | 2,610 bytes/sec | High |
| Filtered | 29 | 870 | 2,610 bytes/sec | High |

**Savings**: 0% (but no harm done)

---

## Migration Guide

### From Basic to Optimized

```swift
// Before
let morph = ProgramMorph(source: p1, destination: p2)

// After
let morph = ProgramMorphOptimized(source: p1, destination: p2)

// That's it! API is identical
```

### From Basic to Filtered

```swift
// Before
let morph = ProgramMorph(source: p1, destination: p2)

// After (with defaults - same behavior)
let morph = ProgramMorphFiltered(source: p1, destination: p2)

// After (with customization)
let config = MorphFilterConfig.filtersOnly
let morph = ProgramMorphFiltered(source: p1, destination: p2, config: config)
```

### From Optimized to Filtered

```swift
// Before
let morph = ProgramMorphOptimized(source: p1, destination: p2)

// After
let morph = ProgramMorphFiltered(source: p1, destination: p2)

// Get same optimization + filtering capabilities
```

---

## Recommendations by Use Case

### Learning / Prototyping
→ **ProgramMorph** (Basic)
- Simplest to understand
- Good for learning concepts
- Easy to modify

### Performance-Critical Desktop App
→ **ProgramMorphOptimized**
- Significant bandwidth reduction
- Detailed statistics
- Production-ready

### Professional Music Application
→ **ProgramMorphFiltered** ⭐ RECOMMENDED
- Full user control
- Parameter grouping
- Discrete handling
- Comprehensive UI
- Best overall choice

### iOS Music App
→ **ProgramMorphFiltered**
- Users expect parameter control
- Grouping presets useful
- Professional feature set

### Simple Utility Tool
→ **ProgramMorph** (Basic)
- Keep it simple
- Fewer dependencies
- Easier maintenance

---

## Common Patterns

### Pattern 1: Filter Sweep

```swift
let config = MorphFilterConfig()
config.enabledGroups = [.filters, .vcfModulation]

let morph = ProgramMorphFiltered(source: closedFilter, destination: openFilter, config: config)
morph.morphDuration = 4.0
morph.startMorph()
```

### Pattern 2: Envelope Evolution

```swift
let config = MorphFilterConfig.envelopesOnly

let morph = ProgramMorphFiltered(source: shortPluck, destination: longPad, config: config)
morph.morphDuration = 8.0
morph.startMorph()
```

### Pattern 3: Complete Transformation

```swift
let morph = ProgramMorphFiltered(source: ambient, destination: aggressive)
morph.morphDuration = 10.0
morph.startMorph()
// Morphs all continuous parameters
```

### Pattern 4: Manual X/Y Control

```swift
let morph = ProgramMorphFiltered(source: p1, destination: p2)
morph.sendCCMessages = true

// In drag gesture
.onChanged { value in
    let position = value.location.x / geometry.size.width
    morph.setMorphPosition(position)
}
```

### Pattern 5: Ping-Pong Morph

```swift
func pingPong() {
    morph.startMorph(to: 1.0)
    
    DispatchQueue.main.asyncAfter(deadline: .now() + morph.morphDuration + 0.5) {
        self.morph.startMorph(to: 0.0)
    }
}
```

---

## Troubleshooting

### "Why isn't parameter X morphing?"

**Check**:
1. Is it a discrete parameter? (Excluded by default)
2. Is its group enabled? (Check `filterConfig.enabledGroups`)
3. Is it specifically disabled? (Check `filterConfig.disabledParameters`)
4. Are source and dest values the same? (Won't send CC if no change)

### "Morph is sending too many MIDI messages"

**Solutions**:
1. Use `ProgramMorphOptimized` or `ProgramMorphFiltered`
2. Reduce `updateRate` (try 20 Hz instead of 30 Hz)
3. Enable only needed parameter groups
4. Check that source and dest programs are actually different

### "Discrete parameters are changing unexpectedly"

**Check**:
1. Are you using `ProgramMorphFiltered`?
2. Have you enabled `includeLFOShape` or similar?
3. What's your `modulationSourceStrategy`?

### "UI not updating during morph"

**Check**:
1. Is `@Observable` macro present on morph class?
2. Is morph marked as `@State` or `@Bindable` in view?
3. Is `isAutoMorphing` being checked in UI?

---

## Files Reference

### Core Implementations
- `ProgramMorph.swift` - Basic implementation
- `ProgramMorphOptimized.swift` - Optimized implementation
- `ProgramMorphFiltered.swift` - Filtered implementation (recommended)

### Configuration & Control
- `MorphParameterControl.swift` - Groups, strategies, filtering logic
- `MorphFilterControlView.swift` - Comprehensive UI for filtering

### UI Components
- `MorphControlView.swift` - Basic morph UI
- `AdvancedMorphView.swift` - Advanced morph UI with visualization

### Documentation
- `README.md` - Overview and quick start
- `APPROACHES_COMPARISON.md` - Eight different approaches analyzed
- `OPTIMIZATION_ANALYSIS.md` - Performance optimization details
- `DISCRETE_PARAMETERS_GUIDE.md` - Discrete parameter handling (this file)

### Examples
- `MorphUsageExamples.swift` - Complete usage examples and patterns

---

## Final Recommendation

**Use `ProgramMorphFiltered` for production applications.**

It provides:
- ✅ Full optimization (60-90% fewer messages)
- ✅ User control over what morphs
- ✅ Proper discrete parameter handling
- ✅ Parameter grouping presets
- ✅ Professional feature set
- ✅ Comprehensive UI components
- ✅ Detailed statistics

The additional complexity is minimal, and the benefits are substantial for real-world use.

```swift
// Production-ready morph with sensible defaults
let morph = ProgramMorphFiltered(
    source: sourceProgram,
    destination: destinationProgram,
    config: .allParameters
)

// Add to your UI
CompleteMorphView(morph: morph)
```

Done! 🎉
