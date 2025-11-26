# Parameter Filtering and Discrete Value Handling

## Overview

This document addresses critical questions about morphing synthesizer parameters:

1. **How are discrete (enum-based) parameters handled?**
2. **Can parameters be excluded from morphing?**
3. **How can parameters be grouped for selective morphing?**
4. **What makes sense to morph vs. what doesn't?**

## The Problem with Discrete Parameters

### What Are Discrete Parameters?

Discrete parameters have a fixed set of possible values (enums) rather than continuous numeric ranges:

```swift
// Continuous (GOOD for morphing)
cutoff: 0-127 (any value)
resonance: 0-127 (any value)

// Discrete (PROBLEMATIC for morphing)
triggerSource: .audio, .midi, .all (only 3 values)
triggerMode: .single, .multi (only 2 values)
lfoShape: .sine, .triangle, .square, .saw, .random (only 5 values)
modulationSource: .off, .lfo, .envelope, etc. (limited set)
```

### Why They're Problematic

**Continuous parameters** interpolate naturally:
```
Cutoff: 40 → 50 → 60 → 70 → 80 → 90 → 100 (smooth)
```

**Discrete parameters** have no meaningful middle ground:
```
Trigger Source: .audio → ??? → ??? → .midi
LFO Shape: .sine → ??? → .square

What does "50% between sine and square" mean?
What does "75% between audio and MIDI trigger" mean?
```

## Solution: Five Strategies for Discrete Parameters

### Strategy 1: Ignore (DEFAULT - RECOMMENDED)

**Approach**: Don't change discrete parameters during morphing.

```swift
strategy: .ignore
```

**Result**:
- Discrete params stay at source value throughout morph
- Simplest and most predictable
- Avoids jarring mid-morph changes

**When to use**: Default for most situations

---

### Strategy 2: Snap at 50%

**Approach**: Switch from source to destination value at midpoint.

```swift
strategy: .snapAtHalf

// Behavior
Position 0.0 - 0.49: Use source value
Position 0.50 - 1.0: Use destination value
```

**Example**:
```
LFO Shape morph (sine → square):
0% - 49%: Sine wave
50% - 100%: Square wave
```

**When to use**: When you want a distinct change in character mid-morph

---

### Strategy 3: Snap at Custom Threshold

**Approach**: Switch at a user-defined position.

```swift
strategy: .snapAtThreshold
threshold: 0.75

// Behavior
Position 0.0 - 0.74: Use source value
Position 0.75 - 1.0: Use destination value
```

**When to use**: 
- Want the discrete change to happen later (threshold > 0.5)
- Want the discrete change to happen earlier (threshold < 0.5)
- Coordinating with other morph events

---

### Strategy 4: Use Source

**Approach**: Always keep source value, never change.

```swift
strategy: .useSource
```

**When to use**: 
- Want to morph everything except certain discrete params
- Destination has experimental discrete settings you don't want

---

### Strategy 5: Use Destination

**Approach**: Immediately jump to destination value at morph start.

```swift
strategy: .useDestination
```

**When to use**:
- Want discrete changes to happen immediately
- Using morph primarily for continuous parameters

---

## Current Implementation Analysis

### What the Original Code Does

Looking at the implementation:

```swift
// From ProgramMorph.swift
extension MiniWorksProgram {
    var allParameters: [ProgramParameter] {
        [
            // Continuous parameters (✅ INCLUDED)
            vcfEnvelopeAttack, vcfEnvelopeDecay, vcfEnvelopeSustain, vcfEnvelopeRelease,
            vcaEnvelopeAttack, vcaEnvelopeDecay, vcaEnvelopeSustain, vcaEnvelopeRelease,
            vcfEnvelopeCutoffAmount, vcaEnvelopeVolumeAmount,
            lfoSpeed, lfoSpeedModulationAmount,
            cutoffModulationAmount, resonanceModulationAmount,
            volumeModulationAmount, panningModulationAmount,
            cutoff, resonance, volume, panning,
            gateTime
            
            // Discrete parameters (❌ EXCLUDED)
            // Note: Excluding mod sources, trigger source/mode as they don't morph well
        ]
    }
}

// Filtering logic
guard sourceParam.type == destParam.type,
      !sourceParam.isModSource,  // ✅ Excludes modulation sources
      sourceParam.containedParameter == nil else {  // ✅ Excludes contained enums
    continue
}
```

### What Gets Excluded

**✅ Already Excluded (Good!)**:
- `cutoffModulationSource` (enum: .off, .lfo, .envelope, etc.)
- `resonanceModulationSource` (enum)
- `volumeModulationSource` (enum)
- `panningModulationSource` (enum)
- `lfoSpeedModulationSource` (enum)
- `lfoShape` (enum: .sine, .triangle, .square, etc.)
- `triggerSource` (enum: .audio, .midi, .all)
- `triggerMode` (enum: .single, .multi)

**✅ Included (Correct)**:
- All ADSR envelope values (continuous 0-127)
- All modulation amounts (continuous 0-127)
- Cutoff, resonance, volume, panning (continuous 0-127)
- LFO speed (continuous 0-127)
- Gate time (continuous 0-127)

### Answer to Your Question

**"How does the code deal with parameters with discrete values?"**

✅ **It excludes them entirely** - which is the correct default behavior!

The code checks:
1. `!sourceParam.isModSource` - excludes all modulation source selectors
2. `sourceParam.containedParameter == nil` - excludes parameters with enum options

This means discrete parameters are **ignored by default** (Strategy 1), which is the recommended approach.

---

## Parameter Grouping System

### Why Grouping Matters

Sometimes you want to morph only related parameters:

**Scenarios**:
- "Morph just the filter cutoff and resonance"
- "Morph just the VCF envelope"
- "Morph everything except LFO parameters"
- "Morph VCF but not VCA"

### Available Groups

```swift
enum ParameterGroup {
    case vcfEnvelope     // Filter envelope ADSR + cutoff amount
    case vcaEnvelope     // Amplitude envelope ADSR + volume amount
    case vcfModulation   // Cutoff & resonance modulation amounts
    case vcaModulation   // Volume & panning modulation amounts
    case lfo             // LFO speed & speed modulation
    case filters         // Cutoff & resonance
    case output          // Volume & panning
    case timing          // Gate time
}
```

### Usage Examples

```swift
// Only morph VCF envelope
let config = MorphFilterConfig()
config.enabledGroups = [.vcfEnvelope]

// Morph filters and their modulation
config.enabledGroups = [.filters, .vcfModulation]

// Morph everything except LFO
config.enabledGroups = Set(ParameterGroup.allCases)
config.enabledGroups.remove(.lfo)

// Use preset
let config = MorphFilterConfig.envelopesOnly
let config = MorphFilterConfig.filtersOnly
let config = MorphFilterConfig.vcfOnly
```

### Individual Parameter Control

Override group settings for specific parameters:

```swift
// Disable specific parameter even if its group is enabled
config.disabledParameters.insert(.cutoff)

// Enable specific parameter even if its group is disabled
config.forceEnabledParameters.insert(.resonance)
```

---

## What Makes Sense to Morph?

### ✅ Always Makes Sense (Continuous Values)

**Envelopes**:
- Attack, Decay, Sustain, Release times ✅
- Envelope amounts (cutoff amount, volume amount) ✅

**Filter Parameters**:
- Cutoff frequency ✅
- Resonance ✅

**Modulation Amounts**:
- How much LFO affects cutoff ✅
- How much envelope affects resonance ✅
- All modulation depth parameters ✅

**Output**:
- Volume ✅
- Panning ✅

**LFO**:
- LFO speed/rate ✅
- LFO speed modulation amount ✅

**Timing**:
- Gate time ✅

### ⚠️ Questionable (Discrete Values)

**Modulation Sources** (.off, .lfo, .envelope, etc.):
- ❓ Could snap at 50% if you want distinct sections
- ❌ Generally not recommended (what does "halfway between LFO and envelope" mean?)

**LFO Shape** (.sine, .triangle, .square, etc.):
- ❓ Could snap to create timbral shift mid-morph
- ❌ Usually jarring (sine → square is a big jump)

### ❌ Never Makes Sense

**Trigger Source** (.audio, .midi, .all):
- ❌ No sensible interpolation
- ❌ Would cause confusion about what's triggering the filter

**Trigger Mode** (.single, .multi):
- ❌ Binary choice with no middle ground
- ❌ Would cause unpredictable triggering behavior

---

## Practical Recommendations

### For Most Use Cases

```swift
// Use defaults - excludes discrete parameters
let morph = ProgramMorphFiltered(
    source: program1,
    destination: program2,
    config: .allParameters  // All continuous params
)
```

### For Envelope-Only Morphs

```swift
let config = MorphFilterConfig.envelopesOnly
let morph = ProgramMorphFiltered(
    source: program1,
    destination: program2,
    config: config
)
// Morphs: VCF & VCA envelopes only
```

### For Filter Sweeps

```swift
let config = MorphFilterConfig.filtersOnly
let morph = ProgramMorphFiltered(
    source: program1,
    destination: program2,
    config: config
)
// Morphs: Cutoff, resonance, and their modulation amounts
```

### Including Discrete Parameters (Advanced)

If you really want to include discrete parameters:

```swift
let config = MorphFilterConfig.allParameters
config.includeLFOShape = true
config.modulationSourceStrategy = .snapAtHalf

let morph = ProgramMorphFiltered(
    source: program1,
    destination: program2,
    config: config
)

// Result: LFO shape will snap from source to dest at 50% position
```

---

## Real-World Scenarios

### Scenario 1: Evolving Pad Sound

```swift
// Source: Slow attack, closed filter
// Dest: Fast attack, open filter

let config = MorphFilterConfig()
config.enabledGroups = [.vcfEnvelope, .filters]

// Result: Gradual opening of filter with attack time change
```

### Scenario 2: Bassline Character Change

```swift
// Source: Short, punchy
// Dest: Long, sustained

let config = MorphFilterConfig()
config.enabledGroups = [.vcaEnvelope, .timing]

// Result: Gate time and amplitude envelope morph
```

### Scenario 3: Modulation Intensity

```swift
// Source: No modulation
// Dest: Heavy LFO modulation

let config = MorphFilterConfig()
config.enabledGroups = [.vcfModulation, .lfo]

// Result: LFO amount and speed increase
// Note: LFO shape stays at source (discrete)
```

### Scenario 4: Complete Patch Transformation

```swift
// Source: Ambient pad
// Dest: Aggressive lead

let config = MorphFilterConfig.allParameters

// Morphs everything except discrete parameters
// For smooth, comprehensive transformation
```

---

## UI Integration

The provided `MorphFilterControlView` gives users:

1. **Quick Presets**: One-click common configurations
2. **Group Toggles**: Enable/disable parameter groups visually
3. **Discrete Strategy**: Choose how to handle discrete params
4. **Advanced Options**: Individual parameter overrides
5. **Live Statistics**: See what's being morphed in real-time

```swift
struct MyMorphView: View {
    @State var morph: ProgramMorphFiltered
    
    var body: some View {
        VStack {
            // Morph control
            MorphControlSection(morph: morph)
            
            // Filter configuration UI
            MorphFilterControlView(morph: morph)
        }
    }
}
```

---

## Summary

### ✅ What the Code Does Right

1. **Excludes discrete parameters by default** (modulation sources, trigger settings, LFO shape)
2. **Only morphs continuous parameters** (0-127 values)
3. **Provides grouping** for selective morphing
4. **Offers strategies** for discrete handling when needed

### 🎯 Answers to Your Questions

**Q: How does it deal with discrete parameters?**
A: Excludes them by default (ignore strategy). Can optionally include with snap strategies.

**Q: Can parameters be ignored?**
A: Yes - through group disabling, individual parameter blacklist, or force-enable whitelist.

**Q: How to morph groups?**
A: Eight predefined groups (VCF envelope, filters, etc.) with presets and custom combinations.

**Q: Does it make sense to morph trigger source/mode?**
A: No - excluded by default. These don't interpolate meaningfully.

**Q: What about modulation sources?**
A: Excluded by default, but can enable with snap strategies if desired.

**Q: How to morph LFO shape?**
A: Excluded by default (discrete), but can enable with `includeLFOShape = true` + snap strategy.

### 💡 Best Practices

1. **Use defaults** for most morphs (discrete params excluded)
2. **Use groups** for focused morphing (envelopes, filters, etc.)
3. **Avoid morphing discrete parameters** unless you specifically want mid-morph snaps
4. **Use snap-at-50%** if you must include discrete parameters
5. **Test your morphs** - what sounds good varies by context

The system provides full control while defaulting to sensible, musical behavior.
